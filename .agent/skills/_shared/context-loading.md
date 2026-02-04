# Dynamic Context Loading Guide

에이전트는 모든 리소스를 한 번에 읽지 말고, 태스크 유형에 따라 필요한 리소스만 로딩한다.
이렇게 하면 컨텍스트 윈도우를 절약하고, 관련 없는 정보로 인한 혼란을 방지한다.

---

## 로딩 순서 (모든 에이전트 공통)

### 항상 로딩 (필수)
1. `SKILL.md` — 자동 로딩됨 (Antigravity가 제공)
2. `resources/execution-protocol.md` — 실행 프로토콜

### 태스크 시작 시 로딩
3. `../_shared/difficulty-guide.md` — 난이도 판단 (Step 0)

### 난이도에 따라 로딩
4. **Simple**: 추가 로딩 없이 바로 구현
5. **Medium**: `resources/examples.md` (유사 예시 참고)
6. **Complex**: `resources/examples.md` + `resources/tech-stack.md` + `resources/snippets.md`

### 실행 중 필요시 로딩
7. `resources/checklist.md` — Step 4 (Verify) 시점에 로딩
8. `resources/error-playbook.md` — 에러 발생 시에만 로딩
9. `../_shared/common-checklist.md` — Complex 태스크의 최종 검증 시
10. `../_shared/serena-memory-protocol.md` — CLI 모드일 때만

---

## 에이전트별 태스크 유형 → 리소스 매핑

### Backend Agent

| 태스크 유형 | 필요 리소스 |
|------------|-----------|
| CRUD API 생성 | snippets.md (route, schema, model, test) |
| 인증 구현 | snippets.md (JWT, password) + tech-stack.md |
| DB 마이그레이션 | snippets.md (migration) |
| 성능 최적화 | examples.md (N+1 example) |
| 기존 코드 수정 | examples.md + Serena MCP |

### Frontend Agent

| 태스크 유형 | 필요 리소스 |
|------------|-----------|
| 컴포넌트 생성 | snippets.md (component, test) + component-template.tsx |
| 폼 구현 | snippets.md (form + Zod) |
| API 연동 | snippets.md (TanStack Query) |
| 스타일링 | tailwind-rules.md |
| 페이지 레이아웃 | snippets.md (grid) + examples.md |

### Mobile Agent

| 태스크 유형 | 필요 리소스 |
|------------|-----------|
| 화면 생성 | snippets.md (screen, provider) + screen-template.dart |
| API 연동 | snippets.md (repository, Dio) |
| 네비게이션 | snippets.md (GoRouter) |
| 오프라인 기능 | examples.md (offline example) |
| 상태 관리 | snippets.md (Riverpod) |

### Debug Agent

| 태스크 유형 | 필요 리소스 |
|------------|-----------|
| 프론트엔드 버그 | common-patterns.md (Frontend section) |
| 백엔드 버그 | common-patterns.md (Backend section) |
| 모바일 버그 | common-patterns.md (Mobile section) |
| 성능 버그 | common-patterns.md (Performance section) + debugging-checklist.md |
| 보안 버그 | common-patterns.md (Security section) |

### QA Agent

| 태스크 유형 | 필요 리소스 |
|------------|-----------|
| 보안 리뷰 | checklist.md (Security section) |
| 성능 리뷰 | checklist.md (Performance section) |
| 접근성 리뷰 | checklist.md (Accessibility section) |
| 전체 감사 | checklist.md (전체) + self-check.md |

### PM Agent

| 태스크 유형 | 필요 리소스 |
|------------|-----------|
| 신규 프로젝트 계획 | examples.md + task-template.json + api-contracts/template.md |
| 기능 추가 계획 | examples.md + Serena MCP (기존 구조 파악) |
| 리팩토링 계획 | Serena MCP만 |

---

## Orchestrator 전용: 서브에이전트 프롬프트 구성 시

Orchestrator가 서브에이전트 프롬프트를 구성할 때, 위 매핑을 참조하여
태스크 유형에 맞는 리소스 경로만 프롬프트에 포함시킨다.

```
프롬프트 구성:
1. 에이전트 SKILL.md의 Core Rules 섹션
2. execution-protocol.md
3. 태스크 유형에 매칭되는 리소스 (위 표 참조)
4. error-playbook.md (항상 포함 — 복구 필수)
5. Serena Memory Protocol (CLI 모드)
```

이렇게 하면 불필요한 리소스를 로딩하지 않아 서브에이전트의 컨텍스트 효율이 극대화된다.
