#!/usr/bin/env python3
"""Assemble le paquet Debian de l'application à partir du build Linux release.

Usage : python3 tool/build_deb.py [--skip-build]

Le paquet installe l'application dans /opt/druide-and-droiid, une commande
druide-and-droiid, un lanceur et ses icônes. Les dépendances sont déduites des
bibliothèques liées directement (readelf, ldd, puis dpkg -S). L'architecture est celle de
la machine de compilation. Le paquet est écrit dans dist/.
"""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = "druide-and-droiid"
APP_ID = "com.druideanddroiid.druide_and_droiid"
BINARY = "druide_and_droiid"
INSTALL_DIR = Path("opt") / PACKAGE


def run(*args, **kwargs):
    return subprocess.run(args, check=True, text=True, capture_output=True,
                          **kwargs).stdout


def version():
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf8")
    return re.search(r"^version: ([^+\s]+)", text, re.M).group(1)


def maintainer():
    try:
        name = run("git", "config", "user.name", cwd=ROOT).strip()
        email = run("git", "config", "user.email", cwd=ROOT).strip()
        return f"{name} <{email}>"
    except subprocess.CalledProcessError:
        return "Druide And-Droiid <noreply@localhost>"


def system_dependencies(bundle):
    """Paquets qui fournissent les bibliothèques liées hors du bundle."""
    libraries = set()
    bundled = {p.name for p in (bundle / "lib").glob("*.so")}
    files = [bundle / BINARY, *sorted((bundle / "lib").glob("*.so"))]
    for elf in files:
        # Seules les bibliothèques liées directement (NEEDED) comptent : leurs
        # paquets tirent eux-mêmes le reste.
        needed = set(re.findall(r"\(NEEDED\)\s+Shared library: \[(\S+)\]",
                                run("readelf", "-d", str(elf))))
        for line in run("ldd", str(elf)).splitlines():
            match = re.search(r"^\s*(\S+) => (/\S+)", line)
            if match and match.group(1) in needed - bundled:
                libraries.add(os.path.realpath(match.group(2)))
    packages = set()
    for library in sorted(libraries):
        try:
            owner = run("dpkg", "-S", library)
        except subprocess.CalledProcessError:
            # Chemin /lib fusionné avec /usr/lib : dpkg connaît l'autre forme.
            alt = library.replace("/usr/lib/", "/lib/", 1)
            owner = run("dpkg", "-S", alt)
        packages.add(owner.split(":")[0].strip())
    return sorted(packages)


def main():
    arch = run("dpkg", "--print-architecture").strip()
    flutter_arch = {"amd64": "x64", "arm64": "arm64"}[arch]
    if "--skip-build" not in sys.argv:
        subprocess.run(["flutter", "build", "linux", "--release", "--no-pub"],
                       check=True, cwd=ROOT)
    bundle = ROOT / "build" / "linux" / flutter_arch / "release" / "bundle"
    if not (bundle / BINARY).exists():
        sys.exit(f"Build introuvable : {bundle}")

    stage = ROOT / "build" / "deb" / PACKAGE
    if stage.exists():
        shutil.rmtree(stage)
    shutil.copytree(bundle, stage / INSTALL_DIR, symlinks=True)

    bin_dir = stage / "usr" / "bin"
    bin_dir.mkdir(parents=True)
    (bin_dir / PACKAGE).symlink_to(Path("/") / INSTALL_DIR / BINARY)

    packaging = ROOT / "linux" / "packaging"
    apps = stage / "usr" / "share" / "applications"
    apps.mkdir(parents=True)
    shutil.copy(packaging / f"{PACKAGE}.desktop", apps)
    for size in (64, 128, 256, 512):
        icons = (stage / "usr" / "share" / "icons" / "hicolor"
                 / f"{size}x{size}" / "apps")
        icons.mkdir(parents=True)
        shutil.copy(packaging / f"icon_{size}.png", icons / f"{APP_ID}.png")

    doc = stage / "usr" / "share" / "doc" / PACKAGE
    doc.mkdir(parents=True)
    shutil.copy(packaging / "copyright", doc / "copyright")
    for name in ("README.md", "USER_GUIDE.md", "CHANGELOG.md"):
        shutil.copy(ROOT / name, doc / name)

    stage.chmod(0o755)
    for path in stage.rglob("*"):
        if path.is_symlink():
            continue
        if path.is_dir() or os.access(path, os.X_OK) and path.suffix != ".png":
            path.chmod(0o755)
        else:
            path.chmod(0o644)

    size_kb = sum(p.stat().st_size for p in stage.rglob("*")
                  if p.is_file() and not p.is_symlink()) // 1024
    depends = ", ".join(system_dependencies(bundle))
    control = stage / "DEBIAN" / "control"
    control.parent.mkdir()
    control.write_text(
        f"Package: {PACKAGE}\n"
        f"Version: {version()}\n"
        f"Architecture: {arch}\n"
        f"Maintainer: {maintainer()}\n"
        f"Installed-Size: {size_kb}\n"
        f"Depends: {depends}\n"
        "Suggests: default-jdk, adb\n"
        "Section: education\n"
        "Priority: optional\n"
        "Description: apprentissage du développement Android\n"
        " Druide And-Droiīd enseigne Kotlin, Java, Flutter et Android : cours,\n"
        " quiz, exercices, Lab de code, Chaudron des bugs, projets et professeur\n"
        " IA (Ollama local ou fournisseur en ligne, avec la clé de l'utilisateur).\n"
        " Les données restent sur la machine, dans le dossier de l'utilisateur.\n",
        encoding="utf8",
    )

    out = ROOT / "dist"
    out.mkdir(exist_ok=True)
    target = out / f"Druide_And-Droiid_v{version()}_{arch}.deb"
    subprocess.run(["dpkg-deb", "--root-owner-group", "-Zxz", "--build",
                    str(stage), str(target)], check=True)
    print(f"Paquet : {target}")
    print(f"Dépendances : {depends}")


if __name__ == "__main__":
    main()
