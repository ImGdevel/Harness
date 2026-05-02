param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [string]$RepoUrl,
    [string]$DefaultBranch,
    [string]$ProductionBranch,
    [string]$DocsPath = "docs",
    [string]$PlanPath = "docs/plan",
    [string]$TroubleshootingPath = "docs/troubleshooting",
    [string[]]$Stacks = @(),
    [string[]]$Aliases = @(),
    [ValidateSet("active", "paused", "archived")]
    [string]$Status = "active"
)

function Quote-Yaml {
    param([string]$Value)

    if ($null -eq $Value) {
        return "''"
    }

    $escaped = $Value -replace "'", "''"
    return "'$escaped'"
}

function Expand-NormalizedList {
    param([string[]]$Values)

    return @(
        $Values |
            Where-Object { $_ -and $_.Trim() -ne "" } |
            ForEach-Object { $_ -split ',' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne "" } |
            Select-Object -Unique
    )
}

function Ensure-ProjectIndex {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return
    }

    $content = @"
# Project Registry Index

이 디렉터리는 하네스가 참조하는 외부 프로젝트 레지스트리를 관리한다.

## Authoritative Source

- 단일 진실 원천은 `registry.yaml`이다.
- 이 문서는 사람이 빠르게 찾기 위한 요약 인덱스다.
- 실제 프로젝트 코드와 문서는 하네스 내부가 아니라 registry가 가리키는 외부 저장소에 있다.

## Rule

- 하네스 내부 `project/`에는 메타데이터만 둔다.
- 실제 프로젝트 저장소를 이 디렉터리 아래에 clone하거나 이동하지 않는다.
- 프로젝트 작업을 시작할 때는 먼저 `registry.yaml`에서 `repo_path`를 확인한다.
- 프로젝트 전용 문서는 실제 저장소의 `<project-root>/docs/`에 둔다.
- 계획 문서는 기본적으로 `<project-root>/docs/plan/`에 둔다.
- 트러블슈팅 문서는 기본적으로 `<project-root>/docs/troubleshooting/`에 둔다.

## Registered Projects

| id | name | path | default branch | stacks | status |
| --- | --- | --- | --- | --- | --- |
"@

    Set-Content -LiteralPath $Path -Value $content -Encoding utf8
}

function Update-ProjectIndex {
    param(
        [string]$IndexPath,
        [string]$ProjectId,
        [string]$DisplayName,
        [string]$RepoPath,
        [string]$DefaultBranch,
        [string[]]$Stacks,
        [string]$Status
    )

    Ensure-ProjectIndex -Path $IndexPath

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in (Get-Content -LiteralPath $IndexPath -Encoding utf8)) {
        $lines.Add($line)
    }

    $sectionIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "## Registered Projects") {
            $sectionIndex = $i
            break
        }
    }

    if ($sectionIndex -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1].Trim() -ne "") {
            $lines.Add("")
        }
        $lines.Add("## Registered Projects")
        $lines.Add("")
        $lines.Add("| id | name | path | default branch | stacks | status |")
        $lines.Add("| --- | --- | --- | --- | --- | --- |")
        $sectionIndex = $lines.Count - 4
    }

    $headerIndex = -1
    $separatorIndex = -1
    for ($i = $sectionIndex + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "| id | name | path | default branch | stacks | status |") {
            $headerIndex = $i
            if (($i + 1) -lt $lines.Count -and $lines[$i + 1] -eq "| --- | --- | --- | --- | --- | --- |") {
                $separatorIndex = $i + 1
            }
            break
        }
        if ($lines[$i] -match '^## ') {
            break
        }
    }

    if ($headerIndex -lt 0 -or $separatorIndex -lt 0) {
        $insertAt = $sectionIndex + 1
        if ($insertAt -lt $lines.Count -and $lines[$insertAt].Trim() -ne "") {
            $lines.Insert($insertAt, "")
            $insertAt++
        }
        $lines.Insert($insertAt, "| id | name | path | default branch | stacks | status |")
        $lines.Insert($insertAt + 1, "| --- | --- | --- | --- | --- | --- |")
        $headerIndex = $insertAt
        $separatorIndex = $insertAt + 1
    }

    $code = [char]96
    $stackSummary = if ($Stacks.Count -eq 0) {
        "{0}unknown{0}" -f $code
    } else {
        ($Stacks | ForEach-Object { "{0}{1}{0}" -f $code, $_ }) -join ", "
    }

    $row = "| {0}{1}{0} | {0}{2}{0} | {0}{3}{0} | {0}{4}{0} | {5} | {0}{6}{0} |" -f $code, $ProjectId, $DisplayName, $RepoPath, $DefaultBranch, $stackSummary, $Status
    $rowPattern = '^\|\s*' + [regex]::Escape([string]$code) + [regex]::Escape($ProjectId) + [regex]::Escape([string]$code) + '\s*\|'

    $nextHeadingIndex = $lines.Count
    for ($i = $separatorIndex + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## ') {
            $nextHeadingIndex = $i
            break
        }
    }

    $existingRowIndex = -1
    for ($i = $separatorIndex + 1; $i -lt $nextHeadingIndex; $i++) {
        if ($lines[$i] -match $rowPattern) {
            $existingRowIndex = $i
            break
        }
    }

    if ($existingRowIndex -ge 0) {
        $lines[$existingRowIndex] = $row
    } else {
        $lines.Insert($nextHeadingIndex, $row)
    }

    Set-Content -LiteralPath $IndexPath -Value $lines -Encoding utf8
}

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$registryPath = Join-Path $workspaceRoot "project\registry.yaml"
$projectIndexPath = Join-Path $workspaceRoot "project\index.md"

