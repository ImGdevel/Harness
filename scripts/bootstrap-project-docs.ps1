param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId
)

function Get-RegistryProject {
    param(
        [string]$RegistryPath,
        [string]$TargetProjectId
    )

    if (-not (Test-Path -LiteralPath $RegistryPath)) {
        throw "Registry file not found: $RegistryPath"
    }

    $current = $null
    $currentList = $null

    foreach ($line in (Get-Content -LiteralPath $RegistryPath -Encoding utf8)) {
        if ($line -match '^  # BEGIN project:(.+)$') {
            $current = [ordered]@{
                MarkerId            = $Matches[1].Trim()
                Id                  = ""
                Name                = ""
                RepoPath            = ""
                DocsPath            = "docs"
                PlanPath            = "docs/plan"
                TroubleshootingPath = "docs/troubleshooting"
                DocsSource          = "repo"
                WikiPath            = ""
                Stacks              = [System.Collections.Generic.List[string]]::new()
            }
            $currentList = $null
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($line -match '^  # END project:(.+)$') {
            if ($current.Id -eq $TargetProjectId) {
                return [pscustomobject]@{
                    Id                  = $current.Id
                    Name                = $current.Name
                    RepoPath            = $current.RepoPath
                    DocsPath            = $current.DocsPath
                    PlanPath            = $current.PlanPath
                    TroubleshootingPath = $current.TroubleshootingPath
                    DocsSource          = $current.DocsSource
                    WikiPath            = $current.WikiPath
                    Stacks              = @($current.Stacks)
                }
            }

            $current = $null
            $currentList = $null
            continue
        }

        if ($line -match '^\s{2}-\s+id:\s*(.*)$') {
            $current.Id = $Matches[1].Trim()
            $currentList = $null
            continue
        }

        if ($line -match '^\s{4}([a-z_]+):\s*(.*)$') {
            $field = $Matches[1]
            $value = $Matches[2].Trim().Trim("'").Replace("''", "'")
            $currentList = $null

            switch ($field) {
                "name" { $current.Name = $value }
                "repo_path" { $current.RepoPath = $value }
                "docs_path" { $current.DocsPath = $value }
                "plan_path" { $current.PlanPath = $value }
                "troubleshooting_path" { $current.TroubleshootingPath = $value }
                "docs_source" { $current.DocsSource = $value }
                "wiki_path" { $current.WikiPath = $value }
                "stacks" { $currentList = "Stacks" }
            }

            continue
        }

        if ($line -match '^\s{6}-\s*(.+)$' -and $currentList) {
            $current[$currentList].Add($Matches[1].Trim()) | Out-Null
        }
    }

    throw "Project id not found in registry: $TargetProjectId"
}

function Ensure-Directory {
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$CreatedItems
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        $CreatedItems.Add("dir:$Path") | Out-Null
    }
}

function Ensure-File {
    param(
        [string]$Path,
        [string]$Content,
        [System.Collections.Generic.List[string]]$CreatedItems
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Set-Content -LiteralPath $Path -Value $Content -Encoding utf8
        $CreatedItems.Add("file:$Path") | Out-Null
    }
}

function Get-SectionDescription {
    param([string]$SectionName)

    switch ($SectionName) {
        "api" { return "프로젝트 API 계약과 요청/응답 규칙 문서를 모아두는 영역이다." }
        "architecture" { return "프로젝트 아키텍처, 모듈 경계, 런타임 흐름 문서를 모아두는 영역이다." }
        "convention" { return "프로젝트 전용 구현 규칙과 운영 규약 문서를 모아두는 영역이다." }
        "domain-tech-spec" { return "도메인 동작, 상태 전이, 유스케이스 기술 문서를 모아두는 영역이다." }
        "erd" { return "ERD, 테이블 정의, 관계 설계 문서를 모아두는 영역이다." }
        "infrastructure" { return "배포, 클라우드, 런타임 인프라 문서를 모아두는 영역이다." }
        "local-setup" { return "로컬 개발 환경 설치와 실행 문서를 모아두는 영역이다." }
        "plan" { return "프로젝트 실행 계획 문서를 모아두는 영역이다." }
        "references" { return "외부 레퍼런스와 보조 자료를 모아두는 영역이다." }
        "security" { return "인증, 인가, 시크릿, 보안 점검 문서를 모아두는 영역이다." }
        "stack-selection" { return "스택 선택과 기술 트레이드오프 기록을 모아두는 영역이다." }
        "troubleshooting" { return "프로젝트 트러블슈팅 기록을 모아두는 영역이다." }
        default { return "프로젝트 전용 문서를 모아두는 영역이다." }
    }
}

