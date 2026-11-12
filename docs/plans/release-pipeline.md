# Release pipeline task note

- Updated: 2026-11-11
- Scope: GitHub Actions validation and tagged GitHub Releases for Lagom Ledger on World of Warcraft Forever.

## Behavior

- Pull requests and pushes to `main` run `tests/ReferenceCompatibility.Contract.Tests.ps1` only.
- A pushed tag matching `v*` runs the same validation, verifies that the tag exactly matches `## Version` in `LagomLedger/LagomLedger.toc`, then runs `BigWigsMods/packager@v2` with `-g forever`.
- The release job uses `GH_API_TOKEN: ${{ github.token }}` and job-scoped `contents: write`, so no personal access token or repository secret is required for GitHub Releases.
- `fetch-depth: 0` keeps tag history available for the packager's generated changelog.
- `.pkgmeta` maps the repository's nested `LagomLedger` source directory to the ZIP's `LagomLedger` installation folder and excludes project-only files.

## Release procedure

1. Update `## Version` in `LagomLedger/LagomLedger.toc`, for example to `1.7.0`. The addon reads its release version from this metadata.
2. Push the version commit to `main`.
3. Create and push an annotated tag with the same version prefixed by `v`:

   ```powershell
   git tag -a v1.7.0 -m "Lagom Ledger 1.7.0"
   git push origin v1.7.0
   ```

4. The workflow packages the `LagomLedger` addon and creates a GitHub Release with its ZIP asset.

## Validation

- Static: workflow content is asserted by `tests/ReferenceCompatibility.Contract.Tests.ps1`.
- GitHub Actions runtime: pending the first pushed release tag.

## First release candidate

- Prepared version: `1.7.0`.
- The addon and TOC version fields match; the static contract verifies this before the tag is created.
- Create the release tag only after the pull request is merged and the in-game checks in the integration matrix have been accepted.

## Sources

- BigWigs packager workflow guide: https://github.com/BigWigsMods/packager/wiki/GitHub-Actions-workflow
- BigWigs packager action: https://github.com/BigWigsMods/packager
- Blizzard forum release-workflow discussion: https://us.forums.blizzard.com/en/wow/t/creating-addon-releases-with-github-actions/613424
