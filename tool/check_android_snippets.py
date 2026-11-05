#!/usr/bin/env python3
"""Compile les extraits Android des cours dans un vrai projet Gradle.

Les extraits qui utilisent Compose, Room ou Retrofit ne peuvent pas s'exécuter
sur un ordinateur : ce script les compile, avec KSP pour vérifier les requêtes
Room, et compile aussi les mises en page XML. Il n'exécute rien : il prouve que
le code existe et se type correctement, pas qu'il se comporte comme annoncé.

    python3 tool/check_android_snippets.py interfaces donnees-reseaux

Chaque leçon devient un paquet. Les lignes `import` étant omises dans les cours,
elles sont ajoutées ici.
"""
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys

PROJECT = pathlib.Path("build/android_snippets")
COURSES = pathlib.Path("assets/courses")
GRADLE_DSL = re.compile(r"^(plugins|android|dependencies)\s*\{", re.M)

VERSIONS = {
    "agp": "9.5.0",
    "gradle": "9.6.0",
    "kotlin": "2.4.10",
    "ksp": "2.3.13",
    "bom": "2026.09.00",
    "room": "3.0.3",
    "retrofit": "3.0.0",
    "okhttp": "5.5.1",
    "serialization": "1.9.0",
    "navigation": "2.10.2",
    "lifecycle": "2.11.0",
    "datastore": "1.3.0",
    "work": "2.12.0",
}

IMPORTS = """
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.material3.adaptive.currentWindowAdaptiveInfo
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import androidx.room3.ColumnInfo
import androidx.room3.Dao
import androidx.room3.Database
import androidx.room3.Delete
import androidx.room3.Entity
import androidx.room3.Insert
import androidx.room3.PrimaryKey
import androidx.room3.Room
import androidx.room3.RoomDatabase
import androidx.room3.Update
import androidx.room3.Upsert
import androidx.room3.migration.Migration
import androidx.sqlite.SQLiteConnection
import androidx.sqlite.driver.AndroidSQLiteDriver
import androidx.sqlite.execSQL
import androidx.window.core.layout.WindowSizeClass
import androidx.work.*
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.Authenticator
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Route
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import preuve.R
import preuve.databinding.ActivityExempleBinding
import preuve.stubs.*
"""

STUBS = """
package preuve.stubs

suspend fun synchroniser() {}
"""

FRAGMENT_LAYOUT = """<TextView xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/nom"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content" />
"""

BUILD = """
plugins {{
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.devtools.ksp")
}}

android {{
    namespace = "preuve"
    compileSdk = 37
    defaultConfig {{
        applicationId = "preuve.app"
        minSdk = 24
        targetSdk = 36
    }}
    buildFeatures {{
        compose = true
        viewBinding = true
    }}
}}

dependencies {{
    implementation(platform("androidx.compose:compose-bom:{bom}"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material3.adaptive:adaptive")
    implementation("androidx.compose.material:material-icons-core")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.appcompat:appcompat:1.8.0")
    implementation("androidx.fragment:fragment-ktx:1.8.9")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:{lifecycle}")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:{lifecycle}")
    implementation("androidx.navigation:navigation-compose:{navigation}")
    implementation("androidx.room3:room3-runtime:{room}")
    ksp("androidx.room3:room3-compiler:{room}")
    implementation("androidx.sqlite:sqlite-framework:2.7.0")
    implementation("androidx.datastore:datastore-preferences:{datastore}")
    implementation("androidx.work:work-runtime-ktx:{work}")
    implementation("com.squareup.retrofit2:retrofit:{retrofit}")
    implementation("com.squareup.retrofit2:converter-kotlinx-serialization:{retrofit}")
    implementation("com.squareup.okhttp3:okhttp:{okhttp}")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:{serialization}")
}}
"""


def imports_for(code):
    room = "@Entity" in code or "@Dao" in code
    query = "androidx.room3.Query" if room else "retrofit2.http.Query"
    return f"{IMPORTS}import {query}\n"


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf8")


def extra_database(package, kotlin):
    """Déclare les DAO orphelins dans une base, pour que KSP vérifie leur SQL."""
    joined = "\n".join(kotlin)
    if "@Database" in joined or "@Entity" not in joined:
        return None
    entities = re.findall(r"@Entity[^\n]*\n\s*data class (\w+)", joined)
    daos = re.findall(r"@Dao\s+interface (\w+)", joined)
    body = "\n".join(f"    abstract fun dao{i}(): {d}" for i, d in enumerate(daos))
    return (
        f"package {package}\n{IMPORTS}\n"
        f"@Database(entities = [{', '.join(e + '::class' for e in entities)}], version = 1)\n"
        f"abstract class BaseGeneree : RoomDatabase() {{\n{body}\n}}\n"
    )


