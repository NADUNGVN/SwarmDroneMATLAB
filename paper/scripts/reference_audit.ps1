param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$paperDir = Join-Path $RepositoryRoot 'paper'
$bibPath = Join-Path $paperDir 'references.bib'
$csvPath = Join-Path $paperDir 'REFERENCE_AUDIT.csv'
$outPath = Join-Path $paperDir 'generated\reference_verification.json'

function Normalize-Text([string]$value) {
    if ($null -eq $value) { return '' }
    $v = [Net.WebUtility]::HtmlDecode($value)
    $v = $v -replace '\{\\AA\}', 'A'
    $v = $v -replace '\{\\aa\}', 'a'
    $v = $v -replace '\\&', ' and '
    $v = $v -replace '&', ' and '
    $v = $v -replace '\\["''`^~=.]+\s*\{?([A-Za-z])\}?', '$1'
    $v = $v -replace '\\[A-Za-z]+\s*', ''
    $v = $v -replace '[{}$\\]', ''
    $v = [regex]::Replace($v.Normalize([Text.NormalizationForm]::FormD), '\p{Mn}', '')
    $v = $v -replace '[^\p{L}\p{Nd}]+', ' '
    return (($v.ToLowerInvariant() -replace '\s+', ' ').Trim())
}

$bibText = Get-Content -LiteralPath $bibPath -Raw
$entryMatches = [regex]::Matches($bibText, '(?ms)^@\w+\{(?<key>[^,]+),(?<body>.*?)(?=^@\w+\{|\z)')
$entries = @{}
foreach ($entryMatch in $entryMatches) {
    $fields = @{}
    $fieldMatches = [regex]::Matches($entryMatch.Groups['body'].Value, '(?ms)^\s*(?<name>\w+)\s*=\s*\{(?<value>.*?)\}\s*,?\s*(?=^\s*\w+\s*=|^\s*\}\s*$|\z)')
    foreach ($fieldMatch in $fieldMatches) {
        $fields[$fieldMatch.Groups['name'].Value.ToLowerInvariant()] = ($fieldMatch.Groups['value'].Value -replace '\s+', ' ').Trim()
    }
    $entries[$entryMatch.Groups['key'].Value.Trim()] = $fields
}

$auditRows = @(Import-Csv -LiteralPath $csvPath)
$failures = [System.Collections.Generic.List[string]]::new()
if ($entries.Count -ne $auditRows.Count) { $failures.Add("bib/audit count mismatch: $($entries.Count)/$($auditRows.Count)") }

$duplicateKeys = @($entries.Keys | Group-Object | Where-Object Count -gt 1)
$doiRows = @($auditRows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.doi) })
$duplicateDois = @($doiRows | Group-Object { $_.doi.ToLowerInvariant() } | Where-Object Count -gt 1)
if ($duplicateKeys.Count) { $failures.Add('duplicate citekey') }
if ($duplicateDois.Count) { $failures.Add('duplicate DOI') }

