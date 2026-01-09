# 왜 이 기술 스택인가?

[English](./WHY.md) | [한국어](./WHY.ko.md)

이 문서는 풀스택 스타터 템플릿의 각 기술 선택에 대한 이유를 설명합니다.

## 프론트엔드

### Next.js 16 + React 19

- **서버 컴포넌트**: 클라이언트 JavaScript 번들 감소, 초기 로딩 시간 개선
- **App Router**: 레이아웃, 로딩 상태, 에러 바운더리가 내장된 파일 기반 라우팅
- **Turbopack**: Webpack 대비 빠른 개발 서버 및 빌드
- **React 19**: Concurrent 기능, Actions, `use()` 훅으로 성능 향상

### TailwindCSS v4

- **제로 런타임**: 모든 스타일이 빌드 시점에 컴파일
- **Lightning CSS**: PostCSS 기반 v3 대비 100배 빠름
- **CSS 우선 설정**: JavaScript 설정 대신 네이티브 CSS 문법
- **작은 번들**: 사용하지 않는 스타일 자동 제거

### shadcn/ui

- **복사-붙여넣기 컴포넌트**: npm 의존성 없음, 코드 완전 소유
- **Radix 기반**: 기본적으로 접근성 지원 (ARIA, 키보드 내비게이션)
- **Tailwind 네이티브**: 프로젝트 스타일링 방식과 일관성
- **커스터마이징 용이**: 디자인 시스템과 싸우지 않고 쉽게 수정

### TanStack Query

- **자동 캐싱**: 중복 제거, 백그라운드 리페치, stale-while-revalidate
- **DevTools**: 디버깅용 내장 쿼리 인스펙터
- **프레임워크 독립적**: React Native에서도 동일한 멘탈 모델
- **Optimistic updates**: 반응형 UI를 위한 1급 지원

### Jotai

- **바텀업 원자 모델**: 아톰을 조합해 상태를 구성하고, 아톰 의존성 기반으로 렌더링 최적화
- **불필요한 리렌더 없음**: 변경된 아톰을 구독하는 컴포넌트만 리렌더
- **TypeScript 우선**: 뛰어난 타입 추론
- **경량**: ~3KB, 기본 사용에 프로바이더 불필요

### TanStack Form

- **헤드리스 & 컴포저블**: `withForm` HOC 패턴으로 타입 안전한 모듈화된 폼 구성
- **타입 안전**: 폼 값과 검증에 대한 완전한 TypeScript 추론
- **심플한 인터페이스**: React Hook Form이나 Formik보다 깔끔한 API

## 백엔드

### FastAPI

- **AI/ML 생태계**: Python AI 라이브러리 직접 접근 (LangChain, Transformers 등)
- **Async 우선**: Starlette 기반, 네이티브 async/await 지원
- **자동 생성 문서**: OpenAPI (Swagger)와 ReDoc 기본 제공
- **Pydantic 검증**: 타입 힌트를 통한 요청/응답 검증
- **확장성**: 상태 비저장 설계로 쉬운 수평 확장

### SQLAlchemy (async)

- **ORM 유연성**: 필요하면 raw SQL, 편할 때는 ORM
- **Async 지원**: asyncpg 드라이버로 네이티브 asyncio
- **마이그레이션 친화적**: 스키마 버전 관리를 위한 Alembic 통합
- **성숙한 생태계**: 수십 년간 프로덕션에서 검증됨

### PostgreSQL 16

- **ACID 준수**: 데이터 무결성 보장
- **JSON 지원**: 유연한 반정형 데이터를 위한 JSONB
- **벡터 확장**: AI 임베딩과 유사도 검색을 위한 pgvector
- **성능**: 고급 쿼리 플래너, 병렬 쿼리, 파티셔닝
- **확장 기능**: PostGIS, 전문 검색 내장

### Redis 7

- **밀리초 미만 지연**: 인메모리 데이터 구조 저장소
- **다목적**: 캐시, 세션 저장소, pub/sub, 속도 제한
- **영속성 옵션**: 내구성을 위한 RDB 스냅샷 또는 AOF
- **클러스터 지원**: 필요시 수평 확장

## 모바일

### Flutter 3.38

- **전자정부 표준프레임워크 v5**: 한국 전자정부 표준프레임워크 공식 모바일 프레임워크로 선정
- **유연한 버전 관리**: 프로젝트별 Flutter/Dart 버전 고정 및 업그레이드 용이
- **핫 리로드**: 개발 중 1초 미만의 UI 반복
- **네이티브 성능**: ARM으로 컴파일, JavaScript 브릿지 없음

### Riverpod 3

- **컴파일 안전**: 컴파일 시점에 의존성 검사
- **테스트 용이**: 격리된 상태로 쉽게 목킹 및 테스트
- **Context 불필요**: BuildContext 없이 어디서나 상태 접근
- **코드 생성**: riverpod_generator로 보일러플레이트 감소

### go_router 17