try {
    $resolvedRepoPath = (Resolve-Path -LiteralPath $RepoPath).Path
} catch {
    throw "Repository path not found: $RepoPath"
}

if (-not (Test-Path -LiteralPath (Join-Path $resolvedRepoPath ".git"))) {
    throw "Repository path is not a Git repository: $resolvedRepoPath"
}

if (-not $RepoUrl) {
    try {
        $RepoUrl = (git -C $resolvedRepoPath remote get-url origin).Trim()
    } catch {
        $RepoUrl = ""
    }
}

if (-not $DefaultBranch) {
    try {
        $DefaultBranch = (git -C $resolvedRepoPath branch --show-current).Trim()
    } catch {
        $DefaultBranch = "main"
    }
}

$normalizedStacks = Expand-NormalizedList -Values $Stacks
$normalizedAliases = Expand-NormalizedList -Values @($Aliases + $ProjectId + $DisplayName)

$lines = @()
$lines += "  # BEGIN project:$ProjectId"
$lines += "  - id: $ProjectId"
$lines += "    name: $DisplayName"
$lines += "    repo_path: $(Quote-Yaml $resolvedRepoPath)"
$lines += "    repo_url: $(Quote-Yaml $RepoUrl)"
$lines += "    default_branch: $DefaultBranch"
if ($ProductionBranch) {
    $lines += "    production_branch: $ProductionBranch"
}
$lines += "    docs_path: $DocsPath"
$lines += "    plan_path: $PlanPath"
$lines += "    troubleshooting_path: $TroubleshootingPath"
$lines += "    status: $Status"
$lines += "    stacks:"

if ($normalizedStacks.Count -eq 0) {
    $lines += "      - unknown"
} else {
    foreach ($stack in $normalizedStacks) {
        $lines += "      - $stack"
    }
}

$lines += "    aliases:"
foreach ($alias in $normalizedAliases) {
    $lines += "      - $alias"
}
$lines += "  # END project:$ProjectId"

$entryBlock = ($lines -join "`r`n") + "`r`n"

if (-not (Test-Path -LiteralPath $registryPath)) {
    $header = "version: 1`r`nprojects:`r`n"
    Set-Content -LiteralPath $registryPath -Value $header -Encoding utf8
}

$content = Get-Content -LiteralPath $registryPath -Raw -Encoding utf8
$pattern = "(?ms)^  # BEGIN project:$([regex]::Escape($ProjectId))\r?\n.*?^  # END project:$([regex]::Escape($ProjectId))\r?\n?"

if ($content -match $pattern) {
    $updated = [regex]::Replace($content, $pattern, $entryBlock)
} else {
    $updated = $content -replace "(?ms)^projects:\r?\n", "projects:`r`n$entryBlock"
}

Set-Content -LiteralPath $registryPath -Value $updated -Encoding utf8

Update-ProjectIndex `
    -IndexPath $projectIndexPath `
    -ProjectId $ProjectId `
    -DisplayName $DisplayName `
    -RepoPath $resolvedRepoPath `
    -DefaultBranch $DefaultBranch `
    -Stacks $normalizedStacks `
    -Status $Status

Write-Output "Registered project id: $ProjectId"
Write-Output "Repo path: $resolvedRepoPath"
Write-Output "Registry: $registryPath"
Write-Output "Project index: $projectIndexPath"
