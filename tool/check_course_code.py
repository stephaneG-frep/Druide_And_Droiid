#!/usr/bin/env python3
"""Compile et exécute les exemples Kotlin, Java et Dart des cours.

Sont exécutés les blocs `code` et les corrigés contenant `fun main` (Kotlin),
`public class Main` (Java) ou `main` sans paquet Flutter (Dart). Le C++ est
vérifié avec le compilateur du NDK, sans être exécuté. Un bloc avec `output` doit produire exactement ce
texte. Les autres extraits (API Android, Gradle, fragments) sont listés comme
non vérifiés.

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
GRADLE_CACHE = pathlib.Path.home() / ".gradle/caches/modules-2/files-2.1"
SERIALIZATION_PLUGIN = LIB / "kotlinx-serialization-compiler-plugin.jar"


def gradle_jar(group, name, version):
    """Trouve une bibliothèque déjà téléchargée par Gradle."""
    jars = sorted((GRADLE_CACHE / group / name / version).glob(f"*/{name}-{version}.jar"))
    if not jars:
        sys.exit(f"Bibliothèque absente du cache Gradle : {name} {version}")
    return jars[0]


CLASSPATH = [
    LIB / "kotlin-stdlib.jar",
    LIB / "kotlinx-coroutines-core-jvm.jar",
    gradle_jar("org.jetbrains.kotlinx", "kotlinx-serialization-core-jvm", "1.8.1"),
    gradle_jar("org.jetbrains.kotlinx", "kotlinx-serialization-json-jvm", "1.8.1"),
]
COURSES = pathlib.Path(os.environ.get("COURSES_DIR", "assets/courses"))
LANGUAGES = ("kotlin", "java", "dart", "cpp")


def snippets():
    for path in sorted(COURSES.glob("*.json")):
        if path.name == "index.json":
            continue
        course = json.loads(path.read_text(encoding="utf8"))
        for lesson in course["lessons"]:
            count = 0
            for block in lesson["blocks"]:
                if block["type"] == "code" and block["language"] in LANGUAGES:
                    count += 1
                    yield (
                        f"{lesson['id']}#{count}",
                        block["language"],
                        block["code"],
                        block.get("output"),
                    )
            for exercise in lesson["exercises"]:
                if exercise.get("language") in LANGUAGES:
                    yield exercise["id"], exercise["language"], exercise["solution"], None


def is_runnable(language, code):
    if language == "kotlin":
        return "fun main" in code
    if language == "java":
        return "public class Main" in code
    if language == "dart":
        return " main(" in code and "package:" not in code
    return False


def check_cpp(snippets_cpp, tmp):
    """Vérifie le C++ avec le NDK. Renvoie le nombre d'erreurs."""
    ndks = sorted((pathlib.Path.home() / "Android/Sdk/ndk").glob("*"))
    if not ndks:
        sys.exit("NDK absent : impossible de vérifier le C++.")
    compiler = ndks[-1] / "toolchains/llvm/prebuilt/linux-x86_64/bin/clang++"
    errors = 0
    for index, (name, _, code, _) in enumerate(snippets_cpp):
        source = tmp / f"bloc{index}.cpp"
        source.write_text(code + "\n", encoding="utf8")
        build = subprocess.run(
            [
                str(compiler),
                "--target=aarch64-linux-android24",
                "-std=c++17",
                "-fsyntax-only",
                str(source),
            ],
            capture_output=True,
            text=True,
        )
        if build.returncode != 0:
            errors += 1
            print(f"ÉCHEC C++ {name}\n{build.stderr[:800]}")
    return errors


def run_dart(name, code, expected, tmp, index):
    source = tmp / f"dart{index}.dart"
    source.write_text(code + "\n", encoding="utf8")
    run = subprocess.run(
        ["dart", "run", str(source)],
        capture_output=True,
        text=True,
        encoding="utf8",
        timeout=60,
    )
    actual = run.stdout.rstrip("\n")
    if run.returncode != 0:
        print(f"ÉCHEC {name}\n{(run.stderr or run.stdout)[:500]}")
        return 1
    if expected is not None and actual != expected:
        print(f"ÉCART {name}\n--- attendu\n{expected}\n--- obtenu\n{actual}")
        return 1
    if expected is None and "#" in name:
        print(f"SORTIE MANQUANTE {name}\n{actual}")
        return 1
    return 0


