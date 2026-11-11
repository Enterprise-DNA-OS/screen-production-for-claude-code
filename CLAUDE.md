# Screen Production for Claude Code

Read README.md and docs/compliance.md. This folder runs a production office's records, not a crew portal or a broadcast system. All demo names and addresses are fictional.

## Operator context

Business: fill in your production company. Operator: fill in the person accountable for the records. Calendar clock: one local production-office clock. Confirm the clock before importing another unit's hours.

## Routing

- `/productions`: read `.claude/commands/productions.md`.
- `/people`: read `.claude/commands/people.md`.
- `/locations`: read `.claude/commands/locations.md`.
- `/shoot-week`: read `.claude/commands/shoot-week.md`.
- `/schedule`: read `.claude/commands/schedule.md`.
- `/scenes`: read `.claude/commands/scenes.md`.
- `/cast-gaps`: read `.claude/commands/cast-gaps.md`.
- `/crew-clashes`: read `.claude/commands/crew-clashes.md`.
- `/location-clashes`: read `.claude/commands/location-clashes.md`.
- `/day-out-of-days`: read `.claude/commands/day-out-of-days.md`.
- `/bookings`: read `.claude/commands/bookings.md`.
- `/risks`: read `.claude/commands/risks.md`.
- `/work-hours`: read `.claude/commands/work-hours.md`.
- `/rest-gaps`: read `.claude/commands/rest-gaps.md`.
- `/wrap-report`: read `.claude/commands/wrap-report.md`.
- `/attention`: read `.claude/commands/attention.md`.
- `/compliance`: read `.claude/commands/compliance.md`.
- `/notes`: read `.claude/commands/notes.md`.
- `/audit`: read `.claude/commands/audit.md`.
- `/call-sheet`: read `.claude/commands/call-sheet.md`.
- `/weekly-review`: read `.claude/commands/weekly-review.md`.
- `/add`: read `.claude/commands/add.md`.
- `/update`: read `.claude/commands/update.md`.
- `/schedule-scene`: read `.claude/commands/schedule-scene.md`.
- `/mark-shot`: read `.claude/commands/mark-shot.md`.
- `/log`: read `.claude/commands/log.md`.
- `/draft-call-sheet`: read `.claude/commands/draft-call-sheet.md`.
- `/draft-weekly-review`: read `.claude/commands/draft-weekly-review.md`.
- `/import`: read `.claude/commands/import.md`.
- `/export`: read `.claude/commands/export.md`.
- `/customise`: read `.claude/commands/customise.md`.
- `/new-view`: read `.claude/commands/new-view.md`.

## Hard rules

- Start answers from `node scripts/production.mjs <command> --json`, never memory.
- Read the record before changing it. An ambiguous name requires a selection.
- Never invent a permit, risk assessment, control, signature, acceptance, hour or completion.
- Save drafts locally. Never send, publish, delete or alter an external system without the operator's explicit instruction.
- Treat safety checks as record completeness only. The production manager and safety adviser decide whether work proceeds.
- Never treat the demo rest threshold as law, award interpretation or payroll.
- Add numbered migrations for changes. Do not edit applied migrations. Run npm test before committing.
- Keep database files, private exports, credentials and drafts out of Git.
- The database owner is a trusted operator. This is not a role-separated crew service. Put individual access controls in place before wider sharing.

## Shape

scripts/production.mjs is the one CLI. supabase/migrations holds portable Postgres SQL. scripts/lib/db.mjs uses Postgres when DATABASE_URL is set and local PGlite otherwise. `npm run view` and `npm run docs` produce static read-only HTML. All updates are audited. A slash command is a recipe, not an independent implementation.

Built and run for businesses by Enterprise DNA through Omni by Enterprise DNA.
