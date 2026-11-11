# Bring daily working hours across from Dramatify

Dramatify documents a daily working-hours CSV export in [Work with time sheets & working hours](https://dramatify.com/how-to/work-with-time-sheets), checked 11 November 2026. Go to On Set, Check In / Out, select the day, choose Export in the edit menu and follow its export steps. Export each required date. Keep the untouched source files outside Git.

## What imports in one command

A daily file maps to people already on the roster and one production/date: presence, sickness or absence, check-in, check-out, and break minutes when supplied. The raw source row is retained alongside the imported record. It does not create a new person from an ambiguous name. Add verified roster records with `add person` before importing.

The help article documents export availability, not a stable CSV header contract. The example fixture is synthetic. Inspect the real export headers and use an explicit mapping when they differ. Do not describe this build as validated on a customer export.

Supported fields are `person`, or `first_name` plus `last_name`; `start`; `end`; `status`; and `break`. Example mapping of observed column names:

```json
{"person":"Name","start":"Check in","end":"Check out","status":"Status","break":"Break minutes"}
```

Save the mapping privately, then run:

```bash
node scripts/production.mjs import dramatify --file=imports/daily-hours.csv --production=P-101 --date=2026-11-10 --mapping=imports/mapping.json --dry-run --json
```

Review every mapped person, row count and warning, then repeat without --dry-run. Run `work-hours`, `rest-gaps` and `export` afterwards and reconcile against the source day before retiring anything.

Times accept HH:MM or whole minutes after midnight. A confirmed next-day wrap uses 24:00 or later. A wrap earlier than call is rejected, not silently guessed to be overnight. Present rows without wrap remain incomplete. Sickness and absence carry no worked time. A missing break column produces a warning and no deduction, not a claim that no break occurred. Accepted status words are present, worked, sick, sick day and absent. Other values fail for review.

The importer matches exact references, UUID prefixes or case-insensitive names. An ambiguous name lists every candidate. Every row is validated in one transaction. Any rejected row rolls back the file and its audit entries. A test run rolls back everything. Repeating a file updates the same production, person and date. Multiple shifts for the same person in that daily export require an agreed modelling change first.

## What requires separate migration

Dramatify's [integration page](https://dramatify.com/integrations) documents budget and timesheet exports and team imports. It is not evidence that a complete project export matches this schema. Schedules, script breakdowns, characters, budgets, access settings, attachments, messages and live rundown integrations do not come through this hours importer. Map those from the owner's source records and reconcile counts before making a switch. Enterprise DNA can do that work as part of a custom version.

## Your data back out

`node scripts/production.mjs export --out=exports/review-1` creates CSV files for all nonempty record types and snapshot.json with all tables and audit history. Existing files are never overwritten. This is a data export, not a tested full database backup/restore system. Use your database's backup mechanism for disaster recovery.
