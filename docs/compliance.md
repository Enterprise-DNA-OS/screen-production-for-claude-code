# Safety record checks and office policies

Checked 11 November 2026. This is a production recordkeeping aid. It does not certify safety, decide whether an activity is lawful, or replace a competent production safety adviser. Australian productions need their own jurisdiction-specific review. The supplied source guidance is from New Zealand.

| Check | What the code checks | Basis and limit |
|---|---|---|
| CALL-SHEET | Each shoot day has a safety contact, assessment reference and day-specific briefing | [ScreenSafe call-sheet checklist](https://www.screensafe.co.nz/template-categories/h-s-workplace-forms) calls for safety information specific to the day and activity. Nonempty text only proves a record exists, not that controls are adequate. |
| LOCATION | Permission date covers the day and an emergency plan reference exists | [ScreenSafe guidelines](https://www.screensafe.co.nz/guideline-categories/all-guidelines) cover location safety and daily information. These particular date and field checks are office policy, not a statutory permission rule. |
| RISK-REVIEW | Open risks, missing controls/owners and reviews older than the shoot day or today are flagged | [WorkSafe risk guidance](https://www.worksafe.govt.nz/managing-health-and-safety/managing-risks/how-to-manage-work-risks/) describes identifying, assessing, controlling and reviewing work risks. The responsible adviser sets the review date. No fixed legal interval is assumed. |
| Rest interval | Consecutive complete working-hours records less than settings.rest_minutes apart | Demo office policy: 720 minutes. Consult the applicable engagement agreement and safety adviser. This value is not a legal rule or an award calculator. |
| Long day | Recorded worked minutes exceed settings.long_day_minutes | Demo office policy: 720 minutes after recorded breaks. Missing breaks generate an import warning and need review. |

`node scripts/production.mjs compliance --json` returns source URLs with each safety record flag. `/rest-gaps` and `/work-hours` report the separate office-policy flags. Every call-sheet draft keeps outstanding checks visible.

The database refuses to mark a risk controlled without a control and owner. It refuses a cast assignment to a crew-only record, a scene on another production's day, and a future scene marked shot. Those are data checks, not safety approvals.

Each person can have one daily hours record per production. All units use one local office clock. Overnight wrap is explicit, for example 26:00 means 02:00 next day. Daylight-saving elapsed time and different timezone units need a timestamp-based extension before use. Missing wrap times remain unknown. Nothing here calculates wages, penalties or entitlements.
