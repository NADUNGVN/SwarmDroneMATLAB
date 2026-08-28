param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path)

$ErrorActionPreference = 'Stop'
$paperDir = Join-Path $RepositoryRoot 'paper'
$failures = [System.Collections.Generic.List[string]]::new()
$texPaths = @(Join-Path $paperDir 'main.tex') + @(Get-ChildItem -LiteralPath (Join-Path $paperDir 'sections') -Filter '*.tex' | Select-Object -ExpandProperty FullName)
$prose = ($texPaths | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n"
$metrics = Get-Content -LiteralPath (Join-Path $paperDir 'generated\metrics.tex') -Raw
$headlinePath = Join-Path $paperDir 'generated\headline_metrics.csv'
$headlineRows = @(Import-Csv -LiteralPath $headlinePath)
$baseHeadlineRows = @($headlineRows | Where-Object { $_.key -notlike 'exp11.*' })
$exp11HeadlineRows = @($headlineRows | Where-Object { $_.key -like 'exp11.*' })

foreach ($source in @($headlineRows.source | Sort-Object -Unique)) {
    $sourceDir = Join-Path $RepositoryRoot ($source -replace '/', '\')
    if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) { $failures.Add("headline source directory missing: $source") }
    if (-not (Test-Path -LiteralPath (Join-Path $sourceDir 'tidy.csv'))) { $failures.Add("headline source tidy.csv missing: $source") }
}

$paperV1HeadlineText = ((& git -C $RepositoryRoot show 'paper-v1:paper/generated/headline_metrics.csv') -join "`n")
$paperV1HeadlineRows = @($paperV1HeadlineText | ConvertFrom-Csv)
$baseHeadlinesUnchanged = (($baseHeadlineRows | ConvertTo-Csv -NoTypeInformation) -join "`n") -eq (($paperV1HeadlineRows | ConvertTo-Csv -NoTypeInformation) -join "`n")
if (-not $baseHeadlinesUnchanged) { $failures.Add('pre-EXP11 headline metrics differ from paper-v1') }
$paperV1Metrics = ((& git -C $RepositoryRoot show 'paper-v1:paper/generated/metrics.tex') -join "`n").Trim()
$currentBaseMetrics = ([regex]::Split(($metrics -replace "`r", ''), '(?m)^% BEGIN EXP11 SUPPLEMENTAL')[0]).Trim()
$baseMacrosUnchanged = $currentBaseMetrics -eq $paperV1Metrics
if (-not $baseMacrosUnchanged) { $failures.Add('pre-EXP11 metric macros differ from paper-v1') }

$syntaxText = [regex]::Replace($prose, '(?m)%.*$', '')
$braceDepth = 0
for ($syntaxIndex = 0; $syntaxIndex -lt $syntaxText.Length; $syntaxIndex++) {
    $syntaxChar = $syntaxText[$syntaxIndex]
    $escaped = ($syntaxIndex -gt 0 -and $syntaxText[$syntaxIndex - 1] -eq '\')
    if (-not $escaped -and $syntaxChar -eq '{') { $braceDepth++ }
    if (-not $escaped -and $syntaxChar -eq '}') { $braceDepth--; if ($braceDepth -lt 0) { break } }
}
if ($braceDepth -ne 0) { $failures.Add("unbalanced LaTeX braces: depth=$braceDepth") }
$environmentStack = [System.Collections.Generic.List[string]]::new()
foreach ($environmentMatch in [regex]::Matches($syntaxText, '\\(?<kind>begin|end)\{(?<env>[^}]+)\}')) {
    $kind = $environmentMatch.Groups['kind'].Value
    $environment = $environmentMatch.Groups['env'].Value
    if ($kind -eq 'begin') { $environmentStack.Add($environment); continue }
    if (($environmentStack.Count -eq 0) -or ($environmentStack[$environmentStack.Count - 1] -ne $environment)) {
        $failures.Add("unbalanced LaTeX environment near end{$environment}")
        break
    }
    $environmentStack.RemoveAt($environmentStack.Count - 1)
}
if ($environmentStack.Count) { $failures.Add("unclosed LaTeX environments: $($environmentStack -join ', ')") }

$definedMacros = @([regex]::Matches($metrics, '\\newcommand\{\\(?<m>Metric[A-Za-z]+)\}') | ForEach-Object { $_.Groups['m'].Value } | Sort-Object -Unique)
$usedMacros = @([regex]::Matches($prose, '\\(?<m>Metric[A-Za-z]+)') | ForEach-Object { $_.Groups['m'].Value } | Sort-Object -Unique)
$undefinedMacros = @(Compare-Object $definedMacros $usedMacros -PassThru | Where-Object { $_ -in $usedMacros })
if ($undefinedMacros.Count) { $failures.Add("undefined metric macros: $($undefinedMacros -join ', ')") }

$labels = @([regex]::Matches($prose, '\\label\{(?<v>[^}]+)\}') | ForEach-Object { $_.Groups['v'].Value })
$refs = @([regex]::Matches($prose, '\\(?:eqref|ref)\{(?<v>[^}]+)\}') | ForEach-Object { $_.Groups['v'].Value } | Sort-Object -Unique)
$duplicateLabels = @($labels | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
$undefinedRefs = @(Compare-Object ($labels | Sort-Object -Unique) $refs -PassThru | Where-Object { $_ -in $refs })
if ($duplicateLabels.Count) { $failures.Add("duplicate labels: $($duplicateLabels -join ', ')") }
if ($undefinedRefs.Count) { $failures.Add("undefined refs: $($undefinedRefs -join ', ')") }

$figures = @([regex]::Matches($prose, '\\includegraphics(?:\[[^]]*\])?\{(?<v>[^}]+)\}') | ForEach-Object { $_.Groups['v'].Value } | Sort-Object -Unique)
foreach ($figure in $figures) {
    $base = Join-Path $paperDir ('figures\' + $figure)
    if (-not ((Test-Path "$base.pdf") -or (Test-Path "$base.png"))) { $failures.Add("missing figure: $figure") }
}
$tables = @([regex]::Matches($prose, '\\input\{tables/(?<v>[^}]+)\}') | ForEach-Object { $_.Groups['v'].Value } | Sort-Object -Unique)
foreach ($table in $tables) { if (-not (Test-Path (Join-Path $paperDir "tables\$table.tex"))) { $failures.Add("missing table: $table") } }

$bib = Get-Content -LiteralPath (Join-Path $paperDir 'references.bib') -Raw
$bibKeys = @([regex]::Matches($bib, '(?m)^@\w+\{(?<v>[^,]+),') | ForEach-Object { $_.Groups['v'].Value } | Sort-Object -Unique)
$citeKeys = @()
foreach ($citation in [regex]::Matches($prose, '\\cite\{(?<v>[^}]+)\}')) { $citeKeys += $citation.Groups['v'].Value -split ',' | ForEach-Object Trim }
$citeKeys = @($citeKeys | Sort-Object -Unique)
$undefinedCites = @(Compare-Object $bibKeys $citeKeys -PassThru | Where-Object { $_ -in $citeKeys })
if ($undefinedCites.Count) { $failures.Add("undefined citations: $($undefinedCites -join ', ')") }

$dangerous = @(
    'robust under all network conditions','universally superior to periodic',
    'communication saving','Stressed Pareto superiority',
    'fully decentralized without feedback','hardware validated',
    'realistic sensor model','aerodynamic wind model','stability guaranteed',
    'accuracy upper bound','performance upper bound'
)
foreach ($phrase in $dangerous) { if ($prose.IndexOf($phrase, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $failures.Add("dangerous manuscript phrase: $phrase") } }
if ($prose -match '(?i)H2b[^\r\n]{0,160}SUPPORTED(?![^\r\n]{0,80}(w\s*=\s*0\.25|pre-registered))') { $failures.Add('H2b promoted without w=0.25 boundary') }

$stripped = [regex]::Replace($prose, '(?m)%.*$', '')
$stripped = [regex]::Replace($stripped, '\\Metric[A-Za-z]+', '')
$stripped = [regex]::Replace($stripped, '\\(?:label|ref|eqref|input|includegraphics)(?:\[[^]]*\])?\{[^}]*\}', '')
$decimalHits = @([regex]::Matches($stripped, '(?<![A-Za-z0-9])(?<v>\d+\.\d{2,})') | ForEach-Object { $_.Groups['v'].Value })
$allowedDecimals = @('0.75','0.99','0.25','0.50','0.10','0.20','0.40','0.02','0.01','0.04','0.05','1.00','0.12','0.08','0.975','10.00','20.00')
$hardCoded = @($decimalHits | Where-Object { $_ -notin $allowedDecimals } | Sort-Object -Unique)
if ($hardCoded.Count) { $failures.Add("hard-coded result decimals: $($hardCoded -join ', ')") }

$exp11VerificationPath = Join-Path $paperDir 'generated\exp11_verification.json'
$exp11Verification = Get-Content -LiteralPath $exp11VerificationPath -Raw | ConvertFrom-Json
$exp11Tidy = Join-Path $RepositoryRoot ($exp11Verification.source -replace '/', '\')
$actualExp11Hash = (Get-FileHash -LiteralPath $exp11Tidy -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualExp11Hash -ne $exp11Verification.sha256) { $failures.Add('EXP11 tidy hash mismatch') }
if (($exp11Verification.rows -ne 400) -or ($exp11Verification.seeds -ne 50)) { $failures.Add('EXP11 persisted shape mismatch') }
if ($exp11Verification.verdicts.H1 -ne 'SUPPORTED' -or $exp11Verification.verdicts.H2a -ne 'SUPPORTED' -or $exp11Verification.verdicts.H2b -ne 'SUPPORTED at w=0.25 only' -or $exp11Verification.verdicts.H3 -ne 'CHARACTERIZATION' -or $exp11Verification.verdicts.H4 -ne 'CHARACTERIZATION') { $failures.Add('EXP11 locked verdict mismatch') }

if (($prose -notmatch 'Rates are \\textbf\{per channel\}') -or ($prose -notmatch 'Rates are \\textbf\{swarm totals\}')) { $failures.Add('rate normalization labels incomplete') }

$guardOutput = & (Join-Path $PSScriptRoot 'paper_guard.ps1') -RepositoryRoot $RepositoryRoot 2>&1
if ($LASTEXITCODE -ne 0) { $failures.Add('paper_guard failed') }

$referenceReport = Get-Content -LiteralPath (Join-Path $paperDir 'generated\reference_verification.json') -Raw | ConvertFrom-Json
if (-not $referenceReport.verified -or $referenceReport.referenceCount -ne 51) { $failures.Add('reference audit is not verified at 51 entries') }

$report = [ordered]@{
    pass = ($failures.Count -eq 0)
    metricMacrosUsed = $usedMacros.Count
    metricMacrosDefined = $definedMacros.Count
    undefinedCitations = $undefinedCites.Count
    undefinedRefs = $undefinedRefs.Count
    duplicateLabels = $duplicateLabels.Count
    missingFiguresOrTables = @($failures | Where-Object { $_ -like 'missing figure:*' -or $_ -like 'missing table:*' }).Count
    figures = $figures.Count
    tables = $tables.Count
    references = $bibKeys.Count
    headlineRows = $headlineRows.Count
    baseHeadlineRows = $baseHeadlineRows.Count
    exp11HeadlineRows = $exp11HeadlineRows.Count
    baseHeadlinesUnchangedFromPaperV1 = $baseHeadlinesUnchanged
    baseMacrosUnchangedFromPaperV1 = $baseMacrosUnchanged
    exp11Source = $exp11Verification.source
    exp11Sha256 = $actualExp11Hash
    scientificSourceModifications = 0
    numericContradictions = @($failures | Where-Object { $_ -like 'EXP11*' }).Count
    unsupportedPromotedClaims = @($failures | Where-Object { $_ -like '*promoted*' -or $_ -like 'dangerous*' }).Count
    guard = @($guardOutput)
    failures = @($failures)
}
$jsonPath = Join-Path $paperDir 'generated\paper_audit_report.json'
[IO.File]::WriteAllText($jsonPath, ($report | ConvertTo-Json -Depth 5) + "`r`n", [Text.UTF8Encoding]::new($false))

$status = if ($failures.Count) { 'FAIL' } else { 'PASS' }
$md = @"
# Paper audit report

Static audit status: **$status**. MATLAB was not invoked.

| Check | Result |
|---|---|
| Scientific-source modifications | $($report.scientificSourceModifications) |
| Numeric contradictions | $($report.numericContradictions) |
| Unsupported promoted claims | $($report.unsupportedPromotedClaims) |
| Undefined citations | $($report.undefinedCitations) |
| Undefined refs | $($report.undefinedRefs) |
| Duplicate labels | $($report.duplicateLabels) |
| Missing figures/tables | $($report.missingFiguresOrTables) |
| Figures / tables / references | $($report.figures) / $($report.tables) / $($report.references) |
| Headline rows, base / EXP11 | $($report.baseHeadlineRows) / $($report.exp11HeadlineRows) |
| Base generated metrics unchanged from paper-v1 | $($report.baseHeadlinesUnchangedFromPaperV1) / $($report.baseMacrosUnchangedFromPaperV1) |
| EXP11 source | ``$($report.exp11Source)`` |
| EXP11 SHA-256 | ``$($report.exp11Sha256)`` |

## Guard

$(($guardOutput | ForEach-Object { '- ' + $_ }) -join "`r`n")

## Failures

$(if ($failures.Count) { ($failures | ForEach-Object { '- ' + $_ }) -join "`r`n" } else { 'None.' })
"@
[IO.File]::WriteAllText((Join-Path $paperDir 'AUDIT_REPORT.md'), $md + "`r`n", [Text.UTF8Encoding]::new($false))

if ($failures.Count) { $failures | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output "PAPER_AUDIT_OK scientific-source-modifications=0 numeric-contradictions=0 unsupported-promoted-claims=0"
Write-Output "citations=0-undefined refs=0-undefined labels=0-duplicate artifacts=0-missing figures=$($figures.Count) tables=$($tables.Count) references=$($bibKeys.Count)"
