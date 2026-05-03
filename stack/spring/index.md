# Spring Docs Index

Spring 관련 컨벤션과 스펙 문서의 빠른 탐색용 인덱스다.

## Sections

- `convention/`: Spring 코드 스타일, 계층 규칙, 패키지 규칙
- `spec/`: Spring 아키텍처와 기능 스펙
- `test/`: 테스트 규칙, 픽스처, 슬라이스 테스트 기준
- `entity/`: 엔티티, 매핑, 영속성 관련 규칙
- `snippets/`: 짧게 재사용하는 Spring 코드 예제와 패턴

## Current Highlights

- `convention/error-handling-convention.md`: `ErrorCode`, `BusinessException`, validation/binding 예외, 프론트 노출 경계, Swagger 문서화 기준
- `snippets/business-exception-and-error-code-snippet.md`: 공통 `ErrorCode`, `BusinessException`, `ErrorResponse`, `GlobalExceptionHandler` 구현 예시
- `convention/serialization-and-parsing-convention.md`: Jackson `ObjectMapper` 재사용, JSON codec, parser/normalizer 공통화 후보, 실패 처리 기준
- `snippets/serialization-and-parsing-snippet.md`: `JsonCodec`, feature-specific parser, string/enum parser 예시
- `convention/common-module-method-candidates.md`: 공통 모듈 메서드 후보와 라이브러리 선택 기준
- `snippets/common-module-method-snippet.md`: 공통 메서드 코드 스니펫과 성능 테스트 prefix 예시
- `convention/spring-gradle-ci-test-convention.md`: JUnit tag 기반 unit/integration test 분리와 Gradle CI cache 기준

## Related

- 실제 프로젝트 레지스트리는 `../../project/index.md`와 `../../project/registry.yaml`에서 관리한다.
