---
paths:
  - "packages/i18n/**"
  - "apps/web/src/config/messages/**"
  - "apps/mobile/lib/i18n/**"
---

# I18n Workflow

## Source of Truth
The single source of truth for all i18n keys is in packages/i18n/src/.

- Do NOT edit files in apps/web/src/config/messages or apps/mobile/lib/i18n directly
- ALWAYS make changes in packages/i18n/src/*.arb (en.arb, ko.arb, ja.arb)

## Workflow

### 1. Modify Keys
Add, update, or delete keys in packages/i18n/src/en.arb.
Sync changes to other language files (ko.arb, ja.arb).

### 2. Build & Distribute
```bash
mise //packages/i18n:build
```

This generates:
- Web: apps/web/src/config/messages/*.json
- Mobile: apps/mobile/lib/i18n/messages/*.arb

### 3. Apply to Mobile
```bash
cd apps/mobile
flutter gen-l10n
```

## Using Translations

### Web (Next.js)
The build process transforms double underscores (`__`) in ARB keys to nested objects in JSON.
For example, `nav__home` in ARB becomes `nav.home` in code.

```typescript
import { useTranslations } from 'next-intl';

function MyComponent() {
  const t = useTranslations();
  // packages/i18n: nav__home -> apps/web: nav.home
  return <Link href="/">{t('nav.home')}</Link>;
}
```

### Mobile (Flutter)
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.save)
```

## Best Practices
1. Always include descriptions (@key) for translators
2. Keep keys descriptive
3. Use consistent naming across locales
4. Test all locales after adding translations
5. Build frequently to catch errors early
6. Never modify generated files

## Troubleshooting

### Build Fails
```bash
rm -rf packages/i18n/dist apps/web/src/config/messages apps/mobile/lib/i18n/messages
mise //packages/i18n:build
```

### Mobile Not Showing Translations
```bash
cd apps/mobile
flutter clean && flutter pub get && flutter gen-l10n
```
