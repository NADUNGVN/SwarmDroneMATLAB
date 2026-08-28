[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runRel = 'results/exp11_dynamic_network/2026-08-27_174026'
$runDir = Join-Path $root ($runRel -replace '/', '\')
$tidyPath = Join-Path $runDir 'tidy.csv'
$paperDir = Join-Path $root 'paper'
$generatedDir = Join-Path $paperDir 'generated'
$tablesDir = Join-Path $paperDir 'tables'
$figuresDir = Join-Path $paperDir 'figures'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

if (-not (Test-Path -LiteralPath $tidyPath -PathType Leaf)) {
    throw "Frozen EXP11 dataset is missing: $tidyPath"
}

$rows = @(Import-Csv -LiteralPath $tidyPath)
$methods = @('P5', 'P10', 'P12.5', 'P20', 'P25', 'StateEvent', 'Causal', 'OraclePeriodic')
$seeds = @($rows.seed | Sort-Object -Unique)

if ($rows.Count -ne 400 -or $seeds.Count -ne 50) {
    throw "EXP11 shape mismatch: expected 400 rows and 50 seeds; found $($rows.Count) rows and $($seeds.Count) seeds."
}

foreach ($method in $methods) {
    $count = @($rows | Where-Object method -eq $method).Count
    if ($count -ne 50) {
        throw "EXP11 method $method has $count rows; expected 50."
    }
}

function Get-Mean {
    param([double[]]$Values)
    return [double](($Values | Measure-Object -Average).Average)
}

function Get-Column {
    param([string]$Method, [string]$Column)
    return [double[]]@(
        $rows |
            Where-Object method -eq $Method |
            Sort-Object { [int]$_.seed } |
            ForEach-Object { [double]($_.$Column) }
    )
}

function Get-PairedCI {
    param([double[]]$Values)

    $n = $Values.Count
    $mean = Get-Mean $Values
    $sumSquares = 0.0
    foreach ($value in $Values) {
        $sumSquares += ($value - $mean) * ($value - $mean)
    }

    $standardDeviation = [Math]::Sqrt($sumSquares / ($n - 1))
    $criticalT = 2.00957523448921 # two-sided 95% t critical value, df=49
    $halfWidth = $criticalT * $standardDeviation / [Math]::Sqrt($n)

    return [pscustomobject]@{
        mean = $mean
        lo = $mean - $halfWidth
        hi = $mean + $halfWidth
        n = $n
    }
}

function Compare-Methods {
    param([string]$Left, [string]$Right, [string]$Column)
    $leftValues = Get-Column $Left $Column
    $rightValues = Get-Column $Right $Column
    $differences = [double[]]::new($leftValues.Count)
    for ($index = 0; $index -lt $leftValues.Count; $index++) {
        $differences[$index] = $leftValues[$index] - $rightValues[$index]
    }
    return Get-PairedCI $differences
}

function Compare-Segments {
    param([int]$Left, [int]$Right)
    $leftValues = Get-Column 'Causal' ("SEG{0}_DATAHZ" -f $Left)
    $rightValues = Get-Column 'Causal' ("SEG{0}_DATAHZ" -f $Right)
    $differences = [double[]]::new($leftValues.Count)
    for ($index = 0; $index -lt $leftValues.Count; $index++) {
        $differences[$index] = $leftValues[$index] - $rightValues[$index]
    }
    return Get-PairedCI $differences
}

function Format-Number {
    param([double]$Value, [string]$Pattern)
    return $Value.ToString($Pattern, $culture)
}

function Csv-Escape {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    if ($Value.IndexOfAny([char[]]",`r`n") -ge 0) {
        return '"' + $Value.Replace('"', '""') + '"'
    }
    return $Value
}

$h1 = @(
    Compare-Segments 2 1
    Compare-Segments 3 2
    Compare-Segments 4 3
    Compare-Segments 5 4
)
$h2a = Compare-Methods 'Causal' 'P10' 'RMSE'
$h2b = Compare-Methods 'Causal' 'P20' 'TOTW025'
$broadcastP20 = Compare-Methods 'Causal' 'P20' 'BCASTHZ'
$broadcastP25 = Compare-Methods 'Causal' 'P25' 'BCASTHZ'
$oracleRmse = Compare-Methods 'Causal' 'OraclePeriodic' 'RMSE'
$oracleCost = Compare-Methods 'Causal' 'OraclePeriodic' 'TOTW025'
$oracleP10Rmse = Compare-Methods 'OraclePeriodic' 'P10' 'RMSE'
$oracleP10Cost = Compare-Methods 'OraclePeriodic' 'P10' 'TOTW025'
$p125Rmse = Compare-Methods 'Causal' 'P12.5' 'RMSE'
$p125Cost = Compare-Methods 'Causal' 'P12.5' 'TOTW025'

$means = @{}
foreach ($method in $methods) {
    $means[$method] = [pscustomobject]@{
        rmse = Get-Mean (Get-Column $method 'RMSE')
        w025 = Get-Mean (Get-Column $method 'TOTW025')
        broadcast = Get-Mean (Get-Column $method 'BCASTHZ')
        data = Get-Mean (Get-Column $method 'DATAHZ')
        ack = Get-Mean (Get-Column $method 'ACKHZ')
    }
}

$p125AccuracyPct = 100.0 * $means['Causal'].rmse / $means['P12.5'].rmse
$p125CostPct = 100.0 * $means['P12.5'].w025 / $means['Causal'].w025
$p125BroadcastPct = 100.0 * $means['P12.5'].broadcast / $means['Causal'].broadcast
$broadcastWorsePct = 100.0 * ($means['Causal'].broadcast / $means['P20'].broadcast - 1.0)
$oracleP10ImprovePct = 100.0 * ($means['P10'].rmse - $means['OraclePeriodic'].rmse) / $means['P10'].rmse

$h1Supported = $h1[0].lo -gt 0 -and $h1[1].lo -gt 0 -and $h1[2].hi -lt 0 -and $h1[3].hi -lt 0
$h2aSupported = $h2a.hi -lt 0
$h2bSupported = $h2b.hi -lt 0
if (-not ($h1Supported -and $h2aSupported -and $h2bSupported)) {
    throw 'Frozen EXP11 data contradict the locked H1/H2 interpretation.'
}

$metricRows = [System.Collections.Generic.List[object]]::new()
function Add-Metric {
    param(
        [string]$Key,
        [double]$Value,
        [double]$Lo = [double]::NaN,
        [double]$Hi = [double]::NaN,
        [int]$N = 50,
        [string]$Units,
        [string]$Note
    )
    $metricRows.Add([pscustomobject]@{
        key = $Key; value = $Value; ci_lo = $Lo; ci_hi = $Hi; n = $N
        units = $Units; source = $runRel; note = $Note
    })
}

for ($index = 0; $index -lt 4; $index++) {
    Add-Metric ("exp11.H1.adjacent_{0}" -f ($index + 1)) $h1[$index].mean $h1[$index].lo $h1[$index].hi 50 'swarm-total Hz' 'Causal adjacent-segment DATA-rate difference; paired over seeds'
}
Add-Metric 'exp11.H2a.rmse_causal_minus_p10' $h2a.mean $h2a.lo $h2a.hi 50 'm' 'preregistered H2a; paired over seeds'
Add-Metric 'exp11.H2b.total_w025_causal_minus_p20' $h2b.mean $h2b.lo $h2b.hi 50 'swarm-total Hz' 'preregistered H2b at w=0.25 only; paired over seeds'
Add-Metric 'exp11.broadcast.causal_minus_p20' $broadcastP20.mean $broadcastP20.lo $broadcastP20.hi 50 'swarm-total Hz' 'negative result: broadcast accounting reverses the comparison'
Add-Metric 'exp11.broadcast.causal_minus_p25' $broadcastP25.mean $broadcastP25.lo $broadcastP25.hi 50 'swarm-total Hz' 'negative result: Causal is also costlier than P25 under broadcast accounting'
Add-Metric 'exp11.oracle.rmse_causal_minus_oracle' $oracleRmse.mean $oracleRmse.lo $oracleRmse.hi 50 'm' 'oracle-information reference; characterization only'
Add-Metric 'exp11.oracle.total_w025_causal_minus_oracle' $oracleCost.mean $oracleCost.lo $oracleCost.hi 50 'swarm-total Hz' 'oracle-information reference; characterization only'
Add-Metric 'exp11.oracle.rmse_oracle_minus_p10' $oracleP10Rmse.mean $oracleP10Rmse.lo $oracleP10Rmse.hi 50 'm' 'oracle-information reference versus P10 at near-equal cost'
Add-Metric 'exp11.oracle.total_w025_oracle_minus_p10' $oracleP10Cost.mean $oracleP10Cost.lo $oracleP10Cost.hi 50 'swarm-total Hz' 'oracle-information reference versus P10 at near-equal cost'
Add-Metric 'exp11.p125.rmse_causal_minus_p125' $p125Rmse.mean $p125Rmse.lo $p125Rmse.hi 50 'm' 'prominent fixed-rate counterexample'
Add-Metric 'exp11.p125.total_w025_causal_minus_p125' $p125Cost.mean $p125Cost.lo $p125Cost.hi 50 'swarm-total Hz' 'prominent fixed-rate counterexample'
Add-Metric 'exp11.p125.accuracy_fraction' ($p125AccuracyPct / 100.0) ([double]::NaN) ([double]::NaN) 50 'fraction' 'Causal RMSE divided by P12.5 RMSE'
Add-Metric 'exp11.p125.total_w025_fraction' ($p125CostPct / 100.0) ([double]::NaN) ([double]::NaN) 50 'fraction' 'P12.5 cost divided by Causal cost'
Add-Metric 'exp11.p125.broadcast_fraction' ($p125BroadcastPct / 100.0) ([double]::NaN) ([double]::NaN) 50 'fraction' 'P12.5 broadcast cost divided by Causal broadcast cost'

foreach ($method in $methods) {
    $safe = if ($method -eq 'OraclePeriodic') { 'oracle' } else { $method.ToLowerInvariant().Replace('.', '') }
    Add-Metric "exp11.means.$safe.rmse" $means[$method].rmse ([double]::NaN) ([double]::NaN) 50 'm' 'mission mean'
    Add-Metric "exp11.means.$safe.total_w025" $means[$method].w025 ([double]::NaN) ([double]::NaN) 50 'swarm-total Hz' 'mission mean'
    Add-Metric "exp11.means.$safe.broadcast" $means[$method].broadcast ([double]::NaN) ([double]::NaN) 50 'swarm-total Hz' 'mission mean'
}

$headlinePath = Join-Path $generatedDir 'headline_metrics.csv'
$baseLines = @(Get-Content -LiteralPath $headlinePath | Where-Object { $_ -notmatch '^exp11\.' })
$newLines = foreach ($metric in $metricRows) {
    $values = @(
        $metric.key,
        (Format-Number $metric.value '0.#################'),
        $(if ([double]::IsNaN($metric.ci_lo)) { 'NaN' } else { Format-Number $metric.ci_lo '0.#################' }),
        $(if ([double]::IsNaN($metric.ci_hi)) { 'NaN' } else { Format-Number $metric.ci_hi '0.#################' }),
        [string]$metric.n,
        $metric.units,
        $metric.source,
        $metric.note
    )
    ($values | ForEach-Object { Csv-Escape ([string]$_) }) -join ','
}
[System.IO.File]::WriteAllLines($headlinePath, [string[]]@($baseLines + $newLines), $utf8NoBom)

$macros = [ordered]@{
    MetricElevenSeeds = '50'
    MetricElevenRuns = '400'
    MetricElevenHoneVerdict = 'SUPPORTED'
    MetricElevenHtwoaVerdict = 'SUPPORTED'
    MetricElevenHtwobVerdict = 'SUPPORTED at $w=0.25$ only'
    MetricElevenHthreeVerdict = 'CHARACTERIZATION'
    MetricElevenHfourVerdict = 'CHARACTERIZATION'
}
$words = @('One', 'Two', 'Three', 'Four')
for ($index = 0; $index -lt 4; $index++) {
    $tag = $words[$index]
    $macros["MetricElevenHone${tag}Mean"] = Format-Number $h1[$index].mean '+0.000;-0.000'
    $macros["MetricElevenHone${tag}Lo"] = Format-Number $h1[$index].lo '+0.000;-0.000'
    $macros["MetricElevenHone${tag}Hi"] = Format-Number $h1[$index].hi '+0.000;-0.000'
}
$macros.MetricElevenHtwoaMean = Format-Number $h2a.mean '+0.00000;-0.00000'
$macros.MetricElevenHtwoaLo = Format-Number $h2a.lo '+0.00000;-0.00000'
$macros.MetricElevenHtwoaHi = Format-Number $h2a.hi '+0.00000;-0.00000'
$macros.MetricElevenHtwobMean = Format-Number $h2b.mean '+0.000;-0.000'
$macros.MetricElevenHtwobLo = Format-Number $h2b.lo '+0.000;-0.000'
$macros.MetricElevenHtwobHi = Format-Number $h2b.hi '+0.000;-0.000'
$macros.MetricElevenBroadcastPtwentyMean = Format-Number $broadcastP20.mean '+0.000;-0.000'
$macros.MetricElevenBroadcastPtwentyLo = Format-Number $broadcastP20.lo '+0.000;-0.000'
$macros.MetricElevenBroadcastPtwentyHi = Format-Number $broadcastP20.hi '+0.000;-0.000'
$macros.MetricElevenBroadcastWorsePercent = Format-Number $broadcastWorsePct '0.0'
$macros.MetricElevenOracleRmseMean = Format-Number $oracleRmse.mean '+0.00000;-0.00000'
$macros.MetricElevenOracleRmseLo = Format-Number $oracleRmse.lo '+0.00000;-0.00000'
$macros.MetricElevenOracleRmseHi = Format-Number $oracleRmse.hi '+0.00000;-0.00000'
$macros.MetricElevenOracleCostMean = Format-Number $oracleCost.mean '+0.000;+0.000'
$macros.MetricElevenOracleCostLo = Format-Number $oracleCost.lo '+0.000;+0.000'
$macros.MetricElevenOracleCostHi = Format-Number $oracleCost.hi '+0.000;+0.000'
$macros.MetricElevenOraclePtenImprovePercent = Format-Number $oracleP10ImprovePct '0.0'
$macros.MetricElevenPonetwofiveAccuracyPercent = Format-Number $p125AccuracyPct '0.0'
$macros.MetricElevenPonetwofiveCostPercent = Format-Number $p125CostPct '0.0'
$macros.MetricElevenPonetwofiveBroadcastPercent = Format-Number $p125BroadcastPct '0.0'
$macros.MetricElevenPonetwofiveRmseMean = Format-Number $p125Rmse.mean '+0.00000;-0.00000'
$macros.MetricElevenPonetwofiveRmseLo = Format-Number $p125Rmse.lo '+0.00000;-0.00000'
$macros.MetricElevenPonetwofiveRmseHi = Format-Number $p125Rmse.hi '+0.00000;-0.00000'
$macros.MetricElevenPonetwofiveCostMean = Format-Number $p125Cost.mean '+0.00;-0.00'
$macros.MetricElevenPonetwofiveCostLo = Format-Number $p125Cost.lo '+0.00;-0.00'
$macros.MetricElevenPonetwofiveCostHi = Format-Number $p125Cost.hi '+0.00;-0.00'

$methodTags = [ordered]@{
    P5 = 'Pfive'; P10 = 'Pten'; 'P12.5' = 'Ponetwofive'; P20 = 'Ptwenty'
    P25 = 'Ptwentyfive'; StateEvent = 'Stateevent'; Causal = 'Causal'; OraclePeriodic = 'Oracle'
}
foreach ($method in $methodTags.Keys) {
    $tag = $methodTags[$method]
    $macros["MetricEleven${tag}Rmse"] = Format-Number $means[$method].rmse '0.00000'
    $macros["MetricEleven${tag}Cost"] = Format-Number $means[$method].w025 '0.00'
    $macros["MetricEleven${tag}Broadcast"] = Format-Number $means[$method].broadcast '0.00'
}

$metricsPath = Join-Path $generatedDir 'metrics.tex'
$metricsText = Get-Content -LiteralPath $metricsPath -Raw
$metricsText = [regex]::Replace($metricsText, '(?ms)\r?\n% BEGIN EXP11 SUPPLEMENTAL.*?% END EXP11 SUPPLEMENTAL\r?\n?', "`r`n")
$macroLines = @('% BEGIN EXP11 SUPPLEMENTAL - generated from frozen 50-seed tidy.csv')
foreach ($entry in $macros.GetEnumerator()) {
    if ($entry.Key -notmatch '^[A-Za-z]+$') { throw "Illegal LaTeX macro name: $($entry.Key)" }
    $macroLines += "\newcommand{\$($entry.Key)}{$($entry.Value)}"
}
$macroLines += '% END EXP11 SUPPLEMENTAL'
$metricsText = $metricsText.TrimEnd() + "`r`n`r`n" + ($macroLines -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText($metricsPath, $metricsText, $utf8NoBom)

$tableHypotheses = @'
\begin{tabular}{@{}llll@{}}
\toprule
Claim & Paired difference & 95\% CI & Verdict \\
\midrule
H1, Moderate$_1-$Clean$_1$ & \MetricElevenHoneOneMean{} Hz & [\MetricElevenHoneOneLo{}, \MetricElevenHoneOneHi{}] & \MetricElevenHoneVerdict{} \\
H1, Stressed$-$Moderate$_1$ & \MetricElevenHoneTwoMean{} Hz & [\MetricElevenHoneTwoLo{}, \MetricElevenHoneTwoHi{}] & \MetricElevenHoneVerdict{} \\
H1, Moderate$_2-$Stressed & \MetricElevenHoneThreeMean{} Hz & [\MetricElevenHoneThreeLo{}, \MetricElevenHoneThreeHi{}] & \MetricElevenHoneVerdict{} \\
H1, Clean$_2-$Moderate$_2$ & \MetricElevenHoneFourMean{} Hz & [\MetricElevenHoneFourLo{}, \MetricElevenHoneFourHi{}] & \MetricElevenHoneVerdict{} \\
H2a, RMSE(Causal$-$P10) & \MetricElevenHtwoaMean{} m & [\MetricElevenHtwoaLo{}, \MetricElevenHtwoaHi{}] & \MetricElevenHtwoaVerdict{} \\
H2b, $C_{0.25}$(Causal$-$P20) & \MetricElevenHtwobMean{} Hz & [\MetricElevenHtwobLo{}, \MetricElevenHtwobHi{}] & \MetricElevenHtwobVerdict{} \\
H3, periodic frontier & --- & --- & \MetricElevenHthreeVerdict{} \\
H4, oracle-information gap & --- & --- & \MetricElevenHfourVerdict{} \\
\bottomrule
\end{tabular}
'@
[System.IO.File]::WriteAllText((Join-Path $tablesDir 'tableVII_exp11_hypotheses.tex'), $tableHypotheses, $utf8NoBom)

$tableFrontier = @'
\begin{tabular}{@{}lrrr@{}}
\toprule
Method & RMSE [m] & $C_{0.25}$ [Hz] & broadcast [Hz] \\
\midrule
P5 & \MetricElevenPfiveRmse{} & \MetricElevenPfiveCost{} & \MetricElevenPfiveBroadcast{} \\
P10 & \MetricElevenPtenRmse{} & \MetricElevenPtenCost{} & \MetricElevenPtenBroadcast{} \\
\textbf{P12.5} & \textbf{\MetricElevenPonetwofiveRmse{}} & \textbf{\MetricElevenPonetwofiveCost{}} & \textbf{\MetricElevenPonetwofiveBroadcast{}} \\
P20 & \MetricElevenPtwentyRmse{} & \MetricElevenPtwentyCost{} & \MetricElevenPtwentyBroadcast{} \\
P25 & \MetricElevenPtwentyfiveRmse{} & \MetricElevenPtwentyfiveCost{} & \MetricElevenPtwentyfiveBroadcast{} \\
State-event & \MetricElevenStateeventRmse{} & \MetricElevenStateeventCost{} & \MetricElevenStateeventBroadcast{} \\
\textbf{Causal-v3} & \textbf{\MetricElevenCausalRmse{}} & \textbf{\MetricElevenCausalCost{}} & \textbf{\MetricElevenCausalBroadcast{}} \\
Oracle-periodic\textsuperscript{*} & \MetricElevenOracleRmse{} & \MetricElevenOracleCost{} & \MetricElevenOracleBroadcast{} \\
\bottomrule
\multicolumn{4}{@{}l}{\footnotesize \textsuperscript{*}Non-causal, regime-aware oracle-information reference.}
\end{tabular}
'@
[System.IO.File]::WriteAllText((Join-Path $tablesDir 'tableVIII_exp11_frontier.tex'), $tableFrontier, $utf8NoBom)

Copy-Item -LiteralPath (Join-Path $runDir 'figures\fig01_EXP11SegmentDATARate.png') -Destination (Join-Path $figuresDir 'fig12_exp11_adaptivity.png') -Force
Copy-Item -LiteralPath (Join-Path $runDir 'figures\fig03_EXP11Pareto.png') -Destination (Join-Path $figuresDir 'fig13_exp11_frontier.png') -Force

$tidyHash = (Get-FileHash -LiteralPath $tidyPath -Algorithm SHA256).Hash.ToLowerInvariant()
$verification = [ordered]@{
    source = "$runRel/tidy.csv"
    sha256 = $tidyHash
    rows = $rows.Count
    seeds = $seeds.Count
    methods = $methods
    verdicts = [ordered]@{ H1 = 'SUPPORTED'; H2a = 'SUPPORTED'; H2b = 'SUPPORTED at w=0.25 only'; H3 = 'CHARACTERIZATION'; H4 = 'CHARACTERIZATION' }
    generator = 'paper/scripts/rebuild_exp11_artifacts.ps1'
}
[System.IO.File]::WriteAllText(
    (Join-Path $generatedDir 'exp11_verification.json'),
    (($verification | ConvertTo-Json -Depth 5) + "`n"),
    $utf8NoBom)

Write-Output "EXP11_ARTIFACTS_OK source=$runRel/tidy.csv rows=$($rows.Count) seeds=$($seeds.Count)"
Write-Output "H1=$($h1Supported) H2a=$($h2aSupported) H2b=$($h2bSupported)"
Write-Output "P12.5 accuracy=$([Math]::Round($p125AccuracyPct,1))% cost=$([Math]::Round($p125CostPct,1))% broadcast=$([Math]::Round($p125BroadcastPct,1))%"
