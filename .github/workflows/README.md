# GitHub Actions — cost & deploy playbook

Copy these patterns into product monorepos. Goal: keep private-repo
**billable minutes under the free ~2,000/month** (Windows ×2, macOS ×10).

## Defaults every deploy workflow should have

| Control | Why |
|---------|-----|
| `paths:` on `push` | Unrelated monorepo edits must not rebuild docker |
| Never `packages/**` | Prefer explicit `packages/<name>/**` per consumer |
| No `pull_request` on deploy | PR CI lives in `review.yml`; deploy = main only |
| `concurrency` + `cancel-in-progress: true` | Rapid main pushes: only latest SHA finishes |
| `docker/build-push-action` + `cache-from/to: type=gha,scope=<img>` | Warm builds cut 40–60% of docker time |
| `permissions.actions: write` | Required to write GHA docker cache |
| `timeout-minutes` on light jobs | Bound runaway runners (e.g. release-please) |

## Path fan-out rules

```yaml
# BAD — one package edit rebuilds api + web + worker
paths:
  - "packages/**"

# GOOD — each service lists only packages it COPYs / imports
# api/worker (python workspace dep):
paths:
  - "apps/api/**"
  - "packages/core/**"
# web (bun workspace tokens/i18n only):
paths:
  - "apps/web/**"
  - "packages/design-tokens/**"
  - "packages/i18n/**"
```

If the Dockerfile context is `apps/<svc>` only and does **not** COPY monorepo
`packages/`, do not list packages at all.

## Docker build snippet (canonical)

```yaml
permissions:
  contents: read
  id-token: write
  actions: write

concurrency:
  group: deploy-<svc>
  cancel-in-progress: true

steps:
  - uses: docker/setup-buildx-action@v4
  - uses: docker/build-push-action@v6
    with:
      context: apps/api   # or monorepo root if Dockerfile needs packages/*
      file: apps/api/Dockerfile
      push: true
      platforms: linux/amd64
      tags: ${{ env.IMAGE }}:${{ github.sha }}
      cache-from: type=gha,scope=<unique-image-name>
      cache-to: type=gha,mode=max,scope=<unique-image-name>
```

Use a **unique `scope` per image** so api/web/worker caches do not clobber each other.

## release-please

```yaml
on:
  push:
    branches: [main]
    paths-ignore:
      - "**.md"
      - "docs/**"
concurrency:
  group: release-please
  cancel-in-progress: true
```

## Measure usage

```bash
# Org monthly Actions usage (enhanced billing)
gh api "orgs/<org>/settings/billing/usage?year=YYYY&month=M" \
  | jq '[.usageItems[]
      | select(.product=="actions" and .unitType=="Minutes")
      | {repo: .repositoryName, sku, qty: .quantity}]'
```

Public repos usually do not count against the free private minutes quota;
private Linux minutes count 1×.

## What not to do

- Auto-deploy on every PR (test in `review.yml`, deploy on main/tag only)
- macOS/Windows matrix on every PR (10× / 2× billable)
- `cancel-in-progress: false` on deploy when agents push many main commits
- Bare `docker build && docker push` without GHA cache in monorepos that ship often