def compile_all(runnable, tmp):
    """Renvoie le classpath des programmes, ou None si la compilation échoue."""
    env = {**os.environ, "JAVA_HOME": JAVA_HOME}
    output = tmp / "classes"
    output.mkdir()
    kotlin, java = [], []

    for index, (name, language, code, _) in enumerate(runnable):
        if language == "dart":
            continue
        package = f"s{index}"
        folder = tmp / "src" / package
        folder.mkdir(parents=True)
        if language == "kotlin":
            file = folder / "Main.kt"
            kotlin.append(file)
            imports_first = f"package {package}\n{code}\n"
        else:
            file = folder / "Main.java"
            java.append(file)
            imports_first = f"package {package};\n{code}\n"
        file.write_text(imports_first, encoding="utf8")

    if kotlin:
        build = subprocess.run(
            [
                str(KOTLIN_HOME / "bin" / "kotlinc"),
                *map(str, kotlin),
                "-cp",
                os.pathsep.join(map(str, CLASSPATH)),
                "-d",
                str(output),
                "-nowarn",
                f"-Xplugin={SERIALIZATION_PLUGIN}",
            ],
            env=env,
            capture_output=True,
            text=True,
        )
        if build.returncode != 0:
            print(build.stderr)
            return None

    if java:
        build = subprocess.run(
            [
                f"{JAVA_HOME}/bin/javac",
                "-encoding",
                "UTF-8",
                "-nowarn",
                "-d",
                str(output),
                *map(str, java),
            ],
            capture_output=True,
            text=True,
        )
        if build.returncode != 0:
            print(build.stderr)
            return None

    return output


def main():
    runnable, skipped = [], []
    for snippet in snippets():
        _, language, code, _ = snippet
        (runnable if is_runnable(language, code) else skipped).append(snippet)

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        classes = compile_all(runnable, tmp)
        if classes is None:
            for index, (name, _, _, _) in enumerate(runnable):
                print(f"s{index} = {name}")
            return 1

        cpp = [snippet for snippet in skipped if snippet[1] == "cpp"]
        failures = check_cpp(cpp, tmp)
        skipped = [snippet for snippet in skipped if snippet[1] != "cpp"]
        for index, (name, language, code, expected) in enumerate(runnable):
            if language == "dart":
                failures += run_dart(name, code, expected, tmp, index)
                continue
            main_class = f"s{index}.MainKt" if language == "kotlin" else f"s{index}.Main"
            run = subprocess.run(
                [
                    f"{JAVA_HOME}/bin/java",
                    "-Dstdout.encoding=UTF-8",
                    "-Dstderr.encoding=UTF-8",
                    "-cp",
                    os.pathsep.join([str(classes), *map(str, CLASSPATH)]),
                    main_class,
                ],
                capture_output=True,
                text=True,
                encoding="utf8",
                timeout=30,
            )
            actual = run.stdout.rstrip("\n")
            if run.returncode != 0:
                failures += 1
                print(f"ÉCHEC {name} : code {run.returncode}\n{run.stderr[:500]}")
            elif expected is not None and actual != expected:
                failures += 1
                print(f"ÉCART {name}\n--- attendu\n{expected}\n--- obtenu\n{actual}")
            elif expected is None and "#" in name:
                failures += 1
                print(f"SORTIE MANQUANTE {name}\n{actual}")

    print(f"{len(runnable)} exemples exécutés, {len(cpp)} blocs C++ vérifiés, {failures} en erreur.")
    print(f"{len(skipped)} extraits non exécutés (API Android, Gradle ou fragments) :")
    for name, _, _, _ in skipped:
        print(f"  {name}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
