#!/usr/bin/env python3
"""Vérifie le code des projets pratiques avec les outils des cours.

Les projets sont convertis en un cours temporaire, puis passés aux contrôles
habituels : exécution des tests, compilation Android, analyse Flutter.

    python3 tool/check_projects.py
"""
import json
import os
import pathlib
import subprocess
import sys

SOURCE = pathlib.Path("assets/projects/projects.json")
FOLDER = pathlib.Path("build/project_courses")


def to_lesson(project):
    blocks = [
        {"type": "code", **step["code"]} for step in project["steps"] if "code" in step
    ]
    blocks.append({"type": "code", **project["test"]})
    return {
        "id": f"projet-{project['id']}",
        "blocks": blocks,
        "exercises": [],
    }


def main():
    projects = json.loads(SOURCE.read_text(encoding="utf8"))["projects"]
    FOLDER.mkdir(parents=True, exist_ok=True)
    (FOLDER / "projets.json").write_text(
        json.dumps({"lessons": [to_lesson(p) for p in projects]}, ensure_ascii=False),
        encoding="utf8",
    )
    environment = {**os.environ, "COURSES_DIR": str(FOLDER)}
    code = 0
    for tool in (
        ["tool/check_course_code.py"],
        ["tool/check_android_snippets.py", "projets"],
        ["tool/check_flutter_snippets.py", "projets"],
    ):
        print("==", tool[0])
        code |= subprocess.run([sys.executable, *tool], env=environment).returncode
    return code


if __name__ == "__main__":
    sys.exit(main())
