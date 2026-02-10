# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Changed

- Refined `README.md` with a cleaner structure and modernized copy.
- Added GitHub issue templates for app requests and bug reports.

## [2026-02-10]

### Added

- Added new apps: Jellyfin, Gopeed, ANI-RSS.
- Added dedicated workflows: `build-jellyfin.yml`, `build-gopeed.yml`, `build-ani-rss.yml`.

### Changed

- Unified display names: `Plex`, `Emby`, `Jellyfin`, `Gopeed`, `ANI-RSS`.
- Updated reusable CI app allowlist to include the three new apps.

### Fixed

- Jellyfin startup compatibility:
  - Switched to `network.xml` for HTTP port configuration (`8097`).
  - Bundled `jellyfin-ffmpeg` and set runtime `LD_LIBRARY_PATH`.
- Gopeed packaging/runtime:
  - Switched from desktop `.deb` package to headless `gopeed-web` binary package.
  - Included `bin/gopeed-server` in package payload.
  - Corrected startup flags to `-A/-P/-d`.
