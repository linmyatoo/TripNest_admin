---
marp: true
title: TripNest Admin
description: Flutter app for event organizers — architecture, features, and current state
paginate: true
---

<style>
section {
  font-size: 23px;
  padding: 50px 60px;
  justify-content: flex-start;
}
section h1 { font-size: 46px; margin: 0 0 12px; }
section h2 { font-size: 30px; margin: 0 0 18px; }
section table { font-size: 20px; }
section pre { font-size: 17px; line-height: 1.35; }
section li { margin-bottom: 6px; }
</style>

# TripNest Admin

The operator-side app for the TripNest event platform.

| | |
| --- | --- |
| Platform | Flutter, Material 3 |
| Targets | iOS, Android |
| Backend | REST — `tripnestbackend-v2.onrender.com` |
| Size | ~8.1k lines of Dart, 42 files |
| Tests | 33 unit tests, all passing |

---

## What it does

- **Events** — create and edit: title, mood, date, location, capacity, price
- **Photos** — auto-compressed on-device to ≤300 KB to fit the upload cap
- **Dashboard** — per-event revenue, bookings, tickets; pull-to-refresh
- **Sales** — gross revenue, 15% commission, net total, per-event table
- **Feedback** — reviews plus a server-side AI sentiment summary
- **Messaging** — per-event chat rooms with attendees, unread badge
- **Air quality** — live AQI in the header, daily local notification
- **Account** — auth, organizer profile, notification and security prefs

---

## How it is put together

```
lib/
├── main.dart              routes + Material 3 theme
├── src/app_shell.dart     5-tab IndexedStack shell
└── src/
    ├── core/services/     api_service, chat_service, session,
    │                      auth_storage, notification_*, air_quality
    ├── core/widgets/      shared form controls
    └── features/          auth · home · create · sales · reviews ·
                           messages · profile · onboarding · splash
```

**Feature-first.** No state-management package — pages are `StatefulWidget`s that call a service and `setState`.

**Services are the seam.** All HTTP lives in two files. Every method returns `{'success': bool, ...}` instead of throwing.

---

## Core functions, and how each one works

**Publish an event** — one page serves create and edit; passing an `eventId` flips it into edit mode and pre-fills from `GET /events/:id`. New events go up as a multipart POST so photos ride along with the fields.

**Fit the photos** — the server caps uploads, so the app compresses on-device before sending: resize to 1000px, then step JPEG quality 60 → 30, then shrink 25% at a time until each file is under 300 KB.

**Track the money** — `/dashboard/revenue` and `/dashboard/events` are fetched in parallel. The first fills the balance card, the second drives both the home feed cards and the sales table. The 15% commission is subtracted on the client.

**Talk to attendees** — one chat room per event. The thread polls `/chat/rooms/:id/messages` on a timer and posts new messages straight back.

**Watch the air** — WAQI's feed is read by IP geolocation, shown as a badge in the header, and pushed as a local notification once a day or whenever PM2.5 moves ≥0.5 µg/m³.

---

## The AI layer — how sentiment is produced

**The model runs on the backend, not in the app.** When attendees leave reviews, the server classifies each one and the app reads the results through two endpoints.

```
GET /sentiment/organizer/events/:id/summary   → the aggregate
    { totalReviews, analyzedCount,
      positiveCount, negativeCount, averageScore }

GET /sentiment/organizer/events/:id/reviews   → per-review verdicts
    sentiments: [ { reviewId, label, score, class, negativeSummary } ]
```

**The classification is binary** — every review comes back `POSITIVE` or `NEGATIVE`. There is no neutral bucket: a lukewarm review is forced to one side, and the **confidence score** is what tells the organizer how borderline that call was.

Negative reviews also carry a short **`negativeSummary`**: a generated phrase naming the actual complaint, not the raw comment.

`analyzedCount` is reported separately from `totalReviews`, so the organizer can see how much of the feedback the model has actually processed.

---

## What the organizer sees

The Reviews page fires four calls in parallel — the event, its raw reviews, the sentiment summary, and the per-review verdicts — then assembles one screen:

- **Coverage line** — "Reviews analyzed: 18 / 24 (negatives: 5 → 27.8%)"
- **Chips** — positive and negative counts with percentages, plus the average score
- **Issue list** — the app keeps only entries labelled `NEGATIVE` that carry a non-empty `negativeSummary`, and renders each as `Issue: <summary>`. Low-signal negatives are dropped rather than shown as noise
- **Star breakdown** — computed on the client from the raw review ratings, independent of the model

**Graceful when the model is silent.** No summary renders "Sentiment data unavailable"; no qualifying negatives renders "No issues reported". Neither blocks the rest of the page.