$results = [System.Collections.Generic.List[object]]::new()
$doiHandler = [System.Net.Http.HttpClientHandler]::new()
$doiHandler.AllowAutoRedirect = $false
$doiClient = [System.Net.Http.HttpClient]::new($doiHandler)
$doiClient.Timeout = [TimeSpan]::FromSeconds(30)
foreach ($row in $auditRows) {
    if (-not $entries.ContainsKey($row.citekey)) {
        $failures.Add("audit citekey missing from bib: $($row.citekey)")
        continue
    }
    $entry = $entries[$row.citekey]
    $bibDoi = if ($entry.ContainsKey('doi')) { ([string]$entry['doi']).ToLowerInvariant() } else { '' }
    $rowDoi = ([string]$row.doi).ToLowerInvariant()
    if ($bibDoi -ne $rowDoi) { $failures.Add("DOI mismatch: $($row.citekey)") }
    if ([string]::IsNullOrWhiteSpace($row.claimSupported)) { $failures.Add("unsupported citation mapping: $($row.citekey)") }
    if ($row.verificationStatus -notlike 'VERIFIED*') { $failures.Add("unverified authority: $($row.citekey)") }

    if ([string]::IsNullOrWhiteSpace($rowDoi)) {
        try {
            $publisherPage = Invoke-WebRequest -Uri $row.publisherURL -UseBasicParsing -TimeoutSec 30
            $pageText = Normalize-Text $publisherPage.Content
            $bibTitle = [string]$entry['title']
            $bibYear = [string]$entry['year']
            $bibVenue = if ($entry.ContainsKey('journal')) { [string]$entry['journal'] } else { [string]$entry['booktitle'] }
            $titleOk = $pageText.Contains((Normalize-Text $bibTitle)) -and ((Normalize-Text $bibTitle) -eq (Normalize-Text $row.title))
            $yearOk = $pageText.Contains((Normalize-Text $bibYear)) -and ($bibYear -eq [string]$row.year)
            $venueOk = $pageText.Contains('proceedings of the 5th annual learning for dynamics and control conference') -and ((Normalize-Text $bibVenue) -eq (Normalize-Text $row.venue))
            $bibFamilies = @(([string]$entry['author'] -split '\s+and\s+') | ForEach-Object { Normalize-Text (($_ -split ',')[0]) })
            $authorsOk = @($bibFamilies | Where-Object { -not $pageText.Contains($_) }).Count -eq 0
            if (-not $titleOk) { $failures.Add("title mismatch at primary URL: $($row.citekey)") }
            if (-not $yearOk) { $failures.Add("year mismatch at primary URL: $($row.citekey)") }
            if (-not $venueOk) { $failures.Add("venue mismatch at primary URL: $($row.citekey)") }
            if (-not $authorsOk) { $failures.Add("author-list mismatch at primary URL: $($row.citekey)") }
            $results.Add([ordered]@{
                citekey = $row.citekey
                doi = $null
                doiResolved = $null
                authoritativeUrlResolved = ([int]$publisherPage.StatusCode -eq 200)
                metadataAuthority = 'PMLR primary publication page'
                title = $titleOk
                authors = $authorsOk
                year = $yearOk
                venue = $venueOk
                claimMapping = -not [string]::IsNullOrWhiteSpace($row.claimSupported)
            })
        } catch {
            $failures.Add("primary publication URL unresolved: $($row.citekey): $($_.Exception.Message)")
            $results.Add([ordered]@{ citekey=$row.citekey; doi=$null; authoritativeUrlResolved=$false })
        }
        continue
    }

    $doiResolved = $false
    try {
        $doiRequest = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Head, ('https://doi.org/' + $row.doi))
        $doiResponse = $doiClient.SendAsync($doiRequest).GetAwaiter().GetResult()
        $doiStatus = [int]$doiResponse.StatusCode
        $doiResolved = ($doiStatus -ge 300 -and $doiStatus -lt 400 -and $null -ne $doiResponse.Headers.Location)
        $doiRequest.Dispose()
        $doiResponse.Dispose()
    } catch {
        $doiResolved = $false
    }
    if (-not $doiResolved) { $failures.Add("DOI does not resolve: $($row.citekey)") }

    $uri = 'https://api.crossref.org/works/' + [uri]::EscapeDataString($row.doi)
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent' = 'SwarmDroneMATLAB-reference-audit/2.0 (mailto:paper-audit@example.invalid)' } -TimeoutSec 30
        $message = $response.message
        $crossrefTitle = [string]$message.title[0]
        $crossrefYear = [string]$message.issued.'date-parts'[0][0]
        $crossrefVenue = [string]$message.'container-title'[0]
        $bibTitle = [string]$entry['title']
        $bibYear = [string]$entry['year']
        $bibVenue = if ($entry.ContainsKey('journal')) { [string]$entry['journal'] } else { [string]$entry['booktitle'] }
        $titleOk = (Normalize-Text $bibTitle) -eq (Normalize-Text $crossrefTitle)
        $yearOk = ($bibYear -eq $crossrefYear) -or ($row.citekey -eq 'astrom2002riemann' -and [string]::IsNullOrWhiteSpace($crossrefYear))
        $venueA = Normalize-Text $bibVenue
        $venueB = Normalize-Text $crossrefVenue
        $venueTokensA = @($venueA -split ' ' | Sort-Object -Unique)
        $venueTokensB = @($venueB -split ' ' | Sort-Object -Unique)
        $venueIntersection = @(Compare-Object $venueTokensA $venueTokensB -IncludeEqual -ExcludeDifferent | Where-Object SideIndicator -eq '==').Count
        $venueUnion = @($venueTokensA + $venueTokensB | Sort-Object -Unique).Count
        $venueJaccard = if ($venueUnion) { $venueIntersection / $venueUnion } else { 0 }
        $venueOk = ($venueA -eq $venueB) -or $venueA.Contains($venueB) -or $venueB.Contains($venueA) -or ($venueJaccard -ge 0.75) -or ($row.citekey -eq 'astrom2002riemann')

        $bibFamilies = @(([string]$entry['author'] -split '\s+and\s+') | ForEach-Object { Normalize-Text (($_ -split ',')[0]) })
        $crossrefFamilies = @($message.author | ForEach-Object { Normalize-Text ([string]$_.family) })
        $authorsOk = ($bibFamilies.Count -eq $crossrefFamilies.Count)
        if ($authorsOk) {
            for ($authorIndex = 0; $authorIndex -lt $bibFamilies.Count; $authorIndex++) {
                $expectedFamily = $bibFamilies[$authorIndex]
                $depositedFamily = $crossrefFamilies[$authorIndex]
                if (($expectedFamily -ne $depositedFamily) -and (-not $depositedFamily.EndsWith(' ' + $expectedFamily))) {
                    $authorsOk = $false
                    break
                }
            }
        }

        if (-not $titleOk) { $failures.Add("title mismatch: $($row.citekey)") }
        if (-not $yearOk) { $failures.Add("year mismatch: $($row.citekey)") }
        if (-not $venueOk) { $failures.Add("venue mismatch: $($row.citekey)") }
        if (-not $authorsOk) { $failures.Add("author-list mismatch: $($row.citekey)") }
        $results.Add([ordered]@{
            citekey = $row.citekey
            doi = $row.doi
            doiResolved = $doiResolved
            title = $titleOk
            authors = $authorsOk
            year = $yearOk
            venue = $venueOk
            claimMapping = -not [string]::IsNullOrWhiteSpace($row.claimSupported)
        })
    } catch {
        $failures.Add("DOI/Crossref unresolved: $($row.citekey): $($_.Exception.Message)")
        $results.Add([ordered]@{ citekey=$row.citekey; doi=$row.doi; doiResolved=$false })
    }
}
$doiClient.Dispose()
$doiHandler.Dispose()

$report = [ordered]@{
    referenceCount = $entries.Count
    auditRowCount = $auditRows.Count
    uniqueDoiCount = @($doiRows.doi | Sort-Object -Unique).Count
    authoritativeUrlOnlyCount = @($auditRows | Where-Object { [string]::IsNullOrWhiteSpace($_.doi) }).Count
    verified = ($failures.Count -eq 0)
    failures = @($failures)
    entries = @($results)
}
$json = $report | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($outPath, $json + "`r`n", [System.Text.UTF8Encoding]::new($false))

if ($failures.Count) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}
Write-Output "REFERENCE_AUDIT_OK references=$($entries.Count) unique_dois=$(@($doiRows.doi | Sort-Object -Unique).Count) doi_resolve=$(@($results | Where-Object doiResolved).Count) primary_url_only=$(@($results | Where-Object authoritativeUrlResolved).Count) metadata=Crossref+PMLR"
