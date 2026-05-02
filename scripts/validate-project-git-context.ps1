param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot),

    [switch]$SkipFetch,

    [switch]$AllowStackedBranch,

    [switch]$FailOnIssue
)

function Add-Issue {
    param(
        [System.Collections.Generic.List[object]]$Issues,
        [string]$Type,
        [string]$Message
    )

    $Issues.Add([pscustomobject]@{
            Type    = $Type
            Message = $Message
        }) | Out-Null
}

function Normalize-YamlScalar {
    param([string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $normalized = $Value.Trim()
    if ($normalized.Length -ge 2 -and $normalized.StartsWith("'") -and $normalized.EndsWith("'")) {
        $normalized = $normalized.Substring(1, $normalized.Length - 2).Replace("''", "'")
    }

    return $normalized.Trim()
}

function Get-RegistryProject {
    param(
        [string]$RegistryPath,
        [string]$TargetProjectId
    )

    if (-not (Test-Path -LiteralPath $RegistryPath)) {
        throw "Registry file not found: $RegistryPath"
    }

    $current = $null

    foreach ($line in (Get-Content -LiteralPath $RegistryPath -Encoding utf8)) {
        if ($line -match '^  # BEGIN project:(.+)$') {
            $current = [ordered]@{
                MarkerId            = $Matches[1].Trim()
                Id                  = ""
                Name                = ""
                RepoPath            = ""
                DefaultBranch       = "main"
                IntegrationBranch   = "develop"
                BranchStrategy      = "gitflow"
                DocsSource          = "repo"
                WikiPath            = ""
            }
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($line -match '^  # END project:(.+)$') {
            if ($current.Id -eq $TargetProjectId) {
                return [pscustomobject]@{
                    Id                = $current.Id
                    Name              = $current.Name
                    RepoPath          = $current.RepoPath
                    DefaultBranch     = $current.DefaultBranch
                    IntegrationBranch = $current.IntegrationBranch
                    BranchStrategy    = $current.BranchStrategy
                    DocsSource        = $current.DocsSource
                    WikiPath          = $current.WikiPath
                }
            }

            $current = $null
            continue
        }

        if ($line -match '^\s{2}-\s+id:\s*(.*)$') {
            $current.Id = Normalize-YamlScalar -Value $Matches[1]
            continue
        }

        if ($line -match '^\s{4}([a-z_]+):\s*(.*)$') {
            $field = $Matches[1]
            $value = Normalize-YamlScalar -Value $Matches[2]

            switch ($field) {
                "name" { $current.Name = $value }
                "repo_path" { $current.RepoPath = $value }
                "default_branch" { if ($value) { $current.DefaultBranch = $value } }
                "integration_branch" { if ($value) { $current.IntegrationBranch = $value } }
                "branch_strategy" { if ($value) { $current.BranchStrategy = $value } }
                "docs_source" { if ($value) { $current.DocsSource = $value } }
                "wiki_path" { if ($value) { $current.WikiPath = $value } }
            }
        }
    }

    throw "Project id not found in registry: $TargetProjectId"
}

function Invoke-Git {
    param(
        [string]$RepoPath,
        [string[]]$GitArgs,
        [switch]$AllowFailure
    )

    $output = & git -C $RepoPath @GitArgs 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw (($output | Out-String).Trim())
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = ($output | Out-String).Trim()
    }
}

function Test-RemoteBranch {
    param(
        [string]$RepoPath,
        [string]$BranchName
    )

    $result = Invoke-Git -RepoPath $RepoPath -GitArgs @("show-ref", "--verify", "--quiet", "refs/remotes/origin/$BranchName") -AllowFailure
    return $result.ExitCode -eq 0
}

function Test-IsAncestor {
    param(
        [string]$RepoPath,
        [string]$Ancestor,
        [string]$Descendant
    )

    $result = Invoke-Git -RepoPath $RepoPath -GitArgs @("merge-base", "--is-ancestor", $Ancestor, $Descendant) -AllowFailure
    return $result.ExitCode -eq 0
}

$issues = [System.Collections.Generic.List[object]]::new()
$registryPath = Join-Path $WorkspaceRoot "project\registry.yaml"
$project = Get-RegistryProject -RegistryPath $registryPath -TargetProjectId $ProjectId

if (-not $project.RepoPath -or -not (Test-Path -LiteralPath $project.RepoPath)) {
    Add-Issue -Issues $issues -Type "missing-repo-path" -Message "Repository path does not exist: $($project.RepoPath)"
} elseif (-not (Test-Path -LiteralPath (Join-Path $project.RepoPath ".git"))) {
    Add-Issue -Issues $issues -Type "not-git-repo" -Message "Repository path is not a Git repository: $($project.RepoPath)"
}

if ($issues.Count -eq 0 -and -not $SkipFetch) {
    $fetchResult = Invoke-Git -RepoPath $project.RepoPath -GitArgs @("fetch", "--prune", "origin") -AllowFailure
    if ($fetchResult.ExitCode -ne 0) {
        Add-Issue -Issues $issues -Type "fetch-failed" -Message $fetchResult.Output
    }
}

if ($issues.Count -eq 0) {
    $currentBranch = (Invoke-Git -RepoPath $project.RepoPath -GitArgs @("branch", "--show-current")).Output
    $branchStrategy = $project.BranchStrategy.ToLowerInvariant()
    $defaultBranch = $project.DefaultBranch
    $integrationBranch = $project.IntegrationBranch

    if (-not (Test-RemoteBranch -RepoPath $project.RepoPath -BranchName $defaultBranch)) {
        Add-Issue -Issues $issues -Type "missing-remote-default-branch" -Message "origin/$defaultBranch does not exist."
    }

    if ($branchStrategy -eq "gitflow" -and -not (Test-RemoteBranch -RepoPath $project.RepoPath -BranchName $integrationBranch)) {
        Add-Issue -Issues $issues -Type "missing-remote-integration-branch" -Message "origin/$integrationBranch does not exist."
    }

    $remoteShow = Invoke-Git -RepoPath $project.RepoPath -GitArgs @("remote", "show", "origin") -AllowFailure
    if ($remoteShow.ExitCode -eq 0 -and $remoteShow.Output -match 'HEAD branch:\s*(.+)') {
        $remoteHead = $Matches[1].Trim()
        if ($remoteHead -ne $defaultBranch) {
            Add-Issue -Issues $issues -Type "remote-head-mismatch" -Message "origin HEAD points to '$remoteHead', expected '$defaultBranch'."
        }
    } else {
        Add-Issue -Issues $issues -Type "remote-head-unknown" -Message "Could not resolve origin HEAD branch."
    }

    if (-not $currentBranch) {
        Add-Issue -Issues $issues -Type "detached-head" -Message "Current branch is empty or detached."
    } elseif (@($defaultBranch, $integrationBranch, "master") -contains $currentBranch) {
        Add-Issue -Issues $issues -Type "protected-branch" -Message "Do not work directly on protected branch '$currentBranch'."
    } elseif ($currentBranch -notmatch '^(feat|refactor|hotfix)/[a-z0-9]+(-[a-z0-9]+)*$') {
        Add-Issue -Issues $issues -Type "invalid-branch-name" -Message "Current branch '$currentBranch' must match feat|refactor|hotfix lowercase-kebab format."
    } else {
        $branchType = ($currentBranch -split '/', 2)[0]
        $expectedBase = if ($branchType -eq "hotfix") {
            $defaultBranch
        } elseif ($branchStrategy -eq "gitflow") {
            $integrationBranch
        } else {
            $defaultBranch
        }

        if (Test-RemoteBranch -RepoPath $project.RepoPath -BranchName $expectedBase) {
            if (-not (Test-IsAncestor -RepoPath $project.RepoPath -Ancestor "origin/$expectedBase" -Descendant "HEAD")) {
                Add-Issue -Issues $issues -Type "base-not-ancestor" -Message "origin/$expectedBase is not an ancestor of '$currentBranch'."
            }

            if (-not $AllowStackedBranch) {
                $remoteWorkBranches = (Invoke-Git -RepoPath $project.RepoPath -GitArgs @(
                        "for-each-ref",
                        "--format=%(refname:short)",
                        "refs/remotes/origin/feat",
                        "refs/remotes/origin/refactor",
                        "refs/remotes/origin/hotfix"
                    ) -AllowFailure).Output -split "\r?\n" | Where-Object { $_ }

                foreach ($remoteWorkBranch in $remoteWorkBranches) {
                    $shortRemoteBranch = $remoteWorkBranch -replace '^origin/', ''
                    if ($shortRemoteBranch -eq $currentBranch) {
                        continue
                    }

                    $isRemoteWorkBranchInHead = Test-IsAncestor -RepoPath $project.RepoPath -Ancestor $remoteWorkBranch -Descendant "HEAD"
                    $isRemoteWorkBranchIntegrated = Test-IsAncestor -RepoPath $project.RepoPath -Ancestor $remoteWorkBranch -Descendant "origin/$expectedBase"

                    if ($isRemoteWorkBranchInHead -and -not $isRemoteWorkBranchIntegrated) {
                        Add-Issue -Issues $issues -Type "stacked-work-branch" -Message "Current branch contains unintegrated work branch '$remoteWorkBranch'."
                    }
                }
            }
        }
    }

    if ($project.DocsSource -eq "wiki") {
        if (-not $project.WikiPath) {
            Add-Issue -Issues $issues -Type "missing-wiki-path" -Message "docs_source is wiki but wiki_path is empty."
        } elseif (-not (Test-Path -LiteralPath (Join-Path $project.WikiPath ".git"))) {
            Add-Issue -Issues $issues -Type "missing-wiki-repo" -Message "wiki_path is not a Git repository: $($project.WikiPath)"
        } elseif (-not (Test-Path -LiteralPath (Join-Path $project.WikiPath "Home.md"))) {
            Add-Issue -Issues $issues -Type "missing-wiki-home" -Message "Wiki Home.md does not exist: $($project.WikiPath)"
        }
    }
}

Write-Output "project: $($project.Id)"
Write-Output "repo: $($project.RepoPath)"
Write-Output "branch_strategy: $($project.BranchStrategy)"
Write-Output "default_branch: $($project.DefaultBranch)"
Write-Output "integration_branch: $($project.IntegrationBranch)"
Write-Output "docs_source: $($project.DocsSource)"

if ($issues.Count -eq 0) {
    Write-Output "OK: project git context is valid."
    exit 0
}

Write-Output ("Found {0} project git context issue(s)." -f $issues.Count)
$issues |
    Sort-Object Type, Message |
    Format-Table -AutoSize |
    Out-String |
    Write-Output

if ($FailOnIssue) {
    exit 1
}

