# i18n — Response Language Rules

## Language Resolution (priority order)

1. User prompt language (implicit)
2. `.agents/oma-config.yaml` → `language` field
3. Fallback: English

## Quick Rules

- Respond in user's configured language (natural language output, status updates, result files)
- Code, git commits, PR titles, file paths, config keys, status keywords → always English
- Technical terms stay in English — don't force-translate (JWT, API, middleware, scaffold)
- Inline code in backticks is never translated
- Code block comments stay in English
- Unfamiliar terms: `translated(original)` format, first occurrence only
- Translation tasks (UI strings, docs, marketing copy) → use the `/oma-translator` skill
