---
name: garmin-coaching
description: "Which garmin-mcp tool to use for which coaching question: daily readiness, sleep and recovery, training review, weight trend, nutrition, weekly check-in."
version: 1.0.0
author: dave
license: MIT
metadata:
  hermes:
    tags: [garmin, fitness, weight-loss, mcp]
---

# Coaching with Garmin data via garmin-mcp

All tools are prefixed `garmin-mcp_`. Dates are `YYYY-MM-DD`; range tools default to the 7 days ending today and split longer ranges themselves. The API is read-only.

| Question | Tool |
|----------|------|
| How am I doing today / can I train hard | `garmin_get_day(date)`: summary, sleep, HRV, Body Battery, stress and activities in one call |
| Sleep last night | `garmin_get_sleep(date)`; trend `garmin_get_sleep_summaries` |
| Recovery | `garmin_get_hrv_summaries` (status against baseline), `garmin_get_body_battery`, `garmin_get_heart_rate` (resting HR, 7-day average), `garmin_get_stress` |
| Weight trend | `garmin_get_weight(start, end)` for daily summaries and the range average; `include_all` for every weigh-in; target from `garmin_get_weight_goals` |
| Food and drink | `garmin_get_food_log` (only filled when Dave logs in Garmin Connect), `garmin_get_hydration` |
| Daily movement and calories burned | `garmin_get_steps`, `garmin_get_daily_summaries` |
| What did I train | `garmin_search_activities` (filter by type and dates), then `garmin_get_activity(id)` for splits; `garmin_get_activity_workouts` for the planned workout |
| Training zones | `garmin_get_heart_rate_zones` |
| Long-term fitness | `garmin_get_fitness_age`, `garmin_get_daily_summaries` over months |
| Units and preferences | `garmin_get_profile` |

## Rules of thumb

- Units come back raw: weight in grams, distance in meters, duration in seconds. Convert before reporting (kg, km, min/km or km/h, h:mm).
- `{"no_data": ...}` means Garmin has nothing for that date (today's HRV before sleeping, a metric the watch does not record). Report it as missing; do not estimate.
- Weight: compare 7-day averages, never two single weigh-ins. A plateau is 3+ weeks without a change in the average.
- Leave `include_samples`/`chunks` off unless the question is about the course of one day; they make responses very large.
- Do not call `garmin_download_activity`; the file lands in the MCP pod, not with Dave.

## Weekly check-in

1. `garmin_get_weight` for the last 28 days: this week's average against last week's and the goal.
2. `garmin_search_activities` for the last 7 days: sessions, total time, split by type; compare with the week before.
3. `garmin_get_sleep_summaries` and `garmin_get_hrv_summaries` for the last 7 days: average sleep duration and score, HRV status.
4. `garmin_get_steps` for the last 7 days: average against the goal.
5. Report: weight trend, training, recovery, one thing that went well, one adjustment, and the plan for the coming week.
