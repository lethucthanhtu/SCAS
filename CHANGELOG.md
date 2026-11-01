# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- Steam is found through the running `steam` process again (the fallback called
  `Get-Process` with a parameter that does not exist).
- Grid names that point outside `SCAS_grid` (`..`, `.`, `.hidden`, paths) are rejected;
  `-d ..` used to delete the whole Steam `userdata` folder.
- `-c <name>` backs up the current grid as `backup_<timestamp>` before replacing it, and stops
  if copying fails instead of leaving Steam with no grid.
- `-d` without a name deletes the current grid after the backup, as documented (it only made
  the backup but printed "Current grid deleted").

### Added

- README: restore and uninstall steps, name rules. PSScriptAnalyzer in CI.
