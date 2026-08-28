param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path)

$ErrorActionPreference = 'Stop'
$anchor = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'paper\FROZEN_BASE.json') -Raw | ConvertFrom-Json
$failures = [System.Collections.Generic.List[string]]::new()

function Resolve-LocalTag([string]$tag) {
    return (& git -C $RepositoryRoot rev-list -n1 $tag 2>$null).Trim()
}
function Short-Sha([string]$sha) { if ($sha.Length -gt 7) { return $sha.Substring(0,7) }; return $sha }
function Sha-Matches([string]$actual, [string]$expected) { return $actual.ToLowerInvariant().StartsWith($expected.ToLowerInvariant()) }

$simulationActual = Resolve-LocalTag $anchor.frozenRelease.tag
$exp11Actual = Resolve-LocalTag $anchor.supplementalEvidence.tag
if (-not (Sha-Matches $simulationActual $anchor.frozenRelease.sha)) { $failures.Add("local simulation tag mismatch: $simulationActual") }
if (-not (Sha-Matches $exp11Actual $anchor.supplementalEvidence.sha)) { $failures.Add("local EXP11 tag mismatch: $exp11Actual") }

$remoteLines = @(& git -C $RepositoryRoot ls-remote --tags origin)
if ($LASTEXITCODE -ne 0) { $failures.Add('remote tag query failed') }
function Resolve-RemoteTag([string]$tag) {
    $peeledSuffix = "refs/tags/$tag^{}"
    $directSuffix = "refs/tags/$tag"
    $peeled = @($remoteLines | Where-Object { $_ -like "*$peeledSuffix" })
    $selected = if ($peeled.Count) { $peeled[0] } else { @($remoteLines | Where-Object { $_ -like "*$directSuffix" })[0] }
    if ([string]::IsNullOrWhiteSpace($selected)) { return '' }
    return ($selected -split '\s+')[0]
}
$simulationRemote = Resolve-RemoteTag $anchor.frozenRelease.tag
$exp11Remote = Resolve-RemoteTag $anchor.supplementalEvidence.tag
if (-not (Sha-Matches $simulationRemote $anchor.frozenRelease.sha)) { $failures.Add("remote simulation tag mismatch: $simulationRemote") }
if (-not (Sha-Matches $exp11Remote $anchor.supplementalEvidence.sha)) { $failures.Add("remote EXP11 tag mismatch: $exp11Remote") }

$touched = [System.Collections.Generic.List[string]]::new()
foreach ($path in $anchor.readOnlyPaths) {
    $changed = @(& git -C $RepositoryRoot diff --name-only $anchor.frozenRelease.sha -- $path)
    $dirty = @(& git -C $RepositoryRoot status --porcelain -- $path)
    foreach ($item in $changed) { if ($item) { $touched.Add($item.Trim()) } }
    foreach ($item in $dirty) { if ($item.Length -gt 3) { $touched.Add($item.Substring(3).Trim()) } }
}
$touchedUnique = @($touched | Sort-Object -Unique)
if ($touchedUnique.Count) { $failures.Add("scientific-source modifications: $($touchedUnique -join ', ')") }

$relationship = [string]$anchor.supplementalEvidence.relationshipToFrozen
if (($relationship -notmatch 'outside simulation-v1\.0 boundary') -or ($relationship -notmatch 'paper may cite')) {
    $failures.Add('EXP11 boundary wording missing from FROZEN_BASE.json')
}
$exp11Tidy = Join-Path $RepositoryRoot ($anchor.supplementalEvidence.resultDirectory + '\tidy.csv')
if (-not (Test-Path -LiteralPath $exp11Tidy)) { $failures.Add('frozen EXP11 tidy.csv missing') }

$report = [ordered]@{
    pass = ($failures.Count -eq 0)
    simulation = [ordered]@{ tag=$anchor.frozenRelease.tag; expected=$anchor.frozenRelease.sha; local=(Short-Sha $simulationActual); remote=(Short-Sha $simulationRemote); state=if ((Sha-Matches $simulationActual $anchor.frozenRelease.sha) -and (Sha-Matches $simulationRemote $anchor.frozenRelease.sha)) {'TAG_OK'} else {'TAG_MISMATCH'} }
    exp11 = [ordered]@{ tag=$anchor.supplementalEvidence.tag; expected=$anchor.supplementalEvidence.sha; local=(Short-Sha $exp11Actual); remote=(Short-Sha $exp11Remote); state=if ((Sha-Matches $exp11Actual $anchor.supplementalEvidence.sha) -and (Sha-Matches $exp11Remote $anchor.supplementalEvidence.sha)) {'SUPPLEMENTAL_ANCHOR_VERIFIED'} else {'TAG_MISMATCH'}; relationship=$relationship }
    scientificSourceModifications = $touchedUnique.Count
    touchedScientificPaths = $touchedUnique
    failures = @($failures)
}
$jsonPath = Join-Path $RepositoryRoot 'paper\generated\paper_guard_report.json'
[IO.File]::WriteAllText($jsonPath, ($report | ConvertTo-Json -Depth 5) + "`r`n", [Text.UTF8Encoding]::new($false))

if ($failures.Count) { $failures | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output "PAPER_GUARD_OK TAG_OK simulation-v1.0=$(Short-Sha $simulationActual) remote=$(Short-Sha $simulationRemote)"
Write-Output "EXP11 supplemental anchor verified exp11-locked-supplemental=$(Short-Sha $exp11Actual) remote=$(Short-Sha $exp11Remote)"
Write-Output "scientific-source modifications=0 boundary=outside-simulation-v1.0"
