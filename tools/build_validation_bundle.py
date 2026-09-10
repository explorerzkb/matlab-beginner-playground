"""Build an allowlisted offline validation bundle from the current worktree."""
from pathlib import Path
import hashlib
import json
import zipfile


def build():
    root = Path(__file__).resolve().parents[1]
    output = root / "dist"
    output.mkdir(exist_ok=True)
    files = [root / "startGame.m", root / "startGame.bat",
             root / "runWindowsValidation.m", root / "validateWindows.bat",
             root / "runWindowsPlaytest.m",
             root / "summarizeWindowsValidation.m",
             root / "docs" / "windows-validation.txt"]
    for folder in ("config", "levels", "src", "tests"):
        files.extend(sorted((root / folder).glob("*.m")))
    files.extend(sorted(p for p in (root / "assets" / "game").rglob("*")
                        if p.is_file() and p.suffix.lower() in (".png", ".jpg")))
    manifest = {}
    contents = {}
    for file in files:
        if file.is_symlink():
            raise ValueError(f"Refusing symlink: {file}")
        relative = file.relative_to(root).as_posix()
        if relative == "docs/windows-validation.txt":
            relative = "README.txt"
        contents[relative] = file
        manifest[relative] = hashlib.sha256(file.read_bytes()).hexdigest()
    destination = output / "matlabHi-windows-validation.zip"
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as bundle:
        for relative, file in contents.items():
            bundle.write(file, "matlabHi/" + relative)
        bundle.writestr("matlabHi/SHA256.json", json.dumps(manifest, indent=2))
    with zipfile.ZipFile(destination) as bundle:
        assert bundle.testzip() is None
        for relative, expected in manifest.items():
            assert hashlib.sha256(bundle.read("matlabHi/" + relative)).hexdigest() == expected
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix(".zip.sha256").write_text(digest + "  " + destination.name + "\n")
    print(f"Verified {len(manifest)} files; {destination.stat().st_size} bytes")
    print(destination)
    print(digest)


if __name__ == "__main__":
    build()
