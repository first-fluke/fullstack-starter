# Changelog

## [2.9.0](https://github.com/first-fluke/fullstack-starter/compare/v2.8.0...v2.9.0) (2026-02-12)


### Features

* **web:** add kebab-case naming convention to orval config ([0ad5e9c](https://github.com/first-fluke/fullstack-starter/commit/0ad5e9c3b65e9e55f41ae8ec69f9b3f7c070832a))

## [2.8.0](https://github.com/first-fluke/fullstack-starter/compare/v2.7.1...v2.8.0) (2026-02-07)


### Features

* remove dashboard web server and related scripts ([cb7d818](https://github.com/first-fluke/fullstack-starter/commit/cb7d8181e4923bd010d79dad4ff4ad2ba2801391))

## [2.7.1](https://github.com/first-fluke/fullstack-starter/compare/v2.7.0...v2.7.1) (2026-01-29)


### Bug Fixes

* prevent path traversal vulnerability in dashboard server ([22fed9d](https://github.com/first-fluke/fullstack-starter/commit/22fed9d80012ed18a64c262a2597284146177511))

## [2.7.0](https://github.com/first-fluke/fullstack-starter/compare/v2.6.0...v2.7.0) (2026-01-29)


### Features

* add multi-agent orchestration skills from subagent-orchestrator ([cdfa245](https://github.com/first-fluke/fullstack-starter/commit/cdfa245bc74db313ebe17d79212f1135c55b084b))

## [2.6.0](https://github.com/first-fluke/fullstack-starter/compare/v2.5.0...v2.6.0) (2026-01-27)


### Features

* add new agent skills and their associated reference documentation ([afc2363](https://github.com/first-fluke/fullstack-starter/commit/afc2363722e02699f6c8e19aa58872fae85d1f90))

## [2.5.0](https://github.com/first-fluke/fullstack-starter/compare/v2.4.0...v2.5.0) (2026-01-23)


### Features

* **root:** add postgres best practices skill ([99c6f25](https://github.com/first-fluke/fullstack-starter/commit/99c6f2567a2a53abd7692a3f51ec39eb495ae450))

## [2.4.0](https://github.com/first-fluke/fullstack-starter/compare/v2.3.0...v2.4.0) (2026-01-19)


### Features

* Add comprehensive AI agent skills library ([615ed8f](https://github.com/first-fluke/fullstack-starter/commit/615ed8f0256c4b890568321abfa31064ed2d08fe))
* Add comprehensive AI agent skills library ([4d6d56d](https://github.com/first-fluke/fullstack-starter/commit/4d6d56d14d048b37ec5c9196144cacded528bdf6))

## [2.3.0](https://github.com/first-fluke/fullstack-starter/compare/v2.2.2...v2.3.0) (2026-01-19)


### Features

* **infra:** add Firestore and Vertex AI resources ([95fe4aa](https://github.com/first-fluke/fullstack-starter/commit/95fe4aa620ad2e27dc4ce255e96c4047f759a74b))
* **infra:** add Firestore and Vertex AI resources ([d9e3b70](https://github.com/first-fluke/fullstack-starter/commit/d9e3b705f2c4e207cde89b54da633e735bb7d3ea))

## [2.2.2](https://github.com/first-fluke/fullstack-starter/compare/v2.2.1...v2.2.2) (2026-01-18)


### Bug Fixes

* **web:** resolve typescript errors in auth-client and custom instance ([4350494](https://github.com/first-fluke/fullstack-starter/commit/4350494f79e36de675354ba2495701759492874d))

## [2.2.1](https://github.com/first-fluke/fullstack-starter/compare/v2.2.0...v2.2.1) (2026-01-17)


### Bug Fixes

* **mobile:** update swagger_parser config to latest format ([a517317](https://github.com/first-fluke/fullstack-starter/commit/a5173179062cd55cbf706f094f22a4f8e084a0a8))

## [2.2.0](https://github.com/first-fluke/fullstack-starter/compare/v2.1.0...v2.2.0) (2026-01-17)


### Features

* add gcp-migration skill and fix reviewdog ci errors ([a27edfa](https://github.com/first-fluke/fullstack-starter/commit/a27edfacb1383c9b112edf82d985e9ddb33d93c2))
* add gcp-migration skill and fix reviewdog ci errors ([8918f17](https://github.com/first-fluke/fullstack-starter/commit/8918f17896be9c3255afa16869e6bbae0432e42b))
* GCP 마이그레이션 스킬 및 가이드 문서 추가 ([f0731c9](https://github.com/first-fluke/fullstack-starter/commit/f0731c9774d1264295cd443b3f5f2a7d90c4ac00))


### Bug Fixes

* **ci:** reviewdog biome/ruff 포맷 지원 문제 수정 ([0a1ff7b](https://github.com/first-fluke/fullstack-starter/commit/0a1ff7b0e74aca4950b00aa55419789ed86ef9fa))

## [2.1.0](https://github.com/first-fluke/fullstack-starter/compare/v2.0.0...v2.1.0) (2026-01-16)


### Features

* add db:migrate task and sort tasks alphabetically ([e66a494](https://github.com/first-fluke/fullstack-starter/commit/e66a494fbcca1a5e09cd1f523ea86e1c7cee679d))

## [2.0.0](https://github.com/first-fluke/fullstack-starter/compare/v1.3.0...v2.0.0) (2026-01-16)


### ⚠ BREAKING CHANGES

* **api:** existing tokens are incompatible, users need to re-login

### Features

* add react best practices skill and update biome config ([c5de500](https://github.com/first-fluke/fullstack-starter/commit/c5de50092ff7eb1d12f58aa3ad192daa416607a2))
* recommend `@reactuses/core` for advanced event handlers, global event listeners, and client-side storage patterns ([710350f](https://github.com/first-fluke/fullstack-starter/commit/710350f9a9dbfe1d792dd9ce09ca95fd21bb0848))


### Bug Fixes

* **api:** resolve ruff lint errors ([c49492a](https://github.com/first-fluke/fullstack-starter/commit/c49492a58e533b92cfce2de05bf07f753ccc001d))


### Code Refactoring

* **api:** migrate from python-jose to jwcrypto for JWE ([5d42928](https://github.com/first-fluke/fullstack-starter/commit/5d4292877ef065fa277a84a175f5cd863f5d3cd4))

## [1.3.0](https://github.com/first-fluke/fullstack-starter/compare/v1.2.0...v1.3.0) (2026-01-15)


### Features

* implement stateless JWE authentication and add documentation ([edf6c40](https://github.com/first-fluke/fullstack-starter/commit/edf6c40439b5f7b7baf808aec32a2b2c138eb7ca))

## [1.2.0](https://github.com/first-fluke/fullstack-starter/compare/v1.1.0...v1.2.0) (2026-01-14)


### Features

* **web:** add T3 Env schema ([78adbfe](https://github.com/first-fluke/fullstack-starter/commit/78adbfef969cb2daae5af1f74de804645b9ef0bf))


### Bug Fixes

* **web:** handle optional params in not-found page ([4839c21](https://github.com/first-fluke/fullstack-starter/commit/4839c21e2d916c210741b402d54ec5491dee97df))
* **web:** migrate client env variables to T3 Env ([b740527](https://github.com/first-fluke/fullstack-starter/commit/b7405270a0fefe95b94acaf5555758eab96b7bd6))
* **web:** migrate server env variables to T3 Env ([43960cb](https://github.com/first-fluke/fullstack-starter/commit/43960cb284777f7e5ca69f941c2778896c17fb52))

## [1.1.0](https://github.com/first-fluke/fullstack-starter/compare/v1.0.1...v1.1.0) (2026-01-13)


### Features

* **web:** add @reactuses/core and reorganize atoms ([cf5e4cb](https://github.com/first-fluke/fullstack-starter/commit/cf5e4cb8726213259b3ed2244f622d532819801f))

## [1.0.1](https://github.com/first-fluke/fullstack-starter/compare/v1.0.0...v1.0.1) (2026-01-12)


### Bug Fixes

* **api:** resolve ruff lint errors ([f28a4c8](https://github.com/first-fluke/fullstack-starter/commit/f28a4c81a18423c84ad65b98122fdf6f3c15c284))
* **ci:** replace pyright with mypy in pipelines ([6ee1db3](https://github.com/first-fluke/fullstack-starter/commit/6ee1db338bc40ad125273ef8af8cfec2d94f13c6))
* **mobile:** resolve lint errors and comply with very_good_analysis ([0b3c8c4](https://github.com/first-fluke/fullstack-starter/commit/0b3c8c48cf13c28fa93d279409da68d47ff116d4))
* standardize Python version to 3.12 across all configurations ([3893d15](https://github.com/first-fluke/fullstack-starter/commit/3893d151d23afe7a7b6b2b9f2cf9b8ba3ba6eb58))
* **worker:** allow empty test suite to pass in pre-push hook ([11ef628](https://github.com/first-fluke/fullstack-starter/commit/11ef628c9d94e9938cbfb654c273feeb3d016faa))

## 1.0.0 (2026-01-12)


### Features

* add CodeQL SAST, rate limiting, pagination, and architecture diagram ([7b37139](https://github.com/first-fluke/fullstack-starter/commit/7b371391f14cce3406886913a3764dea6a6c17ab))
* add production hardening with Fastlane, Firebase Crashlytics, OpenTelemetry ([420cea6](https://github.com/first-fluke/fullstack-starter/commit/420cea6ed80ac3b8ec73d8d6844645425b91f00e))
* add release-please for template versioning ([b8c815b](https://github.com/first-fluke/fullstack-starter/commit/b8c815be4617323184743cd73ff5e511cf6bae49))
* add root-level infra:up/down tasks and GitHub stars badge ([8dd9af9](https://github.com/first-fluke/fullstack-starter/commit/8dd9af9e8caf4eab986f8afdeade0c788850d6a7))
* **i18n:** add shared i18n package as single source of truth ([9b93d27](https://github.com/first-fluke/fullstack-starter/commit/9b93d2707f170303d99e18cddedb877e2c753a14))
* initial fullstack starter template ([46f9f26](https://github.com/first-fluke/fullstack-starter/commit/46f9f260017515f141e9efb81580b811b49578ba))
* **mise:** add git:pre-push task for branch validation and conditional tests ([3279fd8](https://github.com/first-fluke/fullstack-starter/commit/3279fd896e42c3ed3faf980fec6629b448e93fa9))
* **mobile:** add forui UI library and upgrade Flutter to 3.38 ([00d5755](https://github.com/first-fluke/fullstack-starter/commit/00d57556fee085dc81cfea69a0200e7564e2d191))
* **web:** add production-ready Next.js config and UI registries ([fa109de](https://github.com/first-fluke/fullstack-starter/commit/fa109deeeafd48260a37756463ad1f34cf4c0b6b))
* **web:** add PWA support with Serwist and essential app files ([59f97f1](https://github.com/first-fluke/fullstack-starter/commit/59f97f1cf7fbdf0cd9b4891494f127f9881637d8))
* **web:** add security headers to Next.js config ([1c30de7](https://github.com/first-fluke/fullstack-starter/commit/1c30de78d1584d542773e05d89108575f867c17d))
* **web:** add TanStack devtools and form context setup ([b6ba47f](https://github.com/first-fluke/fullstack-starter/commit/b6ba47ff9656bacd296297f82bf91f897815b7ee))
* **web:** add useIsClient hook for SSR-safe client detection ([e1455d1](https://github.com/first-fluke/fullstack-starter/commit/e1455d1ba72a34ab4a32d37bd78a0757ceca863c))
* **web:** disable X-Powered-By header ([8d43c65](https://github.com/first-fluke/fullstack-starter/commit/8d43c65af7e37e9599797518b26cd9d1d879eb20))


### Bug Fixes

* **i18n:** move mobile arb files to lib/i18n/messages ([1ae76dd](https://github.com/first-fluke/fullstack-starter/commit/1ae76dd46771df222487f1e9744d11fe2bc749bd))
* **i18n:** move web messages to src/config/messages ([d7ee63a](https://github.com/first-fluke/fullstack-starter/commit/d7ee63af9bfb122aa242ba5b664afdb0c0d81e75))
* simplify gh api star command ([9433e28](https://github.com/first-fluke/fullstack-starter/commit/9433e280881c3a00b7467e2eff54130eb975bc99))
* use correct gh api command for starring repository ([0e40335](https://github.com/first-fluke/fullstack-starter/commit/0e403352742557cfe6224fa563ed595020e7f1ff))
* use gh-star extension for starring repository ([a9e2501](https://github.com/first-fluke/fullstack-starter/commit/a9e2501de036222f1106da271aada4e15e3c23ef))
