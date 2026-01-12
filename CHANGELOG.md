# Changelog

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