- **선언적 라우팅**: 웹처럼 URL 기반 내비게이션
- **딥링크**: iOS/Android에서 바로 작동
- **타입 안전**: 코드 생성된 라우트 파라미터
- **중첩 내비게이션**: 하단 내비, 탭을 위한 Shell 라우트

### Forui

- **Flutter용 shadcn/ui**: 웹(shadcn/ui)과 일관된 디자인 언어
- **커스터마이징 가능**: Tailwind 스타일 토큰 시스템으로 테마 적용
- **접근성**: 모바일용 ARIA 동등 시맨틱
- **경량**: 무거운 의존성 없이 위젯만

### Firebase Crashlytics

- **실시간 크래시 리포팅**: 프로덕션 이슈 즉시 확인
- **브레드크럼**: 크래시로 이어진 사용자 행동
- **스택 난독화 해제**: Flutter용 읽기 쉬운 스택 트레이스
- **무료 티어**: 대부분의 앱에 충분한 한도

### Fastlane

- **자동화된 릴리스**: 한 명령으로 빌드, 서명, 배포
- **크로스플랫폼**: 같은 워크플로우로 iOS와 Android
- **CI 통합**: GitHub Actions와 완벽 호환
- **메타데이터 관리**: 스크린샷, 설명, 변경 로그

## 인프라

### Terraform

- **Infrastructure as Code**: 버전 관리, 리뷰 가능한 인프라 변경
- **선언적**: 원하는 상태를 기술하면 Terraform이 처리
- **상태 관리**: 배포된 것 추적, 적용 전 계획
- **모듈**: 재사용 가능하고 공유 가능한 인프라 컴포넌트

### GCP (Cloud Run, Cloud SQL, Cloud Storage)

- **넉넉한 무료 크레딧**: 신규 계정 $300 크레딧, 다수 서비스 상시 무료 티어
- **서버리스 컨테이너**: 서버 관리 없음, 제로로 스케일
- **사용량 기반 과금**: 요청 처리 시에만 과금
- **관리형 데이터베이스**: 자동 백업, HA, 유지보수
- **글로벌 CDN**: 정적 자산 및 API 캐싱용 Cloud CDN

### GitHub Actions + Workload Identity Federation

- **키리스 배포**: 관리하거나 교체할 서비스 계정 키 없음
- **네이티브 GitHub 통합**: push, PR, 스케줄에 트리거
- **매트릭스 빌드**: 버전/플랫폼별 병렬 테스트
- **마켓플레이스**: 수천 개의 커뮤니티 액션

## 개발자 경험

### Rust 기반 툴체인

**속도**를 위해 전체 개발 워크플로우에서 Rust 기반 도구를 선택:

- **Biome**: 린터 + 포매터 통합, ESLint + Prettier 대비 100배 빠름
- **uv**: Python 패키지 매니저, pip/poetry 대비 10-100배 빠름
- **Turbopack**: Next.js 번들러, Webpack보다 빠름
- **Lightning CSS**: TailwindCSS v4 컴파일러, PostCSS 대비 100배 빠름

### mise

- **폴리글랏 모노레포 지원**: Node, Python, Flutter, Terraform — 다른 생태계를 하나의 도구로
- **프로젝트 로컬 버전**: `.mise.toml`로 개발자 온보딩 시 OS 독립적으로 일관된 환경 보장
- **태스크 러너**: Makefile, npm scripts, shell scripts를 통합된 `mise` 명령어로 대체
- **Rust로 작성**: 즉각적인 도구 전환, 시작 오버헤드 없음

### 폴리글랏 모노레포

- **단일 저장소**: Web (TypeScript), API (Python), Mobile (Dart), Infra (HCL)를 한 곳에
- **바운디드 컨텍스트**: 각 언어 생태계는 해당 디렉토리로 스코프가 제한되어 상호 오염 방지
- **원자적 변경**: 프론트엔드 + 백엔드 변경을 단일 PR로
- **통합 도구**: 모든 앱에 동일한 `mise` 명령어

## 트레이드오프

| 선택 | 트레이드오프 | 수용하는 이유 |
|------|-------------|--------------|
| Remix/SvelteKit 대신 Next.js | 더 큰 번들, 더 많은 복잡성 | 생태계, React 19 호환성 |
| Node.js 대신 FastAPI | 두 개의 런타임 (Node + Python) | Python AI/ML 생태계, 확장성 |
| React Native 대신 Flutter | 더 큰 앱 크기, 커스텀 렌더링 | 전자정부 표준프레임워크 v5, 유연한 버전 관리 |

## 요약

이 스택이 최적화하는 것:

1. **개발자 속도**: 핫 리로드, 타입 안전성, 자동 생성 클라이언트
2. **프로덕션 준비**: 관리형 서비스, 서버리스 스케일링, CI/CD
3. **팀 확장성**: 명확한 경계, 공유 도구, 문서화
4. **장기 유지보수성**: 검증된 기술, 활발한 커뮤니티
