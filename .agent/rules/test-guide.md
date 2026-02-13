---
trigger: always_on
description: when working for testing or coverage.
---

# Test Guide

## Overview

Testing stack:

- **Web**: Vitest (unit/integration)
- **API**: pytest + pytest-asyncio
- **Worker**: pytest + pytest-asyncio
- **Mobile**: flutter_test

## Quick Commands

### Run All Tests

```bash
# All tests
mise test

# Or individually
mise //apps/api:test
mise //apps/web:test
mise //apps/worker:test
mise //apps/mobile:test
```

### Watch Mode

```bash
# Web
cd apps/web && bun test:watch

# API (use pytest-watch)
cd apps/api && uv run ptw
```

### Coverage

```bash
# Web
cd apps/web && bun test:coverage

# API
cd apps/api && uv run poe test-cov

# Flutter
cd apps/mobile && flutter test --coverage
```

## Web Testing (Vitest)

### Configuration

See `apps/web/vitest.config.mts`.

### File Patterns

- Unit tests: `**/*.test.{ts,tsx}`
- Integration tests: `**/*.spec.{ts,tsx}`

### Example Unit Test

```typescript
// src/lib/utils.test.ts
import { describe, it, expect } from 'vitest';
import { cn } from './utils';

describe('cn', () => {
  it('should merge class names', () => {
    expect(cn('foo', 'bar')).toBe('foo bar');
  });

  it('should handle conditional classes', () => {
    expect(cn('foo', false && 'bar', 'baz')).toBe('foo baz');
  });
});
```

### Example Component Test

```typescript
// src/components/button.test.tsx
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Button } from './button';

describe('Button', () => {
  it('should render children', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });
});
```

### Mocking

```typescript
import { vi } from 'vitest';

// Mock module
vi.mock('@/lib/api-client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
  },
}));

// Mock function
const mockFn = vi.fn().mockResolvedValue({ data: 'test' });
```

## API Testing (pytest)

### Configuration

See `apps/api/pyproject.toml` [tool.pytest.ini_options].

### File Patterns

- Tests: `tests/**/*test*.py`
- Fixtures: `tests/conftest.py`

### Example Test

```python
# tests/test_health.py
import pytest
from httpx import AsyncClient, ASGITransport

from src.main import app


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
```

### Database Testing

```python
# tests/conftest.py
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from src.lib.database import Base
from src.lib.dependencies import get_db
from src.main import app

TEST_DATABASE_URL = "postgresql+asyncpg://test:test@localhost:5432/test"


@pytest.fixture(scope="session")
async def engine():
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def db_session(engine):
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
```

## Flutter Testing

### Configuration

See `apps/mobile/pubspec.yaml` dev_dependencies and `analysis_options.yaml`.

Uses `very_good_analysis` for strict linting.

### File Patterns

- Unit tests: `test/**/*_test.dart`
- Widget tests: `test/**/*_widget_test.dart`

### Example Unit Test

```dart
// test/core/utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils.dart';

void main() {
  group('formatCurrency', () {
    test('should format with 2 decimal places', () {
      expect(formatCurrency(1234.5), '\$1,234.50');
    });
  });
}
```

### Example Widget Test

```dart
// test/features/home/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );

    expect(find.text('Home'), findsOneWidget);
  });
}
```

## CI Testing

GitHub Actions runs tests on every PR:

```yaml
- name: Test Web
  run: mise //apps/web:test

- name: Test API
  run: mise //apps/api:test

- name: Test Flutter
  run: mise //apps/mobile:test
```

## Best Practices

### Test Organization

- One test file per source file
- Group related tests with `describe`/`group`
- Use descriptive test names

### Mocking

- Mock external dependencies (APIs, databases)
- Don't mock what you're testing
- Reset mocks between tests

### Assertions

- One logical assertion per test
- Use specific matchers (`toHaveTextContent` vs `toContain`)
- Test behavior, not implementation

### Coverage

- Aim for 80%+ coverage on critical paths
- Don't chase 100% - focus on meaningful tests
- Coverage != quality
