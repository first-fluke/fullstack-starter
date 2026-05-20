# Intent classification rules for oma-market — maps keyword patterns to one of 4 intents.

## Precedence

1. Explicit flag `--intent <pain|trend|competitor|discovery>` always wins.
2. `--vs <entity>` present → intent = `competitor` (unless `--intent` overrides).
3. `"vs "` or `" vs "` substring in topic string → intent = `competitor`.
4. Keyword scan (table below) → highest-scoring intent wins.
5. Fallback chain: complaint keyword detected → `pain`; else → `trend`.

## Keyword Pattern Table

| Intent | English keywords |
|---|---|
| pain | broken, bug, crash, slow, freeze, lag, outage, migrate, migrating, ditched, quit, ditch, alternative, replacing, painful, frustrating, hate, worst, unusable, deprecated |
| trend | trend, trending, growth, adoption, rising, popular, 2024, 2025, 2026, new, emerging, hot, forecast, survey, report, state of |
| competitor | vs, versus, alternative, replaced, switched, migrating from, comparison, compare, benchmark, better than, worse than, switch from |
| discovery | wish, need, missing, underrated, underserved, I want, if only, why doesn't, gap, overlooked, nobody, nobody builds, unmet |

Korean and other-locale intent routing is handled by the LLM reading the user's prompt directly; per-intent Korean keyword detection lives in the LLM's classification step, not in this file. Skill activation tokens for `ko` / `ja` / `zh` are owned by `.agents/hooks/core/triggers.json §oma-market.keywords`.

## Scoring Rules

- Each matched keyword adds 1 point to its intent bucket.
- Tie-break order: `competitor > pain > discovery > trend`.
- If zero keywords match, apply fallback chain (rule 5 above).

## Flag Override Examples

```
# Force pain intent regardless of topic wording
oma market research "Slack notifications" --intent pain

# Force competitor intent; vs-entity triggers fan-out harvest
oma market research "project management tools" --vs Notion --vs Asana

# Discovery scan without operators
oma market research "async comms" --intent discovery --no-operators
```

## Notes

- Keyword matching is case-insensitive.
- Stemming is NOT applied; add both `migrate` and `migrating` explicitly.
- Domain-specific overrides can be added to `oma-config.yaml` under `market_research.intent_overrides`.
- Discovery and competitor intents are NOT triggered by keyword scan alone when confidence < 2 points; require explicit flag or `--vs` in that case.
