param(
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot),
    [string[]]$DocRoots = @("common", "stack", "project"),
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

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseUri = [System.Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $targetUri = [System.Uri](Resolve-Path -LiteralPath $TargetPath).Path
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

function Test-IndexEntry {
    param(
        [string]$IndexContent,
        [string]$Name,
        [switch]$Directory
    )

    $patterns = @(
        ('`' + $Name + '`')
    )

    if ($Directory) {
        $patterns += ('`' + $Name + '/`')
    }

    foreach ($pattern in $patterns) {
        if ($IndexContent.Contains($pattern)) {
            return $true
        }
    }

    return $false
}

function Get-TrackedState {
    param([string]$WorkspaceRootPath)

    $trackedFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $trackedDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $gitFiles = @(git -C $WorkspaceRootPath ls-files)
    } catch {
        return [pscustomobject]@{
            Files       = $trackedFiles
            Directories = $trackedDirectories
            Enabled     = $false
        }
    }

    foreach ($gitFile in $gitFiles) {
        if (-not $gitFile) {
            continue
        }

        $relativePath = $gitFile.Replace('/', '\')
        $trackedFiles.Add($relativePath) | Out-Null

        $parentPath = Split-Path -Parent $relativePath
        while ($parentPath) {
            $trackedDirectories.Add($parentPath) | Out-Null
            $nextParent = Split-Path -Parent $parentPath
            if ($nextParent -eq $parentPath) {
                break
            }
            $parentPath = $nextParent
        }
    }

    return [pscustomobject]@{
        Files       = $trackedFiles
        Directories = $trackedDirectories
        Enabled     = $true
    }
}

$issues = [System.Collections.Generic.List[object]]::new()
$workspaceRootPath = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
$trackedState = Get-TrackedState -WorkspaceRootPath $workspaceRootPath

$docRootItems = foreach ($docRoot in $DocRoots) {
    $candidate = Join-Path $workspaceRootPath $docRoot
    if (Test-Path -LiteralPath $candidate) {
        Get-Item -LiteralPath $candidate
    } else {
        Add-Issue -Issues $issues -Type "missing-doc-root" -Path $docRoot -Message "Configured doc root does not exist."
    }
}

foreach ($rootItem in $docRootItems) {
    $directories = @($rootItem) + @(Get-ChildItem -LiteralPath $rootItem.FullName -Recurse -Directory | Where-Object {
                $_.FullName -notmatch '\\\.git($|\\)' -and $_.FullName -notmatch '\\\.github($|\\)'
            })

    foreach ($directory in $directories) {
        $children = @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue)
        $indexPath = Join-Path $directory.FullName "index.md"
        $relativeDirectory = Get-RelativePath -BasePath $workspaceRootPath -TargetPath $directory.FullName
        $markdownFiles = @($children | Where-Object {
                if ($_.PSIsContainer -or $_.Extension -ne ".md") {
                    return $false
                }

                if (-not $trackedState.Enabled) {
                    return $true
                }

                $relativeFile = Get-RelativePath -BasePath $workspaceRootPath -TargetPath $_.FullName
                return $trackedState.Files.Contains($relativeFile)
            })
        $childDirectories = @($children | Where-Object {
                if (-not $_.PSIsContainer) {
                    return $false
                }

                if (-not $trackedState.Enabled) {
                    return $true
                }

                $relativeChildDirectory = Get-RelativePath -BasePath $workspaceRootPath -TargetPath $_.FullName
                return $trackedState.Directories.Contains($relativeChildDirectory)
            })
        $requiresIndex = ($markdownFiles.Count -gt 0) -or ($childDirectories.Count -gt 0)

        if ($requiresIndex -and -not (Test-Path -LiteralPath $indexPath)) {
            Add-Issue -Issues $issues -Type "missing-index" -Path $relativeDirectory -Message "Documentation directory requires index.md."
            continue
        }

        if (-not (Test-Path -LiteralPath $indexPath)) {
            continue
        }

        $gitkeepPath = Join-Path $directory.FullName ".gitkeep"
        if (Test-Path -LiteralPath $gitkeepPath) {
            Add-Issue -Issues $issues -Type "stale-gitkeep" -Path $relativeDirectory -Message "Directory has index.md and should not keep .gitkeep."
        }

        $indexContent = Get-Content -LiteralPath $indexPath -Raw
        $parentPath = Split-Path -Parent $directory.FullName
        if ($parentPath -and $parentPath.StartsWith($workspaceRootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $parentIndexPath = Join-Path $parentPath "index.md"
            if ((Test-Path -LiteralPath $parentIndexPath) -and ($directory.FullName -ne $rootItem.FullName)) {
                $parentContent = Get-Content -LiteralPath $parentIndexPath -Raw
                if (-not (Test-IndexEntry -IndexContent $parentContent -Name $directory.Name -Directory)) {
                    Add-Issue -Issues $issues -Type "missing-parent-entry" -Path $relativeDirectory -Message "Parent index.md does not mention this directory."
                }
            }
        }

        foreach ($markdownFile in ($markdownFiles | Where-Object { $_.Name -ne "index.md" })) {
            if (-not (Test-IndexEntry -IndexContent $indexContent -Name $markdownFile.Name)) {
                $relativeFile = Get-RelativePath -BasePath $workspaceRootPath -TargetPath $markdownFile.FullName
                Add-Issue -Issues $issues -Type "missing-file-entry" -Path $relativeFile -Message "Nearest index.md does not mention this Markdown file."
            }
        }
    }
}

if ($issues.Count -eq 0) {
    Write-Output "OK: no documentation governance issues found."
    exit 0
}

Write-Output ("Found {0} documentation governance issue(s)." -f $issues.Count)
$issues |
Sort-Object Type, Path |
Format-Table -AutoSize |
Out-String |
Write-Output

if ($FailOnIssue) {
    exit 1
}
