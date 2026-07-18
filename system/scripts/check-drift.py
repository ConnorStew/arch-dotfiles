#!/usr/bin/env python3
"""Report drift between the packages declared in the Ansible vars and what's
actually installed on this machine.

This replaces the old ``packages/dump.sh`` workflow. The vars under
``system/group_vars`` and ``system/host_vars`` are now the source of truth, and
this script simply flags either direction of drift:

  - declared but NOT installed  (something the playbook would install is missing)
  - installed but NOT declared  (something added ad hoc that isn't tracked)

It checks native pacman packages, AUR packages, and flatpak apps. Some
known-noise entries (the Arch baseline, ``*-debug`` AUR packages) are ignored so
real drift stands out. Claude Code is installed via its native user-local
installer (not npm/AUR), so it's not tracked here.

Usage:
    system/scripts/check-drift.py

Exit status is 0 when everything is in sync, 1 when any drift is found.
"""
from __future__ import annotations

import platform
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml

# This script lives in system/scripts/, so its grandparent is system/.
SYSDIR = Path(__file__).resolve().parent.parent

# The Arch install-time baseline: packages a fresh install (archinstall / the
# `base` group) already provides. They're deliberately left out of the package
# vars — the playbook only manages what we add on top — so we also ignore them
# here, otherwise every run would flag them as "installed but not declared".
BASE: set[str] = {
    "base",
    "base-devel",
    "linux",
    "linux-firmware",
    "linux-headers",
    "mkinitcpio",
    "grub",
    "efibootmgr",
    "os-prober",
    "lvm2",
    "sudo",
    "man-db",
    "man-pages",
    "nano",
    "networkmanager",
    "openssh",
    "wpa_supplicant",
}

# A loaded YAML vars file is a plain mapping of var name -> value.
VarsFile = dict[str, Any]


def load_vars() -> list[VarsFile]:
    """Load the group vars and this host's vars into a list of mappings.

    Returns the two files in precedence-agnostic order (we only ever union
    values across both, so order doesn't matter). Exits if this machine has no
    host_vars file, since that means it hasn't been onboarded into the playbook.
    """
    group_vars: VarsFile = yaml.safe_load((SYSDIR / "group_vars" / "all.yml").read_text()) or {}

    hostname = platform.node()
    host_file = SYSDIR / "host_vars" / f"{hostname}.yml"
    if not host_file.exists():
        sys.exit(f"No host_vars/{hostname}.yml — is this an onboarded machine?")
    host_vars: VarsFile = yaml.safe_load(host_file.read_text()) or {}

    return [group_vars, host_vars]


def declared(sources: list[VarsFile], *keys: str) -> set[str]:
    """Union the list-valued vars named by ``keys`` across all ``sources``.

    Missing or null vars are treated as empty lists, so e.g.
    ``declared(sources, "packages_common", "packages_host")`` merges the common
    list with this host's additions into one set.
    """
    result: set[str] = set()
    for source in sources:
        for key in keys:
            result.update(source.get(key) or [])
    return result


def installed(cmd: list[str]) -> set[str]:
    """Run a query command and return its whitespace-split stdout as a set.

    Used for the package managers that print one item per line (pacman,
    flatpak). A failing command yields an empty set rather than raising, so a
    machine lacking e.g. flatpak simply reports everything as "not installed".
    """
    result = subprocess.run(cmd, capture_output=True, text=True)
    return set(result.stdout.split())


def report(
    label: str,
    declared_set: set[str],
    installed_set: set[str],
    ignore: set[str] = frozenset(),
) -> bool:
    """Print the drift for one package category and return whether any was found.

    ``ignore`` is subtracted only from the "installed but not declared" side —
    it suppresses known-noise packages we never intend to track.
    """
    missing = declared_set - installed_set          # declared, but not present
    extra = installed_set - declared_set - ignore   # present, but not declared

    if missing:
        print(f"[{label}] declared but NOT installed:")
        for pkg in sorted(missing):
            print(f"  - {pkg}")
    if extra:
        print(f"[{label}] installed but NOT declared:")
        for pkg in sorted(extra):
            print(f"  + {pkg}")
    if not missing and not extra:
        print(f"[{label}] in sync")

    return bool(missing or extra)


def main() -> None:
    sources = load_vars()
    drift = False

    # Native pacman packages: explicitly-installed, non-foreign (-Qenq).
    drift |= report(
        "native",
        declared(sources, "packages_common", "packages_host"),
        installed(["pacman", "-Qenq"]),
        ignore=BASE,
    )

    # AUR packages: explicitly-installed foreign packages (-Qemq). Drop the
    # auto-generated *-debug variants pacman keeps around for split debug info.
    aur_installed = {
        pkg for pkg in installed(["pacman", "-Qemq"]) if not pkg.endswith("-debug")
    }
    drift |= report(
        "aur",
        declared(sources, "aur_packages", "aur_host"),
        aur_installed,
    )

    # Flatpak apps: one application ID per line.
    drift |= report(
        "flatpak",
        declared(sources, "flatpak_apps"),
        installed(["flatpak", "list", "--app", "--columns=application"]),
    )

    sys.exit(1 if drift else 0)


if __name__ == "__main__":
    main()
