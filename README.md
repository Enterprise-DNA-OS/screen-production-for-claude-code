# Screen Production for Claude Code

Your shoot days, scenes, cast, crew and working hours in a database you own. Built by Enterprise DNA. Works with Claude Code, Codex, OpenCode or Cursor.

| Do it yourself | We customise it | We run it for you |
|---|---|---|
| Free source under MIT. Install and run the demo. | Your production rules, fields and Dramatify data mapped across. | Installed, connected and operated through Omni by Enterprise DNA. |
| [Quick start](#quick-start) | [Get your version built](https://enterprisedna.co/omni/book/?offer=replace-software&utm_medium=readme&utm_campaign=dramatify) | [Setup fee, then a retainer](https://enterprisedna.co/omni/book/?offer=replace-software&utm_medium=readme-managed&utm_campaign=dramatify) |

## What this runs

The production office's morning call check, shoot week, cast day-out-of-days, crew conflict review, daily hours reconciliation and wrap report. It holds scenes in page eighths, units, location permission dates, day-specific risk controls and the history of record changes. Draft call sheets and daily production reports come from those same records.

[Dramatify's Professional plan](https://dramatify.com/subscription-plans/usd) lists US$36 per paid seat per month on monthly billing, or US$27 per seat per month billed annually, with five paid seats minimum. Read-only cast and crew are included free. A 50-editor monthly-billed scenario is US$21,600 per year. This is arithmetic from the published rate, not a customer invoice or a savings promise. Checked 11 November 2026.

The free base covers production-office records. It does not implement script editing, media storage, live broadcast rundowns, teleprompter control, payroll or a mobile crew portal. Dramatify has those broader workflows. Pick this base when the office records are the problem to solve. [Scope and operating limits](docs/why-no-front-end.md).

## Quick start

Requires Node.js 22 or newer. No database installation for the local demo.

```bash
git clone https://github.com/Enterprise-DNA-OS/screen-production-for-claude-code.git
cd screen-production-for-claude-code
npm install
npm test
npm run demo
npm run view
npm run docs
```

Open the folder in your coding agent and ask for `/attention`. The fictional demo has a wharf shoot tomorrow without renewed location permission, two cast gaps, a camera operator booked on two productions, an unshot insert, an unscheduled exterior, a missing wrap and a short recorded rest interval. Dates move with the day you seed the demo. Running the seed again preserves records.

For your own data, start with a separate empty DATA_DIR, run `npm run migrate`, then add production, location and roster records. Do not run demo against business records. To use a shared Postgres database, set DATABASE_URL in your local environment and run the migration. No credentials are stored in this repo. The database account needs owner permissions to run migrations. Tables have row-level security enabled without public policies, so anonymous web clients have no access. The CLI is for trusted production-office operators, not individual crew logins.

## The commands

| Command | Job |
|---|---|
| `/productions` | List the productions and their stage. |
| `/people` | List cast and crew before choosing a name. |
| `/locations` | Review location permissions and emergency plans. |
| `/shoot-week` | Plan the next seven days of shooting. |
| `/schedule` | Read every shoot day and compare scene minutes to the available day. |
| `/scenes` | Review scene order, page eighths, scheduling and shot status. |
| `/cast-gaps` | Find cast members without confirmed coverage for the full shoot day. |
| `/crew-clashes` | Find overlapping crew and cast bookings, including overnight calls. |
| `/location-clashes` | Find two units booked into the same location at overlapping times. |
| `/day-out-of-days` | Read the cast days, characters and booking state. |
| `/bookings` | Review tentative, confirmed and absent bookings. |
| `/risks` | Read day-specific risks, controls, owners and review dates. |
| `/work-hours` | Reconcile daily working-hours records and missing wrap times. |
| `/rest-gaps` | Review recorded rest intervals below the production policy. |
| `/wrap-report` | Compare completed scenes and page eighths against the planned work. |
| `/attention` | Show decisions in priority order, with the affected records. |
| `/compliance` | Check safety record completeness. Open docs/compliance.md before interpreting any rule. |
| `/notes` | Read production notes before drafting a response. |
| `/audit` | Read the most recent record changes with before/after evidence available in audit_events. |
| `/call-sheet` | Review one day's scenes, calls, risks and gaps |
| `/weekly-review` | The shoot week, attention list and progress in one review |
| `/add` `/update` `/log` | Enter and correct verified records with an audit trail |
| `/schedule-scene` `/mark-shot` | Put a scene on a matching day or record that it was shot |
| `/draft-call-sheet` `/draft-weekly-review` | Save branded HTML in drafts/, never send |
| `/import` `/export` | Bring daily Dramatify hours in, or export all records |
| `/customise` `/new-view` | Change your fields, policy or read-only reports |

Every CLI route supports --json. Names match case-insensitively and ID prefixes work. An ambiguous name lists candidates and exits 1. Exact references always win. Run `npm run production -- help` for syntax. There are no email, calendar or publishing integrations.

## Paperwork and views

`npm run docs` renders one draft call sheet, daily production report and risk register per shoot day. `npm run view` renders the shoot week, cast and crew readiness, and working-hours review. Change the business name, colours and logo in brand.json. Open the generated HTML locally or print it to PDF. No server runs and none of the files are published. OUTPUT_DIR redirects generated output for tests.

## Instead of Dramatify

[The switch guide](docs/replace-dramatify.md) explains the supported daily working-hours export and the columns to map. Import in one command after matching the roster and the export headers:

```bash
node scripts/production.mjs import dramatify --file=imports/hours.csv --production=P-101 --date=2026-11-10 --mapping=imports/mapping.json --dry-run
```

Repeat without --dry-run to apply. The whole file succeeds or nothing changes. Re-importing updates the same person, production and date. This is not a complete Dramatify project restore. Scripts, breakdowns, schedules, budgets and attachments require their own mapping and review. A documented vendor export is available, but a real customer export has not been tested in this build. Test fixtures are synthetic and labelled accordingly.

## Ten questions to bring to your own records

These are implemented today. This is not a claim that Dramatify cannot answer any of them through its own reports or integrations.

1. Which scenes have cast without confirmed cover for the whole day? (`/cast-gaps`)
2. Who is double-booked across our productions, including overnight work? (`/crew-clashes`)
3. Which locations have overlapping unit bookings? (`/location-clashes`)
4. Which shoot days are missing safety contacts or daily briefing records? (`/compliance`)
5. Which permissions expire before the planned shoot? (`/compliance`)
6. Which risk controls are still open or due for review? (`/risks`)
7. Which scenes missed their shoot date and which have no date? (`/attention`)
8. How many page eighths have we shot on each production? (`/wrap-report`)
9. Which daily hours are missing a wrap or exceed our own long-day policy? (`/work-hours`)
10. Who has less than our agreed rest interval between recorded shifts? (`/rest-gaps`)

## Your first hour: ten things to ask for

1. Show tomorrow's cast gaps and read each person's booking.
2. Show the camera operator's two clashing days.
3. Read the wharf permission date and the missing emergency plan.
4. Add the renewed permission from the document I supply.
5. Record the production safety adviser's agreed wharf controls and review date.
6. Confirm the cast booking after I provide the acceptance.
7. Move the unshot exterior to a matching location and day.
8. Correct yesterday's wrap from the approved working-hours record.
9. Draft tomorrow's call sheet with every remaining issue visible.
10. Add a weather-cover field and a view of scenes that have no cover plan.

## Safety and time records

Read [docs/compliance.md](docs/compliance.md). Checks identify missing records and apply explicit office policies. They do not approve a shoot or certify legal compliance. Day-specific call-sheet safety information follows ScreenSafe guidance. Risk review checks are an implementation of a recordkeeping workflow informed by WorkSafe guidance. The default twelve-hour rest and long-day thresholds are demo office policies, not law or an interpretation of an award. No payroll, wage calculation or payments exist here.

All productions use one office's local calendar clock. Durations are wall-clock minutes, not timezone or daylight-saving adjusted payroll hours. For cross-timezone units, change the model to timezone-aware timestamps before importing. Keep private cast and crew records in the database and generated output, which are excluded from Git. Generated exports are sensitive. Test restore using snapshot.json before relying on exports as a backup.

## Verification

`npm test` uses a disposable PGlite database, exercises every CLI route, asserts domain constraints and import rollback, checks HTML escaping, and renders all documents and views. The CI workflow runs Node 22 on Windows and Linux and also verifies the migration, seed and core reads on PostgreSQL. See the workflow results for which platforms have actually completed.

## Installed and run for you

Enterprise DNA maps your records, adapts the checks, adds a team screen or a different stack if needed, and operates your version through **Omni by Enterprise DNA**. One setup fee, then a retainer. [Spend 30 minutes with Sam](https://enterprisedna.co/omni/book/?offer=replace-software&utm_medium=readme-closing&utm_campaign=dramatify).

MIT licence. Dramatify is a separate product. This project is not affiliated with its vendor.
