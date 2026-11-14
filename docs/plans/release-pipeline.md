# GitHub Actions and release workflow

This note describes the repository's current validation and release setup. Check the workflow and live GitHub rules before each release; repository settings can change independently of source.

## Validation workflow

Pull requests to `main`, pushes to `main`, matching version tags, and manual workflow dispatch run `.github/workflows/release.yml`. The validation job installs Lua 5.1, parses every addon Lua file, and runs the PowerShell compatibility contract script.

A `v*` tag also starts the release job after validation. The job verifies that the tag version matches `## Version` in `LagomLedger/LagomLedger.toc`, then runs the pinned BigWigs packager with the `forever` game target. It uses the workflow's GitHub token with job-scoped `contents: write` permission.

`.pkgmeta` packages the nested addon source as a root `LagomLedger/` folder and excludes repository-only docs, tests, workflows and Graphify output.

## Pull request and repository rules

All addon changes should go through a pull request. Use the repository's current ruleset for required checks, review count and owner bypass; do not rely on old screenshots or instructions in this file as proof of current settings. The workflow validates code but does not itself enforce review requirements.

## Release procedure

1. Merge the reviewed release changes to `main`.
2. Set `## Version` in `LagomLedger/LagomLedger.toc` to the intended addon version.
3. Create and push an annotated tag with the matching `v` prefix. For example, if the TOC says `1.8.0`, use `v1.8.0`.
4. Wait for the tag workflow to pass and publish its GitHub Release.
5. Inspect the release ZIP: it should contain `LagomLedger/LagomLedger.toc` and the addon's Lua files under `LagomLedger/`, with no repository wrapper folder or maintenance files.
6. Install the ZIP in WoW Forever and verify the addon loads, the main tabs open, and a second addon client receives a guild synchronization.

## Local package preflight

The pinned BigWigs packager supports `-d` to skip upload while still building the package. With its release script available, run `./release.sh -d -g forever`, then inspect the ZIP's file list before creating a release. This preflight is separate from GitHub Actions; passing it does not prove that the hosted workflow or in-game behavior works.

## Current validation limits

The source workflow defines static validation and tagged packaging. Whether a release has been published must be checked against current GitHub Releases and tags; this checkout's local tag list is not a complete source of remote release state. Forever acceptance still requires the game client and two guild members with the same addon build.
