$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$core = Get-Content -Raw (Join-Path $root 'LagomLedger\Core.lua')
$compatibility = Get-Content -Raw (Join-Path $root 'LagomLedger\ReferenceCompatibility.lua')
$ui = Get-Content -Raw (Join-Path $root 'LagomLedger\UI.lua')
$toc = Get-Content -Raw (Join-Path $root 'LagomLedger\LagomLedger.toc')
$workflow = Get-Content -Raw (Join-Path $root '.github\workflows\release.yml')
$packageMeta = Get-Content -Raw (Join-Path $root '.pkgmeta')

function Assert-Contains([string]$Text, [string]$Needle, [string]$Label) {
    if (-not $Text.Contains($Needle)) { throw "Missing ${Label}: $Needle" }
}

function Assert-NotContains([string]$Text, [string]$Needle, [string]$Label) {
    if ($Text.Contains($Needle)) { throw "Unexpected ${Label}: $Needle" }
}

if ($toc.IndexOf('Core.lua') -ge $toc.IndexOf('ReferenceCompatibility.lua') -or $toc.IndexOf('ReferenceCompatibility.lua') -ge $toc.IndexOf('Casino.lua')) {
    throw 'Invalid compatibility load order.'
}
Assert-Contains $toc '## AddonCompartmentFunc: LagomLedger_OnAddonCompartmentClick' 'addon compartment handler'
Assert-Contains $compatibility 'LL.LEGACY_COMM_PREFIX = "LagomGuild"' 'reference addon prefix'
Assert-Contains $compatibility '"S;%s;%d;%d;%d;%s;%s"' 'reference statistics protocol'
Assert-Contains $compatibility '"B;%s;%s;%s;%d;%s;%s;%d;%s"' 'reference bounty protocol'
Assert-Contains $compatibility '"PLAYER_PVP_KILLS_CHANGED"' 'honorable kill event'
Assert-Contains $compatibility 'C_Timer.NewTicker(5' 'honorable kill fallback poll'
Assert-Contains $compatibility 'function LL:ScanReferenceUnit(unit)' 'bounty target scan'
Assert-NotContains ($core + $compatibility) 'COMBAT_LOG_EVENT_UNFILTERED' 'forbidden combat-log registration'
Assert-Contains $core 'primaryProfessions = player.primaryProfessions' 'native profile extension'
Assert-Contains $ui 'local tabs = { "Kills", "Deaths", "Bounties", "Professions" }' 'reference board tabs'
Assert-Contains $ui 'function LL:ToggleCasino()' 'retained casino entry point'
Assert-Contains $ui 'function LL:BuildMinimapButton()' 'retained minimap button'
Assert-Contains $workflow "tags: ['v*']" 'version-tag trigger'
Assert-Contains $workflow 'BigWigsMods/packager@v2' 'BigWigs packager action'
Assert-Contains $workflow 'GH_API_TOKEN: ${{ github.token }}' 'GitHub release token mapping'
Assert-Contains $workflow 'contents: write' 'release permission'
Assert-Contains $workflow 'fetch-depth: 0' 'tag history checkout'
Assert-Contains $workflow 'test "v${toc_version}" = "${GITHUB_REF_NAME}"' 'tag and TOC version check'
Assert-Contains $packageMeta 'package-as: LagomLedger' 'package name'
Assert-Contains $packageMeta 'LagomLedger/LagomLedger: LagomLedger' 'addon folder mapping'
Assert-Contains $packageMeta '  - tests' 'test exclusion from release package'

Write-Output 'Reference compatibility static contract passed.'

