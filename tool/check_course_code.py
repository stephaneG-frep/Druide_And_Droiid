#!/usr/bin/env python3
"""Compile et exécute les exemples Kotlin des cours, puis compare leur sortie.

Chaque bloc `code` Kotlin et chaque corrigé Kotlin contenant `fun main` sont
exécutés. Un bloc avec `output` doit produire exactement ce texte. Les autres
blocs Kotlin (API Android, extraits) sont listés comme non vérifiés.

    python3 tool/check_course_code.py

Variables : KOTLIN_HOME (défaut : le kotlinc d'Android Studio), JAVA_HOME.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

KOTLIN_HOME = pathlib.Path(
    os.environ.get("KOTLIN_HOME", "/opt/android-studio/plugins/Kotlin/kotlinc")
)
JAVA_HOME = os.environ.get("JAVA_HOME", "/opt/android-studio/jbr")
LIB = KOTLIN_HOME / "lib"
CLASSPATH = [LIB / "kotlin-stdlib.jar", LIB / "kotlinx-coroutines-core-jvm.jar"]
COURSES = pathlib.Path("assets/courses")


def snippets():
    for path in sorted(COURSES.glob("*.json")):
        if path.name == "index.json":
            continue
        course = json.loads(path.read_text(encoding="utf8"))
        for lesson in course["lessons"]:
            count = 0
            for block in lesson["blocks"]:
                if block["type"] == "code" and block["language"] == "kotlin":
                    count += 1
                    yield f"{lesson['id']}#{count}", block["code"], block.get("output")
            for exercise in lesson["exercises"]:
                if exercise.get("language") == "kotlin":
                    yield exercise["id"], exercise["solution"], None


def main():
    runnable, skipped = [], []
    for name, code, output in snippets():
        (runnable if "fun main" in code else skipped).append((name, code, output))

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        for index, (name, code, _) in enumerate(runnable):
            package = f"s{index}"
            folder = tmp / "src" / package
            folder.mkdir(parents=True)
            (folder / "Main.kt").write_text(f"package {package}\n{code}\n", encoding="utf8")

        env = {**os.environ, "JAVA_HOME": JAVA_HOME}
        jar = tmp / "all.jar"
        build = subprocess.run(
            [
                str(KOTLIN_HOME / "bin" / "kotlinc"),
                str(tmp / "src"),
                "-cp",
                os.pathsep.join(map(str, CLASSPATH)),
                "-d",
                str(jar),
                "-nowarn",
            ],
            env=env,
            capture_output=True,
            text=True,
        )
        if build.returncode != 0:
            print(build.stderr)
            for index, (name, _, _) in enumerate(runnable):
                print(f"s{index} = {name}")
            return 1

        failures = 0
        for index, (name, _, expected) in enumerate(runnable):
            run = subprocess.run(
                [
                    f"{JAVA_HOME}/bin/java",
                    "-cp",
                    os.pathsep.join([str(jar), *map(str, CLASSPATH)]),
                    f"s{index}.MainKt",
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )
            actual = run.stdout.rstrip("\n")
            if run.returncode != 0:
                failures += 1
                print(f"ÉCHEC {name} : code {run.returncode}\n{run.stderr[:500]}")
            elif expected is not None and actual != expected:
                failures += 1
                print(f"ÉCART {name}\n--- attendu\n{expected}\n--- obtenu\n{actual}")
            elif expected is None and name.count("#"):
                failures += 1
                print(f"SORTIE MANQUANTE {name}\n{actual}")

    print(f"{len(runnable)} exemples exécutés, {failures} en erreur.")
    print(f"{len(skipped)} extraits non exécutés (API Android ou fragments) :")
    for name, _, _ in skipped:
        print(f"  {name}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
