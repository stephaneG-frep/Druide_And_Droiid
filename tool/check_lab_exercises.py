#!/usr/bin/env python3
"""Vérifie les exercices du Lab avec les vrais compilateurs.

Chaque corrigé doit produire exactement `expectedOutput`. Chaque code de départ
doit compiler et s'exécuter, sans réussir l'exercice : sinon, il n'y aurait
rien à faire. Pour le XML, le corrigé doit être bien formé et contenir tous les
éléments de `required`, ce que le code de départ ne doit pas faire.

    python3 tool/check_lab_exercises.py
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import xml.dom.minidom

KOTLINC = pathlib.Path(
    os.environ.get("KOTLIN_HOME", "/opt/android-studio/plugins/Kotlin/kotlinc")
) / "bin/kotlinc"
JAVA_HOME = os.environ.get("JAVA_HOME", "/opt/android-studio/jbr")
ENVIRONMENT = {**os.environ, "JAVA_HOME": JAVA_HOME}
JAVA = f"{JAVA_HOME}/bin/java"


def run(*command, cwd):
    return subprocess.run(
        command, cwd=cwd, env=ENVIRONMENT, capture_output=True, text=True, timeout=180
    )


def execute(language, code):
    with tempfile.TemporaryDirectory() as folder:
        if language == "kotlin":
            (pathlib.Path(folder) / "Main.kt").write_text(code, encoding="utf8")
            build = run(str(KOTLINC), "Main.kt", "-include-runtime", "-d", "main.jar", cwd=folder)
            if build.returncode:
                return None, build.stderr
            result = run(JAVA, "-jar", "main.jar", cwd=folder)
        elif language == "java":
            (pathlib.Path(folder) / "Main.java").write_text(code, encoding="utf8")
            result = run(JAVA, "Main.java", cwd=folder)
        else:
            (pathlib.Path(folder) / "main.dart").write_text(code, encoding="utf8")
            result = run("dart", "main.dart", cwd=folder)
        if result.returncode:
            return None, result.stderr
        return result.stdout.strip(), ""


def main():
    exercises = json.loads(
        pathlib.Path("assets/lab/exercises.json").read_text(encoding="utf8")
    )["exercises"]
    errors = 0
    for exercise in exercises:
        name = exercise["id"]
        if exercise["language"] == "xml":
            xml.dom.minidom.parseString(exercise["solution"])
            xml.dom.minidom.parseString(exercise["starter"])
            missing = [r for r in exercise["required"] if r not in exercise["solution"]]
            solved = all(r in exercise["starter"] for r in exercise["required"])
            if missing or solved:
                print(f"ERREUR {name} : {missing or 'déjà résolu au départ'}")
                errors += 1
            continue
        expected = exercise["expectedOutput"]
        output, error = execute(exercise["language"], exercise["solution"])
        if output != expected:
            print(f"ERREUR {name} (corrigé) : {output!r} {error}")
            errors += 1
        output, error = execute(exercise["language"], exercise["starter"])
        if output is None or output == expected:
            print(f"ERREUR {name} (départ) : {output!r} {error}")
            errors += 1
    print(f"{len(exercises)} exercices vérifiés, {errors} en erreur.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
