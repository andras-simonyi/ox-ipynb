"""Validate .ipynb files against the nbformat JSON schema.

Usage: uv run --with nbformat scripts/validate-notebooks.py FILE.ipynb...

Colab and Jupyter silently drop or refuse notebooks that violate the schema,
so every exported notebook should pass this check.
"""

import sys

import nbformat


def main(paths: list[str]) -> int:
    failed = 0
    for path in paths:
        try:
            nb = nbformat.read(path, as_version=nbformat.NO_CONVERT)
            nbformat.validate(nb)
        except Exception as err:  # noqa: BLE001 - report any failure per file
            failed += 1
            print(f"INVALID {path}: {err}")
        else:
            print(f"ok      {path}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
