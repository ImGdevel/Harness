param(
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$FailOnIssue
)

function Add-Issue {
    param(
        [System.Collections.Generic.List[object]]$Issues,
        [string]$Type,
        [string]$Path,
        [string]$Message
    )

    $Issues.Add([pscustomobject]@{
            Type    = $Type
            Path    = $Path
            Message = $Message
        })
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

function Normalize-MarkdownCodeScalar {
    param([string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $code = [string][char]96
    $normalized = $Value.Trim()
    if ($normalized.Length -ge 2 -and $normalized.StartsWith($code) -and $normalized.EndsWith($code)) {
        $normalized = $normalized.Substring(1, $normalized.Length - 2)
    }

    return $normalized.Trim()
}

function Normalize-List {
    param([string[]]$Values)

    return @(
        $Values |
            Where-Object { $_ -and $_.Trim() -ne "" } |
            ForEach-Object { $_.Trim() } |
            Sort-Object -Unique
    )
}

function Get-ListFingerprint {
    param([string[]]$Values)

    return (Normalize-List -Values $Values) -join ","
}

function Get-RegistryProjects {
    param(
        [string]$RegistryPath,
        [System.Collections.Generic.List[object]]$Issues
    )

    if (-not (Test-Path -LiteralPath $RegistryPath)) {
        Add-Issue -Issues $Issues -Type "missing-registry" -Path "project\\registry.yaml" -Message "Registry file does not exist."
        return @()
    }

    $projects = [System.Collections.Generic.List[object]]::new()
    $current = $null
    $currentList = $null

    foreach ($line in (Get-Content -LiteralPath $RegistryPath -Encoding utf8)) {
        if ($line -match '^  # BEGIN project:(.+)$') {
            if ($null -ne $current) {
                Add-Issue -Issues $Issues -Type "unterminated-project-block" -Path "project\\registry.yaml" -Message ("Project block '{0}' is missing an END marker." -f $current.MarkerId)
            }

            $markerId = $Matches[1].Trim()
            $current = [ordered]@{
                MarkerId             = $markerId
                Id                   = ""
                Name                 = ""
                RepoPath             = ""
                RepoUrl              = ""
                DefaultBranch        = ""
                DocsPath             = ""
                PlanPath             = ""
                TroubleshootingPath  = ""
                Status               = ""
                Stacks               = [System.Collections.Generic.List[string]]::new()
                Aliases              = [System.Collections.Generic.List[string]]::new()
            }
            $currentList = $null
            continue
        }

        if ($line -match '^  # END project:(.+)$') {
            $endId = $Matches[1].Trim()

            if ($null -eq $current) {
                Add-Issue -Issues $Issues -Type "orphan-end-marker" -Path "project\\registry.yaml" -Message ("END marker '{0}' does not have a matching BEGIN marker." -f $endId)
                continue
            }

            if ($current.MarkerId -ne $endId) {
                Add-Issue -Issues $Issues -Type "project-marker-mismatch" -Path "project\\registry.yaml" -Message ("Project block begin/end markers do not match: BEGIN '{0}', END '{1}'." -f $current.MarkerId, $endId)
            }

            $projects.Add([pscustomobject]@{
                    MarkerId            = $current.MarkerId
                    Id                  = $current.Id
                    Name                = $current.Name
                    RepoPath            = $current.RepoPath
                    RepoUrl             = $current.RepoUrl
                    DefaultBranch       = $current.DefaultBranch
                    DocsPath            = $current.DocsPath
                    PlanPath            = $current.PlanPath
                    TroubleshootingPath = $current.TroubleshootingPath
                    Status              = $current.Status
                    Stacks              = @($current.Stacks)
                    Aliases             = @($current.Aliases)
                })

            $current = $null
            $currentList = $null
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($line -match '^\s{2}-\s+id:\s*(.*)$') {
            $current.Id = Normalize-YamlScalar -Value $Matches[1]
            $currentList = $null
            continue
        }

        if ($line -match '^\s{4}([a-z_]+):\s*(.*)$') {
            $field = $Matches[1]
            $value = Normalize-YamlScalar -Value $Matches[2]
            $currentList = $null

            switch ($field) {
                "id" { $current.Id = $value }
                "name" { $current.Name = $value }
                "repo_path" { $current.RepoPath = $value }
                "repo_url" { $current.RepoUrl = $value }
                "default_branch" { $current.DefaultBranch = $value }
                "docs_path" { $current.DocsPath = $value }
                "plan_path" { $current.PlanPath = $value }
                "troubleshooting_path" { $current.TroubleshootingPath = $value }
                "status" { $current.Status = $value }
                "stacks" { $currentList = "Stacks" }
                "aliases" { $currentList = "Aliases" }
            }

            continue
        }

        if ($line -match '^\s{6}-\s*(.+)$' -and $currentList) {
            $value = Normalize-YamlScalar -Value $Matches[1]
            $current[$currentList].Add($value) | Out-Null
        }
    }

    if ($null -ne $current) {
        Add-Issue -Issues $Issues -Type "unterminated-project-block" -Path "project\\registry.yaml" -Message ("Project block '{0}' is missing an END marker." -f $current.MarkerId)
    }

    return @($projects)
}

function Get-ProjectIndexRows {
    param(
        [string]$IndexPath,
        [System.Collections.Generic.List[object]]$Issues
    )

    if (-not (Test-Path -LiteralPath $IndexPath)) {
        Add-Issue -Issues $Issues -Type "missing-project-index" -Path "project\\index.md" -Message "Project summary index does not exist."
        return @()
    }

    $lines = @(Get-Content -LiteralPath $IndexPath -Encoding utf8)
    $sectionIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "## Registered Projects") {
            $sectionIndex = $i
            break
        }
    }

    if ($sectionIndex -lt 0) {
        Add-Issue -Issues $Issues -Type "missing-registered-projects-section" -Path "project\\index.md" -Message "Project index is missing the '## Registered Projects' section."
        return @()
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    for ($i = $sectionIndex + 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^## ') {
            break
        }

        if ($line -notmatch '^\|') {
            continue
        }

        if ($line -eq "| id | name | path | default branch | stacks | status |" -or
            $line -eq "| --- | --- | --- | --- | --- | --- |") {
            continue
        }

        $parts = @($line.Split('|'))
        if ($parts.Count -lt 8) {
            Add-Issue -Issues $Issues -Type "malformed-project-index-row" -Path "project\\index.md" -Message ("Malformed table row: {0}" -f $line)
            continue
        }

        $cells = @()
        for ($cellIndex = 1; $cellIndex -lt ($parts.Count - 1); $cellIndex++) {
            $cells += $parts[$cellIndex].Trim()
        }

        if ($cells.Count -ne 6) {
            Add-Issue -Issues $Issues -Type "malformed-project-index-row" -Path "project\\index.md" -Message ("Unexpected column count in table row: {0}" -f $line)
            continue
        }

        $rows.Add([pscustomobject]@{
                Id            = Normalize-MarkdownCodeScalar -Value $cells[0]
                Name          = Normalize-MarkdownCodeScalar -Value $cells[1]
                RepoPath      = Normalize-MarkdownCodeScalar -Value $cells[2]
                DefaultBranch = Normalize-MarkdownCodeScalar -Value $cells[3]
                Stacks        = @(
                    $cells[4] -split ',' |
                        ForEach-Object { Normalize-MarkdownCodeScalar -Value $_ } |
                        Where-Object { $_ -ne "" }
                )
                Status        = Normalize-MarkdownCodeScalar -Value $cells[5]
            }) | Out-Null
    }

    return @($rows)
}

$issues = [System.Collections.Generic.List[object]]::new()
$workspaceRootPath = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
$registryPath = Join-Path $workspaceRootPath "project\\registry.yaml"
$projectIndexPath = Join-Path $workspaceRootPath "project\\index.md"

$registryProjects = @(Get-RegistryProjects -RegistryPath $registryPath -Issues $issues)
$indexRows = @(Get-ProjectIndexRows -IndexPath $projectIndexPath -Issues $issues)

foreach ($project in $registryProjects) {
    if (-not $project.Id) {
        Add-Issue -Issues $issues -Type "missing-registry-field" -Path "project\\registry.yaml" -Message "A registry project block is missing 'id'."
    }

    if (-not $project.Name) {
        Add-Issue -Issues $issues -Type "missing-registry-field" -Path "project\\registry.yaml" -Message ("Registry project '{0}' is missing 'name'." -f $project.MarkerId)
    }

    if (-not $project.RepoPath) {
        Add-Issue -Issues $issues -Type "missing-registry-field" -Path "project\\registry.yaml" -Message ("Registry project '{0}' is missing 'repo_path'." -f $project.MarkerId)
    }

    if (-not $project.DefaultBranch) {
        Add-Issue -Issues $issues -Type "missing-registry-field" -Path "project\\registry.yaml" -Message ("Registry project '{0}' is missing 'default_branch'." -f $project.MarkerId)
    }

    if (-not $project.Status) {
        Add-Issue -Issues $issues -Type "missing-registry-field" -Path "project\\registry.yaml" -Message ("Registry project '{0}' is missing 'status'." -f $project.MarkerId)
    }

    if ($project.Id -and $project.MarkerId -and $project.Id -ne $project.MarkerId) {
        Add-Issue -Issues $issues -Type "project-id-marker-mismatch" -Path "project\\registry.yaml" -Message ("Project id '{0}' does not match block marker '{1}'." -f $project.Id, $project.MarkerId)
    }
}

$duplicateRegistryIds = $registryProjects |
    Group-Object Id |
    Where-Object { $_.Name -and $_.Count -gt 1 }

foreach ($duplicateId in $duplicateRegistryIds) {
    Add-Issue -Issues $issues -Type "duplicate-registry-id" -Path "project\\registry.yaml" -Message ("Registry project id '{0}' is duplicated." -f $duplicateId.Name)
}

$aliasOwners = @{}
foreach ($project in $registryProjects) {
    foreach ($alias in (Normalize-List -Values $project.Aliases)) {
        if ($aliasOwners.ContainsKey($alias) -and $aliasOwners[$alias] -ne $project.Id) {
            Add-Issue -Issues $issues -Type "duplicate-project-alias" -Path "project\\registry.yaml" -Message ("Alias '{0}' is shared by '{1}' and '{2}'." -f $alias, $aliasOwners[$alias], $project.Id)
        } elseif (-not $aliasOwners.ContainsKey($alias)) {
            $aliasOwners[$alias] = $project.Id
        }
    }
}

$duplicateIndexIds = $indexRows |
    Group-Object Id |
    Where-Object { $_.Name -and $_.Count -gt 1 }

foreach ($duplicateId in $duplicateIndexIds) {
    Add-Issue -Issues $issues -Type "duplicate-project-index-row" -Path "project\\index.md" -Message ("Project index id '{0}' is duplicated." -f $duplicateId.Name)
}

$registryById = @{}
foreach ($project in $registryProjects) {
    if (-not $project.Id -or $registryById.ContainsKey($project.Id)) {
        continue
    }

    $registryById[$project.Id] = $project
}

$indexById = @{}
foreach ($row in $indexRows) {
    if (-not $row.Id -or $indexById.ContainsKey($row.Id)) {
        continue
    }

    $indexById[$row.Id] = $row
}

foreach ($projectId in $registryById.Keys) {
    if (-not $indexById.ContainsKey($projectId)) {
        Add-Issue -Issues $issues -Type "missing-project-index-row" -Path "project\\index.md" -Message ("Project index is missing summary row for '{0}'." -f $projectId)
        continue
    }

    $registryProject = $registryById[$projectId]
    $indexRow = $indexById[$projectId]

    if ($registryProject.Name -ne $indexRow.Name) {
        Add-Issue -Issues $issues -Type "project-index-mismatch" -Path "project\\index.md" -Message ("Project '{0}' name mismatch. registry='{1}', index='{2}'." -f $projectId, $registryProject.Name, $indexRow.Name)
    }

    if ($registryProject.RepoPath -ne $indexRow.RepoPath) {
        Add-Issue -Issues $issues -Type "project-index-mismatch" -Path "project\\index.md" -Message ("Project '{0}' repo path mismatch. registry='{1}', index='{2}'." -f $projectId, $registryProject.RepoPath, $indexRow.RepoPath)
    }

    if ($registryProject.DefaultBranch -ne $indexRow.DefaultBranch) {
        Add-Issue -Issues $issues -Type "project-index-mismatch" -Path "project\\index.md" -Message ("Project '{0}' default branch mismatch. registry='{1}', index='{2}'." -f $projectId, $registryProject.DefaultBranch, $indexRow.DefaultBranch)
    }

    if ($registryProject.Status -ne $indexRow.Status) {
        Add-Issue -Issues $issues -Type "project-index-mismatch" -Path "project\\index.md" -Message ("Project '{0}' status mismatch. registry='{1}', index='{2}'." -f $projectId, $registryProject.Status, $indexRow.Status)
    }

    $registryStacks = Get-ListFingerprint -Values $registryProject.Stacks
    $indexStacks = Get-ListFingerprint -Values $indexRow.Stacks
    if ($registryStacks -ne $indexStacks) {
        Add-Issue -Issues $issues -Type "project-index-mismatch" -Path "project\\index.md" -Message ("Project '{0}' stacks mismatch. registry='{1}', index='{2}'." -f $projectId, $registryStacks, $indexStacks)
    }
}

foreach ($projectId in $indexById.Keys) {
    if (-not $registryById.ContainsKey($projectId)) {
        Add-Issue -Issues $issues -Type "orphan-project-index-row" -Path "project\\index.md" -Message ("Project index contains '{0}', but registry.yaml does not." -f $projectId)
    }
}

if ($issues.Count -eq 0) {
    Write-Output "OK: no project registry issues found."
    exit 0
}

Write-Output ("Found {0} project registry issue(s)." -f $issues.Count)
$issues |
    Sort-Object Type, Path, Message |
    Format-Table -AutoSize |
    Out-String |
    Write-Output

if ($FailOnIssue) {
    exit 1
}
