#!/usr/bin/env python3
"""Vérifie les extraits Flutter et Kotlin hôte d'un module de cours.

Les extraits Dart qui importent un paquet sont analysés dans un vrai projet
Flutter. Le code Kotlin qui étend `FlutterActivity` y est compilé. Rien n'est
exécuté : l'outil prouve que le code se type, pas qu'il se comporte comme annoncé.

    python3 tool/check_flutter_snippets.py flutter
"""
import json
import pathlib
import re
import shutil
import subprocess
import sys

PROJECT = pathlib.Path("build/flutter_snippets")
COURSES = pathlib.Path("assets/courses")
PACKAGES = [
    "flutter_riverpod",
    "go_router",
    "path_provider",
    "permission_handler",
    "flutter_local_notifications",
    "url_launcher",
    "path",
]
GRADLE_VERSION = "9.6.0"
AGP_VERSION = "9.5.0"
DESUGAR = "com.android.tools:desugar_jdk_libs:2.1.5"
ACTIVITY_PATH = "android/app/src/main/kotlin/com/exemple/preuve/MainActivity.kt"
KOTLIN_IMPORTS = """package com.exemple.preuve

import android.content.Context
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

"""


def run(*command, cwd=PROJECT):
    return subprocess.run(command, cwd=cwd).returncode


def substitute(path, old, new):
    text = path.read_text(encoding="utf8")
    if old not in text:
        sys.exit(f"Motif absent de {path} : {old}")
    path.write_text(text.replace(old, new), encoding="utf8")


def upgrade_android_project():
    """Aligne le projet sur ce que réclament les plugins récents.

    `permission_handler` exige compileSdk 37, donc un AGP récent, et
    `flutter_local_notifications` exige la désucration de la bibliothèque Java.
    """
    android = PROJECT / "android"
    version = re.compile(r'(id\("com\.android\.application"\) version )"[\d.]+"')
    settings = android / "settings.gradle.kts"
    settings.write_text(
        version.sub(rf'\1"{AGP_VERSION}"', settings.read_text(encoding="utf8")),
        encoding="utf8",
    )
    wrapper = android / "gradle/wrapper/gradle-wrapper.properties"
    wrapper.write_text(
        re.sub(
            r"gradle-[\d.]+-(all|bin)\.zip",
            f"gradle-{GRADLE_VERSION}-bin.zip",
            wrapper.read_text(encoding="utf8"),
        ),
        encoding="utf8",
    )
    build = android / "app/build.gradle.kts"
    substitute(build, "compileSdk = flutter.compileSdkVersion", "compileSdk = 37")
    substitute(
        build,
        "    compileOptions {\n",
        "    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n",
    )
    with build.open("a", encoding="utf8") as file:
        file.write(f'\ndependencies {{\n    coreLibraryDesugaring("{DESUGAR}")\n}}\n')


def collect(modules):
    dart, activity = [], None
    for module in modules:
        course = json.loads((COURSES / f"{module}.json").read_text(encoding="utf8"))
        for lesson in course["lessons"]:
            sources = [
                (block["language"], block["code"])
                for block in lesson["blocks"]
                if block["type"] == "code"
            ]
            sources += [
                (exercise["language"], exercise["solution"])
                for exercise in lesson["exercises"]
                if "language" in exercise
            ]
            for language, code in sources:
                if language == "dart" and "package:" in code:
                    dart.append(code)
                elif language == "kotlin" and "FlutterActivity" in code:
                    activity = code
    return dart, activity


def main():
    modules = sys.argv[1:]
    if not modules:
        sys.exit("Indiquez au moins un module, par exemple : flutter")
    dart, activity = collect(modules)
    print(f"{len(dart)} extraits Dart, {'1' if activity else '0'} activité Kotlin.")

    if PROJECT.exists():
        shutil.rmtree(PROJECT)
    PROJECT.parent.mkdir(exist_ok=True)
    code = run(
        "flutter", "create", "--platforms=android", "--org=com.exemple",
        "--project-name=preuve", "--no-pub", str(PROJECT), cwd=".",
    )
    if code:
        return code
    if run("flutter", "pub", "add", *PACKAGES):
        return 1

    for index, source in enumerate(dart):
        (PROJECT / f"lib/extrait_{index}.dart").write_text(source + "\n", encoding="utf8")

    code = run("flutter", "analyze", "--no-pub", "--no-fatal-infos", "--no-fatal-warnings")
    if code:
        print("Analyse Dart en échec.")
        return code

    if activity:
        upgrade_android_project()
        path = PROJECT / ACTIVITY_PATH
        path.write_text(KOTLIN_IMPORTS + activity + "\n", encoding="utf8")
        code = run("flutter", "build", "apk", "--debug", "--no-pub")
        if code:
            print("Compilation Kotlin en échec.")
            return code

    print("Vérification réussie.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
