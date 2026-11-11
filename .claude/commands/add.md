---
description: "Add a production record"
---

# Add a production record

Read `node scripts/production.mjs help` and list the matching entity first. Use `add <entity> --ref=<unique-ref> --field=value`. Supported entities: production, location, person, day, scene, cast, booking, risk, hours, note. Relationship options accept references or an unambiguous name: `--production`, `--location`, `--day`, `--person`, `--scene`. Use ISO dates, whole minutes or HH:MM for start/end, and a wrap of 24:00 or later for confirmed overnight work. Never create a safety approval, permit, absence or time from a guess. Read the new card back.

Example: `node scripts/production.mjs add person --ref=W-105 --name="Robin Vale" --department=Lighting`
