#!/usr/bin/env python3
"""
l10n_extract.py
----------------
Helper used while localising Man1fest0 (Spanish-Localization branch).

Scans the given Swift files/folders for SwiftUI string literals that SwiftUI
treats as LocalizedStringKey (Text("..."), Button("..."), Label("...", ...),
Toggle("...", ...), .help("..."), etc.) and prints the unique keys.

Interpolated literals (containing "\\(") are listed separately because their
String Catalog key depends on the interpolated value's type (%@, %lld, ...),
which cannot be determined reliably from a regex.

Usage:
    python3 tools/l10n_extract.py Man1fest0/Views/Policy > keys.txt
"""
import os
import re
import sys

# SwiftUI initialisers / modifiers whose first string-literal argument is a LocalizedStringKey.
CALLS = [
    r"Text", r"Button", r"Label", r"Toggle", r"TextField", r"SecureField", r"Picker",
    r"Section", r"Menu", r"Link", r"DisclosureGroup", r"GroupBox", r"Stepper",
    r"\.help", r"\.alert", r"\.navigationTitle", r"\.confirmationDialog", r"\.tabItem\s*\{\s*Label",
]
PATTERN = re.compile(r"(?:" + "|".join(CALLS) + r")\(\s*\"((?:[^\"\\]|\\.)*)\"")


def swift_files(paths):
    for path in paths:
        if os.path.isfile(path):
            yield path
        else:
            for root, _, files in os.walk(path):
                for name in files:
                    if name.endswith(".swift"):
                        yield os.path.join(root, name)


def main():
    plain, interpolated = set(), set()
    for file_path in swift_files(sys.argv[1:]):
        with open(file_path, encoding="utf-8") as handle:
            for line in handle:
                stripped = line.strip()
                if stripped.startswith("//"):
                    continue  # skip commented-out code
                for match in PATTERN.finditer(line):
                    key = match.group(1)
                    if not key.strip():
                        continue
                    (interpolated if "\\(" in key else plain).add(key)
    for key in sorted(plain):
        print(key)
    print("##### INTERPOLATED #####")
    for key in sorted(interpolated):
        print(key)


if __name__ == "__main__":
    main()