def generate(modules):
    source = PROJECT / "app/src/main/java"
    res = PROJECT / "app/src/main/res"
    write(PROJECT / "app/src/main/AndroidManifest.xml", "<manifest />\n")
    write(source / "preuve/stubs/Stubs.kt", STUBS)
    write(res / "layout/fragment_profil.xml", FRAGMENT_LAYOUT)
    write(PROJECT / "app/build.gradle.kts", BUILD.format(**VERSIONS))
    write(
        PROJECT / "settings.gradle.kts",
        """
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
    repositories { google(); mavenCentral() }
}
rootProject.name = "Preuve"
include(":app")
""",
    )
    write(
        PROJECT / "build.gradle.kts",
        f"""
plugins {{
    id("com.android.application") version "{VERSIONS['agp']}" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "{VERSIONS['kotlin']}" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "{VERSIONS['kotlin']}" apply false
    id("com.google.devtools.ksp") version "{VERSIONS['ksp']}" apply false
}}
""",
    )
    sdk = pathlib.Path.home() / "Android/Sdk"
    write(PROJECT / "local.properties", f"sdk.dir={os.environ.get('ANDROID_HOME', sdk)}\n")
    write(PROJECT / "gradle.properties", "org.gradle.jvmargs=-Xmx3g\nandroid.useAndroidX=true\n")
    shutil.copytree("android/gradle/wrapper", PROJECT / "gradle/wrapper", dirs_exist_ok=True)
    shutil.copy("android/gradlew", PROJECT / "gradlew")
    wrapper = PROJECT / "gradle/wrapper/gradle-wrapper.properties"
    wrapper.write_text(
        re.sub(
            r"gradle-[\d.]+-(all|bin)\.zip",
            f"gradle-{VERSIONS['gradle']}-bin.zip",
            wrapper.read_text(encoding="utf8"),
        ),
        encoding="utf8",
    )

    kept = 0
    for module in modules:
        course = json.loads((COURSES / f"{module}.json").read_text(encoding="utf8"))
        for lesson in course["lessons"]:
            package = "p." + lesson["id"].replace("-", "_")
            folder = source / package.replace(".", "/")
            kotlin = []
            for block in lesson["blocks"]:
                if block["type"] != "code":
                    continue
                code = block["code"]
                if block["language"] == "kotlin":
                    if "fun main" in code or GRADLE_DSL.search(code):
                        continue
                    kotlin.append(code)
                elif block["language"] == "xml" and "<LinearLayout" in code:
                    write(res / "layout/activity_exemple.xml", code + "\n")
                    kept += 1
                elif block["language"] == "xml" and "<network-security-config" in code:
                    name = f"reseau_{lesson['blocks'].index(block)}.xml"
                    write(res / "xml" / name, code + "\n")
                    kept += 1

            for index, code in enumerate(kotlin):
                write(
                    folder / f"Bloc{index}.kt",
                    f"package {package}\n{imports_for(code)}\n{code}\n",
                )
                kept += 1

            database = extra_database(package, kotlin)
            if database:
                write(folder / "BaseGeneree.kt", database)

            for exercise in lesson["exercises"]:
                solution = exercise["solution"]
                if exercise.get("language") != "kotlin" or "fun main" in solution:
                    continue
                name = exercise["id"].replace("-", "_")
                joined = solution + "\n".join(kotlin)
                parent = f"import {package}.*\n" if kotlin else ""
                code = solution
                dao = re.search(r"@Dao\s+interface (\w+)", solution)
                if dao:
                    entities = re.findall(r"@Entity[^\n]*\n\s*data class (\w+)", joined)
                    code += (
                        f"\n\n@Database(entities = [{', '.join(e + '::class' for e in entities)}], "
                        f"version = 1)\nabstract class BaseExercice : RoomDatabase() {{\n"
                        f"    abstract fun dao(): {dao[1]}\n}}\n"
                    )
                write(
                    source / "e" / name / "Solution.kt",
                    f"package e.{name}\n{imports_for(joined)}{parent}\n{code}\n",
                )
                kept += 1
    return kept


def main():
    modules = sys.argv[1:]
    if not modules:
        sys.exit("Indiquez au moins un module, par exemple : interfaces")
    if PROJECT.exists():
        shutil.rmtree(PROJECT)
    count = generate(modules)
    print(f"{count} extraits à compiler.")

    env = {
        **os.environ,
        "JAVA_HOME": os.environ.get("JAVA_HOME", "/opt/android-studio/jbr"),
    }
    build = subprocess.run(
        ["bash", "gradlew", "--no-daemon", "-q", ":app:compileDebugKotlin", ":app:processDebugResources"],
        cwd=PROJECT,
        env=env,
    )
    print("Compilation réussie." if build.returncode == 0 else "Compilation en échec.")
    return build.returncode


if __name__ == "__main__":
    sys.exit(main())
