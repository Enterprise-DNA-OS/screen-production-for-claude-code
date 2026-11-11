---
description: "Import Dramatify hours"
---

# Import Dramatify hours

Read docs/replace-dramatify.md first. Confirm the production, date, source columns and roster match. Keep the source unchanged. Run `node scripts/production.mjs import dramatify --file=<daily-hours.csv> --production=<ref> --date=<YYYY-MM-DD> --mapping=<mapping.json> --dry-run --json`. Review every warning and the row count, then repeat without --dry-run when the operator has asked to import. Missing people must be added from verified roster records first. Never assume an overnight wrap, break, absence or safety record. Run `/work-hours` and `/rest-gaps` afterwards. Whole-project migration needs separate mapping.
