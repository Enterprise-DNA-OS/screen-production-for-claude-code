---
description: "Export all records"
---

# Export all records

Run `node scripts/production.mjs export --json`. The returned folder contains CSV for each nonempty entity and a full JSON snapshot including audit history. Keep it private and test recovery before relying on it as a backup. Existing files are never overwritten. There is no automatic restore command.
