# AGENTS.md

## Repo Purpose

- Personal Fedora Workstation bootstrap repo for Niri, Noctalia, and developer apps.
- This is not an app project: there are no package manifests, tests, CI, build steps, or lockfiles.

## High-Value Files

- `install.sh`: main Fedora-only installer; installs Niri/Noctalia, copies configs, sets GDM default session, configures DDC/CI permissions.
- `install_apps.sh`: runs all scripts in `scripts/` in a fixed order and pauses on failures.
- `niri-config/`: source copied to `~/.config/niri` by `install.sh`.
- `noctalia-config/`: source copied to `~/.config/noctalia` by `install.sh`.

## Verification Commands

- Shell syntax for the main installer: `bash -n install.sh`.
- Shell syntax for app scripts: `for f in scripts/*.sh install_apps.sh; do bash -n "$f" || exit 1; done`.
- Niri config validation when `niri` is installed: `niri validate --config niri-config/config.kdl`.
- Check git state before commits/pushes: `git status --short` and `git diff`.

## Install Flow Gotchas

- `install.sh` is intentionally Fedora Workstation-specific and exits unless `/etc/fedora-release` and `dnf` exist.
- The Terra repo setup is idempotent; do not blindly re-add repo ID `terra` or DNF can fail with duplicate repo configuration.
- Do not add `power-profiles-daemon` back as a required package; it conflicts with Fedora 44 `tuned-ppd`.
- `install.sh` backs up existing configs before copying: `~/.config/niri.backup.*` and `~/.config/noctalia.backup.*`.
- The GDM default session is set through `/var/lib/AccountsService/users/$USER` using `Session=niri` and `XSession=niri`.

## Niri / Noctalia Details

- Noctalia autostart should stay as `spawn-at-startup "qs" "-c" "noctalia-shell"`; `spawn-sh-at-startup "qs -c noctalia-shell"` caused a black-screen session.
- `niri-config/config.kdl` only includes files from `niri-config/cfg/`; update the included file, not an installed copy, unless applying a live fix too.
- `niri-config/cfg/layout.kdl` uses transparent background so Noctalia wallpaper/backdrop can show.
- `noctalia-config/settings.json` stores the user's bar widgets and dock state; sync user changes from `~/.config/noctalia/` into `noctalia-config/` before committing.

## External Monitor Brightness

- External monitor brightness depends on DDC/CI via `ddcutil`, `i2c-tools`, module `i2c-dev`, group `i2c`, and udev rule `/etc/udev/rules.d/45-i2c-tools.rules`.
- After adding the user to group `i2c`, the user must log out and back in before Noctalia can control monitor brightness.
- Useful checks: `ddcutil detect` and `ddcutil getvcp 10`.

## Style / Editing

- Keep installer changes idempotent; this repo is meant to be rerun on the same machine.
- Prefer ASCII in new files; existing scripts include some Unicode output, but new automation should not require it.
- If changing live configs under `~/.config`, also update the repo copy under `niri-config/` or `noctalia-config/`.
