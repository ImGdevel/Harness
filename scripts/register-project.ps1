param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [string]$RepoUrl,
    [string]$DefaultBranch,
    [string]$DocsPath = "docs",
    [string]$PlanPath = "plan",
    [string]$TroubleshootingPath = "troubleshooting",
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

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$registryPath = Join-Path $workspaceRoot "project\registry.yaml"

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

$normalizedStacks = @(
    $Stacks |
        Where-Object { $_ -and $_.Trim() -ne "" } |
        ForEach-Object { $_.Trim() } |
        Select-Object -Unique
)

$normalizedAliases = @(
    @($Aliases + $ProjectId + $DisplayName) |
        Where-Object { $_ -and $_.Trim() -ne "" } |
        ForEach-Object { $_.Trim() } |
        Select-Object -Unique
)

$lines = @()
$lines += "  # BEGIN project:$ProjectId"
$lines += "  - id: $ProjectId"
$lines += "    name: $DisplayName"
$lines += "    repo_path: $(Quote-Yaml $resolvedRepoPath)"
$lines += "    repo_url: $(Quote-Yaml $RepoUrl)"
$lines += "    default_branch: $DefaultBranch"
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

$content = Get-Content -LiteralPath $registryPath -Raw
$pattern = "(?ms)^  # BEGIN project:$([regex]::Escape($ProjectId))\r?\n.*?^  # END project:$([regex]::Escape($ProjectId))\r?\n?"

if ($content -match $pattern) {
    $updated = [regex]::Replace($content, $pattern, $entryBlock)
} else {
    $updated = $content -replace "(?ms)^projects:\r?\n", "projects:`r`n$entryBlock"
}

Set-Content -LiteralPath $registryPath -Value $updated -Encoding utf8

Write-Output "Registered project id: $ProjectId"
Write-Output "Repo path: $resolvedRepoPath"
Write-Output "Registry: $registryPath"
Write-Output "Update project/index.md in the same change if the human summary needs refresh."
