# audit

Read the most recent record changes with before/after evidence available in audit_events.

Run `node scripts/production.mjs audit --json`. Present the result in plain words with record references. State when there are no matches. Never infer missing evidence. Read `card <entity> <ref>` before changing a record.