function New-ProjectDocsIndexContent {
    param(
        [string]$ProjectName,
        [string[]]$SectionNames,
        [string[]]$ExtraDirectoryNames,
        [bool]$IncludePlanSection,
        [bool]$IncludeTroubleshootingSection
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $code = [char]96
    $lines.Add("# $ProjectName Docs Index") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("이 디렉터리는 $ProjectName 프로젝트 전용 문서의 루트 인덱스다.") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("## Sections") | Out-Null
    $lines.Add("") | Out-Null

    foreach ($sectionName in $SectionNames) {
        $lines.Add(("- {0}{1}/{0}" -f $code, $sectionName)) | Out-Null
        $lines.Add(("  {0}" -f (Get-SectionDescription -SectionName $sectionName))) | Out-Null
    }

    if ($IncludePlanSection) {
        $lines.Add(("- {0}plan/{0}" -f $code)) | Out-Null
        $lines.Add(("  {0}" -f (Get-SectionDescription -SectionName "plan"))) | Out-Null
    }

    if ($IncludeTroubleshootingSection) {
        $lines.Add(("- {0}troubleshooting/{0}" -f $code)) | Out-Null
        $lines.Add(("  {0}" -f (Get-SectionDescription -SectionName "troubleshooting"))) | Out-Null
    }

    if ($ExtraDirectoryNames.Count -gt 0) {
        $lines.Add("") | Out-Null
        $lines.Add("## Existing Extra Sections") | Out-Null
        $lines.Add("") | Out-Null

        foreach ($extraDirectoryName in $ExtraDirectoryNames) {
            $lines.Add(("- {0}{1}/{0}" -f $code, $extraDirectoryName)) | Out-Null
            $lines.Add("  기존 프로젝트에 이미 존재하던 추가 문서 디렉터리다.") | Out-Null
        }
    }

    $lines.Add("") | Out-Null
    $lines.Add("## Rule") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add(("- 새 문서를 추가하면 가장 가까운 {0}index.md{0}를 같은 변경에서 갱신한다." -f $code)) | Out-Null
    $lines.Add("- 새 문서 디렉터리를 추가하면 이 루트 인덱스도 같이 갱신한다.") | Out-Null
    if ($IncludePlanSection -or $IncludeTroubleshootingSection) {
        $lines.Add(("- {0}plan/{0}과 {0}troubleshooting/{0}도 이 {0}docs/{0} 트리 안에서 함께 관리한다." -f $code)) | Out-Null
    } else {
        $lines.Add("- 계획과 트러블슈팅 경로는 registry가 가리키는 별도 문서 경로를 따른다.") | Out-Null
    }

    return $lines -join "`r`n"
}

function New-SectionIndexContent {
    param(
        [string]$ProjectName,
        [string]$SectionName
    )

    $title = ($SectionName -split '-' | ForEach-Object {
            if ($_.Length -eq 0) { return $_ }
            return ($_.Substring(0, 1).ToUpper() + $_.Substring(1))
        }) -join ' '
    $code = [char]96

    $lines = @(
        "# $ProjectName $title Index",
        "",
        (Get-SectionDescription -SectionName $SectionName),
        "",
        "## Documents",
        "",
        "- 현재 등록된 문서 없음.",
        "",
        "## Rule",
        "",
        "- 새 문서를 추가하면 목적과 파일 위치를 기록한다.",
        ("- 상위 {0}../index.md{0}와 함께 탐색 경로를 유지한다." -f $code)
    )

    return $lines -join "`r`n"
}

function New-PlanIndexContent {
    param([string]$ProjectName)
    $code = [char]96

    @(
        "# $ProjectName Plan Index",
        "",
        "이 디렉터리는 $ProjectName 프로젝트의 실행 계획 문서를 모아두는 인덱스다.",
        "",
        "## Documents",
        "",
        "- 현재 등록된 문서 없음.",
        "",
        "## Rule",
        "",
        ("- 계획 문서는 {0}YYYY-MM-DD_HHMM_<slug>.md{0} 형식을 기본으로 사용한다." -f $code),
        ("- 같은 주제 후속 계획이면 {0}_v2{0}, {0}_v3{0}로 버전을 올린다." -f $code),
        ("- 상위 {0}../index.md{0}와 함께 탐색 경로를 유지한다." -f $code)
    ) -join "`r`n"
}

function New-TroubleshootingIndexContent {
    param([string]$ProjectName)
    $code = [char]96

    @(
        "# $ProjectName Troubleshooting Index",
        "",
        "이 디렉터리는 $ProjectName 프로젝트의 트러블슈팅 기록을 모아두는 인덱스다.",
        "",
        "## Documents",
        "",
        "- 현재 등록된 문서 없음.",
        "",
        "## Rule",
        "",
        "- 재사용 가치가 있는 장애, 버그, 환경 이슈만 기록한다.",
        ("- 파일명은 {0}YYYY-MM-DD_HHMM_<slug>.md{0} 형식을 기본으로 사용한다." -f $code),
        ("- 상위 {0}../index.md{0}와 함께 탐색 경로를 유지한다." -f $code)
    ) -join "`r`n"
}

function Get-NormalizedPath {
    param([string]$Path)

    return ([System.IO.Path]::GetFullPath($Path)).TrimEnd('\')
}

function Test-IsDirectDocsChild {
    param(
        [string]$DocsRoot,
        [string]$CandidateRoot,
        [string]$ExpectedDirectoryName
    )

    $expectedPath = Join-Path (Get-NormalizedPath -Path $DocsRoot) $ExpectedDirectoryName
    return (Get-NormalizedPath -Path $CandidateRoot) -eq (Get-NormalizedPath -Path $expectedPath)
}

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$registryPath = Join-Path $workspaceRoot "project\registry.yaml"
$project = Get-RegistryProject -RegistryPath $registryPath -TargetProjectId $ProjectId

if (-not (Test-Path -LiteralPath $project.RepoPath)) {
    throw "Repository path not found: $($project.RepoPath)"
}

if (-not (Test-Path -LiteralPath (Join-Path $project.RepoPath ".git"))) {
    throw "Repository path is not a Git repository: $($project.RepoPath)"
}

if ($project.DocsSource -eq "wiki") {
    if (-not $project.WikiPath) {
        throw "Project '$($project.Id)' uses docs_source=wiki but wiki_path is empty."
    }

    if (-not (Test-Path -LiteralPath (Join-Path $project.WikiPath ".git"))) {
        throw "Wiki path is not a Git repository: $($project.WikiPath)"
    }

    if (-not (Test-Path -LiteralPath (Join-Path $project.WikiPath "Home.md"))) {
        throw "Wiki Home.md not found: $($project.WikiPath)"
    }

    Write-Output "Bootstrapped project id: $($project.Id)"
    Write-Output "Repository path: $($project.RepoPath)"
    Write-Output "Docs source: wiki"
    Write-Output "Wiki path: $($project.WikiPath)"
    Write-Output "No repo docs bootstrap was required."
    exit 0
}

$createdItems = [System.Collections.Generic.List[string]]::new()
$docsRoot = Join-Path $project.RepoPath $project.DocsPath
$planRoot = Join-Path $project.RepoPath $project.PlanPath
$troubleshootingRoot = Join-Path $project.RepoPath $project.TroubleshootingPath
$planInsideDocs = Test-IsDirectDocsChild -DocsRoot $docsRoot -CandidateRoot $planRoot -ExpectedDirectoryName "plan"
$troubleshootingInsideDocs = Test-IsDirectDocsChild -DocsRoot $docsRoot -CandidateRoot $troubleshootingRoot -ExpectedDirectoryName "troubleshooting"

$standardSections = @(
    "api",
    "architecture",
    "convention",
    "domain-tech-spec",
    "erd",
    "infrastructure",
    "local-setup",
    "references",
    "security",
    "stack-selection"
)

Ensure-Directory -Path $docsRoot -CreatedItems $createdItems

$existingExtraDirectories = @()
if (Test-Path -LiteralPath $docsRoot) {
    $excludedDocDirectories = @()
    if ($planInsideDocs) {
        $excludedDocDirectories += "plan"
    }
    if ($troubleshootingInsideDocs) {
        $excludedDocDirectories += "troubleshooting"
    }

    $existingExtraDirectories = @(
        Get-ChildItem -LiteralPath $docsRoot -Directory |
            Where-Object {
                $standardSections -notcontains $_.Name -and
                $excludedDocDirectories -notcontains $_.Name
            } |
            Select-Object -ExpandProperty Name
    )
}

$docsIndexPath = Join-Path $docsRoot "index.md"
Ensure-File `
    -Path $docsIndexPath `
    -Content (New-ProjectDocsIndexContent -ProjectName $project.Name -SectionNames $standardSections -ExtraDirectoryNames $existingExtraDirectories -IncludePlanSection $planInsideDocs -IncludeTroubleshootingSection $troubleshootingInsideDocs) `
    -CreatedItems $createdItems

foreach ($sectionName in $standardSections) {
    $sectionPath = Join-Path $docsRoot $sectionName
    Ensure-Directory -Path $sectionPath -CreatedItems $createdItems
    Ensure-File `
        -Path (Join-Path $sectionPath "index.md") `
        -Content (New-SectionIndexContent -ProjectName $project.Name -SectionName $sectionName) `
        -CreatedItems $createdItems
}

foreach ($extraDirectoryName in $existingExtraDirectories) {
    $extraIndexPath = Join-Path (Join-Path $docsRoot $extraDirectoryName) "index.md"
    Ensure-File `
        -Path $extraIndexPath `
        -Content (New-SectionIndexContent -ProjectName $project.Name -SectionName $extraDirectoryName) `
        -CreatedItems $createdItems
}

Ensure-Directory -Path $planRoot -CreatedItems $createdItems
Ensure-File `
    -Path (Join-Path $planRoot "index.md") `
    -Content (New-PlanIndexContent -ProjectName $project.Name) `
    -CreatedItems $createdItems

Ensure-Directory -Path $troubleshootingRoot -CreatedItems $createdItems
Ensure-File `
    -Path (Join-Path $troubleshootingRoot "index.md") `
    -Content (New-TroubleshootingIndexContent -ProjectName $project.Name) `
    -CreatedItems $createdItems

Write-Output "Bootstrapped project id: $($project.Id)"
Write-Output "Repository path: $($project.RepoPath)"
Write-Output "Docs root: $docsRoot"
Write-Output "Plan root: $planRoot"
Write-Output "Troubleshooting root: $troubleshootingRoot"

if ($createdItems.Count -eq 0) {
    Write-Output "No bootstrap changes were required."
} else {
    Write-Output ("Created {0} item(s)." -f $createdItems.Count)
    $createdItems | ForEach-Object { Write-Output $_ }
}
