param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [string]$RepoName
)

$root = Split-Path -Parent $PSScriptRoot
$containerPath = Join-Path $root ("project\" + $ProjectName)
$docsPath = Join-Path $containerPath "docs"
$planPath = Join-Path $containerPath "plan"
$troubleshootingPath = Join-Path $containerPath "troubleshooting"
$repoPath = Join-Path $containerPath $RepoName
$docsIndexPath = Join-Path $docsPath "index.md"

$docSections = @(
    @{
        Name = "api"
        Title = "API Docs Index"
        Description = "HTTP, gRPC, event, webhook, external contract 문서를 관리한다."
    },
    @{
        Name = "architecture"
        Title = "Architecture Docs Index"
        Description = "시스템 구조, 계층, 모듈 경계, 런타임 흐름 문서를 관리한다."
    },
    @{
        Name = "convention"
        Title = "Convention Docs Index"
        Description = "프로젝트 고유 규칙, 네이밍, 개발 규약 문서를 관리한다."
    },
    @{
        Name = "domain-tech-spec"
        Title = "Domain Tech Spec Index"
        Description = "도메인 정책, 유스케이스, 상태 전이, 기술 스펙 문서를 관리한다."
    },
    @{
        Name = "erd"
        Title = "ERD Docs Index"
        Description = "엔티티 관계, 테이블 구조, 데이터 모델 문서를 관리한다."
    },
    @{
        Name = "infrastructure"
        Title = "Infrastructure Docs Index"
        Description = "배포 구조, 네트워크, 클라우드 리소스, 운영 인프라 문서를 관리한다."
    },
    @{
        Name = "local-setup"
        Title = "Local Setup Docs Index"
        Description = "로컬 개발 환경 구성, 필수 도구, 실행 순서 문서를 관리한다."
    },
    @{
        Name = "references"
        Title = "References Docs Index"
        Description = "외부 서비스, 도메인 참고자료, 운영 참고 링크를 관리한다."
    },
    @{
        Name = "security"
        Title = "Security Docs Index"
        Description = "인증, 인가, 비밀값 처리, 권한 모델, 보안 점검 문서를 관리한다."
    },
    @{
        Name = "stack-selection"
        Title = "Stack Selection Docs Index"
        Description = "기술 스택 선정 근거, 대안 비교, 채택 이유를 관리한다."
    }
)

New-Item -ItemType Directory -Force $docsPath | Out-Null
New-Item -ItemType Directory -Force $planPath | Out-Null
New-Item -ItemType Directory -Force $troubleshootingPath | Out-Null
New-Item -ItemType Directory -Force $repoPath | Out-Null

foreach ($section in $docSections) {
    $sectionPath = Join-Path $docsPath $section.Name
    $sectionIndexPath = Join-Path $sectionPath "index.md"

    New-Item -ItemType Directory -Force $sectionPath | Out-Null

    if (-not (Test-Path $sectionIndexPath)) {
        @"
# $($section.Title)

$($section.Description)

## Documents

- 현재 등록된 문서는 아직 없다.
"@ | Set-Content -Path $sectionIndexPath -Encoding utf8
    }
}

if (-not (Test-Path $docsIndexPath)) {
    @"
# $ProjectName Docs Index

이 디렉터리는 프로젝트 고유 문서 인덱스다.

## Sections

- `api/`: HTTP, gRPC, event, webhook, 외부 계약 문서
- `architecture/`: 시스템 구조, 계층, 모듈 경계, 런타임 흐름 문서
- `convention/`: 프로젝트 전용 규칙 문서
- `domain-tech-spec/`: 도메인 정책, 유스케이스, 상태 전이, 기술 스펙 문서
- `erd/`: 엔티티 관계, 테이블 구조, 데이터 모델 문서
- `infrastructure/`: 배포 구조, 네트워크, 클라우드 리소스, 운영 인프라 문서
- `local-setup/`: 로컬 개발 환경 구성, 도구 설치, 실행 순서 문서
- `references/`: 외부 연동, 도메인, 운영 참고 문서
- `security/`: 인증, 인가, 비밀값 처리, 권한 모델, 보안 기준 문서
- `stack-selection/`: 기술 스택 선정 근거와 대안 비교 문서
"@ | Set-Content -Path $docsIndexPath -Encoding utf8
}

Write-Output "Created project container: $containerPath"
Write-Output "Docs: $docsPath"
Write-Output "Plan: $planPath"
Write-Output "Troubleshooting: $troubleshootingPath"
Write-Output "Repo: $repoPath"
