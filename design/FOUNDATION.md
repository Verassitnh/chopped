# Chopped foundation — API reference

Everything screen engineers need. Read `design/SPEC.md` first. Project/targets are still named **Pocus**.

## File map

| Path | What | Targets |
|---|---|---|
| `Shared/Fonts/*.ttf` | Geist 400/500/600/700, Geist Mono 400/500/600/700, Geist Pixel Square | app + widgets |
| `Shared/DesignSystem/Theme.swift` | `Color(hex:)`, `CH` colour tokens | app + widgets |
| `Shared/DesignSystem/Fonts.swift` | `GeistWeight`, `GeistFont`, `Font.geist*`, `.geist*()` text-style modifiers | app + widgets |
| `Shared/DesignSystem/Glyphs.swift` | `Glyph`, `GlyphView`, `GlyphShape`, SVG path parser | app + widgets |
| `Shared/DesignSystem/TrackerPalette.swift` | `TrackerColor` (accent + tint + key), `GoalPeriod` | app + widgets |
| `Shared/DesignSystem/Components.swift` | `IconTile`, `PlayButton`, `StopButton`, `SegmentStrip`, `TrackerBezel`, `SectionLabel`, `GlassCircleButton`, `CircleIconButton`, `PressScaleStyle`, `Motion` | app + widgets |
| `Shared/DesignSystem/Format.swift` | `Fmt` number formats, `Calendar.chopped` (Monday weeks) | app + widgets |
| `Shared/AppClock.swift` | `AppClock.now` (freezable), `Ticker` | app + widgets |
| `Shared/PocusActivityAttributes.swift` | Live Activity state (+ icon, periodBase, goalMinutes, period) | app + widgets |
| `Pocus/Store.swift` | `Activity`, `WorkSession`, `Store` + stats helpers | app |
| `Pocus/Database.swift` | SQLite wrapper + migrations (`PRAGMA user_version`) | app |
| `Pocus/AppRouter.swift` | `AppRouter`, `AppTab` | app |
| `Pocus/RootView.swift` | Tabs + glass tab bar + sheets (`GlassTabBar`) | app |
| `Pocus/Screens/HomeView.swift` | 01 Home — **placeholder** (font specimen) | app |
| `Pocus/Screens/TrackerDetailView.swift` | 02 Detail sheet — placeholder, `init(activityID:)` | app |
| `Pocus/Screens/StatsView.swift` | 03 Stats — placeholder | app |
| `Pocus/Screens/TrackerStatsView.swift` | 04 Tracker stats — placeholder, `init(activityID:)` | app |
| `Pocus/Screens/NewTrackerView.swift` | 05 New tracker sheet — placeholder | app |
| `Pocus/Legacy/SessionEditors.swift` | Old unstyled `SessionsEditor`, `NewSessionSheet` (fix times / add time logic) — restyle or replace | app |
| `Pocus/QC/QC.swift`, `Pocus/QC/DemoData.swift` | QC harness + demo data | app |
| `Pocus-Info.plist`, `PocusWidgets-Info.plist` | UIAppFonts (merged with generated Info.plist keys) | — |

`Shared/` is a synchronized group in **both** targets (verified in project.pbxproj), so new files there compile into the app and the widget extension. Don't put `Store`/`Activity` types in Shared code: they're app-only.

## Fonts

PostScript names (verified at runtime: `GeistFont.missing == []` on simulator and device):

| Family | Names |
|---|---|
| Geist | `Geist-Regular` `Geist-Medium` `Geist-SemiBold` `Geist-Bold` |
| Geist Mono | `GeistMono-Regular` `GeistMono-Medium` `GeistMono-SemiBold` `GeistMono-Bold` |
| Geist Pixel | `GeistPixel-Square` (Square variant, which is the ELSH=0 static. Converted from woff2 with fonttools.) |

CSS weight 650 (e.g. "New tracker" title) → use `.semibold`. There's no 650 static.

```swift
Text("Deep Work").geist(20, .semibold, tracking: -0.015, lineHeight: 24)
Text("5:24").geistMono(26, .medium, tracking: -0.05, lineHeight: 30)   // mono default weight = .medium
Text("00:50:01").geistPixel(62)                                         // lineHeight defaults to size (Paper 62/62)
Text("x").font(.geist(13, .medium))   // Font-only variants: Font.geist / .geistMono / .geistPixel
```

- `tracking` is in **em**, exactly as Paper shows it. The modifier multiplies it by the size.
- `lineHeight` is the CSS line-height in pt. The modifier adds half-leading above and below (negative if tighter than the font, like CSS), plus `lineSpacing` for multi-line text. Omit it to use the font's natural height.
- Sizes are `fixedSize`, so they don't scale with Dynamic Type. This keeps the layout pixel-matched.
- Fonts are only for: Geist for names/labels/UI, Mono for every number, Pixel ONLY for the big running timer and hero totals.

## Colours — `CH`

| Token | Hex | Use |
|---|---|---|
| `CH.bg` | #0C0C0E | app background |
| `CH.sheet` | #141416 | sheets |
| `CH.raised` | #1C1C1E | raised rows, circle buttons, segmented control |
| `CH.text` | #F2F2F7 | primary text |
| `CH.textSecondary` | #8E8E93 | secondary |
| `CH.textTertiary` | #6C6C70 | section labels |
| `CH.textMuted` | #AEAEB2 | section values / subtitles |
| `CH.past` / `CH.pastMid` / `CH.pastLight` | #26262A / #3A3A3E / #48484C | past bars/cells (accent restraint) |
| `CH.up` | #39D353 | up deltas, heatmap green |
| `CH.destructive` | #EF6B6B | delete |
| `CH.onAccent` | black | text/glyphs on bright blocks |
| `CH.onAccentSecondary` | black @ 0.62 (#0000009E) | meta text on bright blocks |
| `CH.iconTileFill` | black @ 0.13 (#00000021) | icon tile on bright blocks |
| `CH.glassFill` / `glassStroke` / `glassHighlight` | white @ .09 / .14 / .18 | glass buttons |

`Color(hex:)` accepts `#RRGGBB` or `#RRGGBBAA` (CSS order).

## Tracker palette — `TrackerColor`

`TrackerColor(key, accentHex, tintHex)` with `.accent`, `.tint`, `.faint` (accent @ 0.2 = unfilled ticks).

| static | accent | tint |
|---|---|---|
| `.blue` (Deep Work) | #4A8BE5 | #172335 |
| `.orange` (Meetings) | #F7A23A | #362716 |
| `.teal` (Exercise) | #1DB3A6 | #0F2A29 |
| `.purple` (Email) | #9D68F0 | #261D37 |
| `.red` (Reading) | #EF6B6B | #351D1F |
| `.pink` | #F07EB8 | #3A1C2C |
| `.green` | #7CCB8E | derived (not in the designs) |
| `.yellow` | #E9C95A | derived (not in the designs) |

- `TrackerColor.picker` is the New Tracker order: blue, teal, green, yellow, orange, red, pink, purple.
- `TrackerColor.forHex(activity.colorHex)` gives you the palette entry. Unknown hexes get a derived tint (~19% accent over #0C0C0E).
- `activity.color` is a shortcut for that lookup.

`GoalPeriod` (`.day .week .month .year`) has:
- `.adjective` → "Daily"/"Weekly"/…
- `.segmentLabel` → "DAY"…
- `.title` → "Day"…
- `.calendarComponent`

## Glyphs

`Glyph` cases:
- **Tracker icons:** `target people pulse mail book music`. `Glyph.trackerIcons` lists them in picker order, and `Glyph.tracker(key)` looks one up (falls back to `.target`).
- **UI glyphs:** `clock bars plus close check minus chevronRight chevronLeft arrowUp arrowRight play`.

```swift
GlyphView(.target, size: 18, color: .black)   // size = SVG box width; stroke scales (2 in 24 → 1.5pt at 18)
GlyphShape(glyph: .book)                      // raw Shape (aspect-fit) for custom effects
```

The paths are copied verbatim from `design/gen/c3/gen.py` ICONS, plus `music` from `f/gen.py`. Rendering is 24×24 viewBox, stroke 2, round caps/joins. The target centre dot is filled. `plus`/`close`/`check`/`minus` use their Paper viewBoxes and stroke widths. `play` is filled.

## Components (exact Paper values baked in as defaults)

```swift
IconTile(glyph: a.glyph)                                  // 36pt r11 glyph18, black on black@13% (idle card)
IconTile(glyph: a.glyph, size: 30, radius: 9, glyphSize: 16)   // running card
//   other sizes: live activity 24/7/13 · widgets 26/8/14 · DI compact 22/7/12 (foreground: accent, background: accent.opacity(0.2)) · DI expanded 40/12/20

PlayButton { store.clockIn(a) }                           // 40pt black circle, white triangle. size:, background:, foreground:
StopButton(accent: a.color.accent) { store.stop() }       // 52pt black circle, accent square size*0.3 r4
StopButton(size: 52, accent: .black, background: accent)  // DI expanded (inverted)
// action: nil → plain view (for widgets wrapping in Button(intent:)). With action → Button + press scale 0.96.

SegmentStrip(fraction: store.progress(for: a, now: now), accent: a.color.accent)
//   count 20, height 6, gap 3, radius 2, unfilled accent@0.2; widgets: count 12, height 5; DI: unfilled CH.raised
//   filled = round(fraction*count); ticks stagger-animate on change (off with Reduce Motion / animated: false)

TrackerBezel(color: a.color) {                 // tinted outer r26, padding 5/5/12, gap 10; bright inner r21
    rowContent.padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 12))   // idle (running: 14/16/14/14)
} footer: {
    SegmentStrip(...)                          // footer inset leading 19 / trailing 17 automatically
}
TrackerBezel(color: a.color) { ... }           // no footer → uniform 5pt border (lock-screen live activity)

SectionLabel("Hours by tracker", value: "4/5 on pace")   // mono 11/14 caps 0.08em #6C6C70 · value mono 12/16 -0.01em #AEAEB2, gap 12
SectionLabel(title: "Goals") { CustomTrailingView() }
SectionLabelText("…") / SectionValueText("…")           // the two text styles alone

GlassCircleButton(glyph: .plus) { router.showingNewTracker = true }   // 44pt glass "+" (home header)
CircleIconButton(glyph: .close, background: .white.opacity(0.08)) { dismiss() }   // 44pt solid circle
GlassTabBar(selection:)    // in RootView; 188×62 glass capsule, 22pt from the bottom; hidden while a tracker-stats page is pushed

.buttonStyle(.pressScale)  // 0.96 press scale (respects Reduce Motion)
Motion.spring              // spring(response 0.35, damping 0.85) for start/stop
Motion.grow                // easeOut 0.45 for bars growing in
```

## Formatting — `Fmt` (input: seconds, floors to the unit shown)

| Function | Example |
|---|---|
| `Fmt.hm(t)` | "5:24", "96:10", "22:49", goal "25:00" |
| `Fmt.hms(t)` | "00:50:01" (Pixel running timer) |
| `Fmt.compact(t)` | "50:01" (<1h), "1:50:01" (DI compact / widgets) |
| `Fmt.signedHM(t)` | "+3:19", "-0:46" |
| `Fmt.words(t)` | "2h 11m", "45m", "3h" |
| `Fmt.goal(minutes:)` | "25h", "45m", "1h 30m" |
| `Fmt.percent(0.913)` | "91%" |
| `Fmt.signedPercent(v, vs: base)` | "+13%" (nil if base 0) |
| `Fmt.time(date)` | "20:06" (24h) |

`Calendar.chopped` is the user's calendar with **Monday-first weeks** ("resets Mon"). Every Store bucket uses it.

## Time — `AppClock`

Never call `Date()` or `.now` in app code. Use `AppClock.now`, which is frozen in `-QCDemo`.

```swift
Ticker(every: 1) { now in Text(Fmt.hms(now.timeIntervalSince(session.start))) }
```

`Ticker` wraps `TimelineView`. When the clock is frozen it renders once with the frozen time. In widgets/Live Activities, use `Text(timerInterval:)` for live counting.

## Data model

```swift
struct Activity { id, name, colorHex, position,
                  icon: String /* Glyph key */, goalMinutes: Int, period: GoalPeriod
                  color: TrackerColor, glyph: Glyph, goal: TimeInterval, goalLine: "Weekly · 25h goal" }
struct WorkSession { id, activityID, start, end?; isRunning; duration(in:now:); duration(now:) }
```

**SQLite migration v1:** non-destructive and idempotent, tracked with `PRAGMA user_version`. It adds `icon TEXT DEFAULT 'target'`, `goal_minutes INTEGER DEFAULT 600` and `period TEXT DEFAULT 'week'`. It also maps the original default trackers by name to their Chopped icon/goal, and maps the old Pocus palette hexes to the Chopped accents.

**Default trackers.** First launch seeds these. Existing installs that already had "Deep Work/Meetings/Email/Exercise" get their goals via the migration. Reading is only seeded on fresh installs.

| Tracker | Colour | Icon | Goal | Period |
|---|---|---|---|---|
| Deep Work | blue | target | 25h (1500 min) | week |
| Meetings | orange | people | 8h (480) | week |
| Exercise | teal | pulse | 45m | day |
| Email | purple | mail | 30m | day |
| Reading | red | book | 150h (9000) | year |

## Store API (`@Environment(Store.self)`)

All methods take `now` explicitly. Pass the `Ticker` date.

| Method | Returns / use |
|---|---|
| `activities`, `sessions` (newest first), `activeSession`, `activeActivity`, `activity(id)`, `isRunning(id)` | basics |
| `clockIn(activity)`, `stop(at:)` | start/stop (uses AppClock) |
| `addActivity(name:colorHex:icon:goalMinutes:period:) -> Int64`, `updateActivity`, `deleteActivity`, `moveActivities` | CRUD |
| `addSession(activityID:start:end:)`, `updateSession`, `deleteSession`, `importSessions([...])` | entries |
| `Store.week(containing:)`, `Store.day(containing:)`, `interval(period, containing:)`, `intervals(period, count:, endingAt:)`, `days(in:)` | buckets (oldest first) |
| `total(for: id?, in: interval, now:)` | seconds (nil id = all trackers) |
| `currentPeriod(for:now:)`, `periodTotal(for:now:)` | home card value (Reading = year-to-date 96:10) |
| `progress(for:now:)` | periodTotal/goal (may exceed 1) → strip fraction |
| `remaining(for:now:)` | "2h 11m left" |
| `isOnPace(_:now:)` | logged ≥ goal × (whole days finished ÷ days in period) ("x/5 on pace"). Today only counts once it's over, so daily goals are on pace until the day ends |
| `dailyTotals(for: id?, in:now:) -> [PeriodTotal]` | per-day totals |
| `thisWeekDays(for: id?, now:)` | Mon…Sun of this week (day bars) |
| `periodTotals(for: id?, period: .week, count: 8, now:)` | 8-week trend, last = current |
| `weekComparison(for: id?, now:) -> (current, last)` | "↑ 4:15 +13% vs last week" |
| `goalHistory(for:count:now:) -> [GoalResult]` | per period: seconds, goal, fraction, hit, isCurrent ("Goal hit · 12 weeks") |
| `streak(for:lookback:now:) -> Streak` | `current`, `best`, `runs: [DateInterval]` (streak timeline). Current ignores an unfinished, not-yet-hit current period |
| `dailyShare(of:on:)` | goal pro-rated per day |
| `dayScores(days: 84, now:) -> [DayScore]` | heatmap: min(1, all time logged that day ÷ Σ dailyShare of every goal); `isPerfect` (= full day's worth); `DayScore.level`: 0 <1/8 · 1 <1/4 · 2 <1 · 3 perfect |
| `entriesByDay(for:in:now:) -> [DayEntries]` | detail "Entries" grouped by day (newest first), with day total |
| `sessionStats(for:in:now:) -> SessionStats` | count, average, longest, bestDay |

Performance: everything is in memory (sessions are loaded once per mutation). `dailyTotals` is a single pass. Compute once per `Ticker` tick rather than per row where you can.

## Navigation — `AppRouter` (`@Environment(AppRouter.self)`)

- `tab: AppTab` (`.track` / `.stats`)
- `detailActivityID: Int64?` presents the 02 sheet
- `showingNewTracker` presents the 05 sheet
- `statsPath: [Int64]` is the Stats `NavigationStack` path (push an id to show 04)
- Helpers: `openDetail(id)`, `openTrackerStats(id)` (switches to Stats and pushes), `open(AppScreen, store:)`

`RootView` owns the sheets and the stack, and hides the nav bar. Screens draw their own headers. Each screen file can be replaced independently. Keep the type names and initialisers: `HomeView()`, `TrackerDetailView(activityID:)`, `StatsView()`, `TrackerStatsView(activityID:)`, `NewTrackerView()`.

## QC harness

Launch args:
- `-QCScreen <home|detail|stats|trackerStats|newTracker>` opens that screen. detail and trackerStats target the running tracker, which is Deep Work in demo.
- `-QCDemo` uses an in-memory DB with demo data and freezes now at **Fri 23 Oct 2026 20:56:01 local**. Live Activities are off in this mode.
- `-QCSnapshot` writes `Documents/qc-<screen>.png` at native scale. It waits 1.5s, or 2.2s for detail/newTracker/trackerStats.

At launch the app logs `QC demo=… missingFonts=[]` and, in demo mode, a `QC demo summary:` block with every computed number.

### Simulator (iPhone 18 Pro Max, 440pt — matches the artboards)
```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
SIM=73276883-8B7C-4FD1-A8E0-30F60ADA31DC; DD=/tmp/dd-<you>
xcodebuild -project Pocus.xcodeproj -scheme Pocus -destination "id=$SIM" -derivedDataPath $DD build
xcrun simctl boot $SIM 2>/dev/null; xcrun simctl install $SIM $DD/Build/Products/Debug-iphonesimulator/Pocus.app
xcrun simctl terminate $SIM com.jackson.Pocus; xcrun simctl launch $SIM com.jackson.Pocus -QCDemo -QCScreen home -QCSnapshot
sleep 4; cp "$(xcrun simctl get_app_container $SIM com.jackson.Pocus data)/Documents/qc-home.png" /tmp/qc-home.png
xcrun simctl spawn $SIM log show --last 1m --style compact --predicate 'eventMessage CONTAINS "QC"'   # logs
```
Don't use `simctl launch --console-pty … &`. The backgrounded process gets killed with the shell before the snapshot is written.

### Device (iPhone 15 Pro Max, 430pt — layouts must be fluid)
```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
U=00008130-000949181A06001C; DD=/tmp/dd-<you>
xcodebuild -project Pocus.xcodeproj -scheme Pocus -destination "id=$U" -derivedDataPath $DD -allowProvisioningUpdates build
xcrun devicectl device install app --device $U $DD/Build/Products/Debug-iphoneos/Pocus.app
xcrun devicectl device process launch --device $U --terminate-existing com.jackson.Pocus -- -QCDemo -QCScreen home -QCSnapshot
sleep 6; xcrun devicectl device copy from --device $U --domain-type appDataContainer --domain-identifier com.jackson.Pocus \
  --source Documents/qc-home.png --destination /tmp/qc-home-device.png
```
The first launch right after an install sometimes fails with "Application failed preflight checks (FBSOpenApplicationErrorDomain 3)". Run the launch command again.

## Demo data (`-QCDemo`, `DemoData.makeStore()`)

The week runs Mon 19 – Sun 25 Oct 2026. Deep Work has been running since 20:06:00, so the timer reads **00:50:01**.
History covers 12 calendar weeks (Mon 3 Aug →) plus Reading Saturdays from 3 Jan (year total 96:10).
`DemoData.days` is a per-day minutes table generated by `design/gen/demo/gen.py`. That script holds the design
values read from Paper (lane arrays, heatmap levels, bar heights). Run `python3 check.py` in that folder to print
every derived metric next to the design value. Edit `gen.py`, then paste its rows into `DemoData.swift`.

| | This week | Last week | Card value |
|---|---|---|---|
| Deep Work | 22:49 (M 4:12 · T 5:06 · W 3:48 · T 6:00 · F 3:43) | 19:30 | 22:49 of 25h, 91% |
| Meetings | 5:24 | 6:10 | 5:24 / 8h, 68% |
| Exercise | 3:45 (today 0:30) | 3:00 | 0:30 / 45m, 67%, **6-day streak** |
| Email | 2:59 (today 0:27) | 2:50 | 0:27 / 30m, 90% (streak 4d, hidden on Home, which needs ≥5) |
| Reading | 1:30 | 0:42 | 96:10 year-to-date / 150h, 64% |
| **Total** | **36:27** | **32:12** | ↑ 4:15, +13% |

**Matches the designs exactly:**
- Home.
- Stats: hero, split bars, table, "4/5 on pace", 8-week trend (avg 29:42), goal-card % and captions, Exercise
  "6d", "15 perfect days", 21d / 17d lane runs, legend order.
- Tracker stats (04): hero, the 8 bars (67 73 68 82 76 85 78 91 % of 25h), "+17% vs avg", day bars,
  12 sessions · 1:54 · 3:45 · THU.
- Detail: day bars and the Thursday entries.

**Metric definitions chosen so the designs hold** (all sensible for real use):
- **On pace** is judged against whole days already finished. DW 22:49 ≥ 25h×4/7 and Meetings 5:24 ≥ 8h×4/7.
  Exercise and Email are on pace until today ends. Reading 96:10 < 150h×295/365 is behind. That gives 4/5.
- **Heatmap / perfect day** = total time logged that day ≥ the day's share of all goals (Σ dailyShare ≈ 6:22).
  Levels: <1/8, <1/4, <1, perfect.
- **Streak lanes** share one axis, the 12 calendar weeks ending this Sunday (84 day slots). Daily lanes run
  from that Monday to today, and weekly lanes get one slot per week, like Paper. Order: daily trackers first,
  then tracker order.
- **Goal % legend:** the 3 trackers with the most time this week, ordered by this week's share of their weekly
  goal (DW 91%, Exercise 71%, Meetings 68%). The best line is drawn on top.
- **04 "vs avg"** uses the same 8-week average as Stats (this week included).
- **Δ header:** Geist Mono has no Δ. It's drawn in SF 9 medium with 0.72pt trailing tracking, the same
  fallback Paper uses, and is pixel-aligned with the ref.

### Unavoidable deviations

The designs contradict each other, so these values are computed from the data, not faked:
- **Detail "Today 7:20".** Its 3 entries can't co-exist with the F 3:43 day bar, the 22:49 week and "2h 11m
  left". Today is 09:00→10:45, 13:30→14:38 and 20:06→now (3:43).
- **Weekly streaks: DW 5w, Meetings 4w, Reading 4w.** The table's last week (DW 19:30, Meetings 6:10,
  Reading 0:42) misses every weekly goal, so every current weekly streak is **0w**.
  - DW also never reaches 25h. The 04 bars and table show 67–85%, and the 8-week totals leave no room for
    25h weeks. That makes DW 0/11 · 0%, the streak bar empty and the dots dim.
  - Meetings hits weeks 3 Aug and 24 Aug only (best 1w). Reading hits weeks 10 Aug, 17 Aug, 31 Aug and 7 Sep
    (best 2w).
  - In Sep–Oct, the trend totals (24–31h) minus DW (04 bars) minus the Exercise/Email lane hits leave only
    0.5–4h a week for Meetings + Reading.
- **Email "12d".** Last week's 2:50 can't hold 7 days of ≥30m. Email dots match the design except Sun 18 Oct,
  which is a miss so the Home card doesn't gain a "5-day streak" line. Streak 4d.
- **Exercise dots.** Sat 17 Oct is a hit, needed for Home's 6-day streak (the design dot is a miss).
  Lane: last 2 weeks follow the table/dots, Fri 28 Aug dropped (empty heat cell).
- **Heatmap: 4 cells differ.**
  - Thu 22 Oct is perfect: 6:00 DW + Exercise + Email is more than a full day.
  - Today is mid, still in progress.
  - Fri 11 Sep is mid instead of low: the 73px trend bar needs the hours.
  - Fri 18 Sep is low instead of empty: it sits inside the 21d/17d best runs.
- **8-week trend bars.** Sep 13–Oct 4 are each 1px taller (70 79 75 82 vs 69 78 74 81). With the design heights
  the average could be at most 29:35, not 29:42.
- **Goal % lines.** They plot real weekly fractions. DW follows the 04 bars, which disagree with the Paper line
  anyway. Meetings is 10–30% in Sep (clamped at the bottom), and Exercise follows its lane hits.
- **8-week axis labels.** These use the preceding Sunday ("OCT 11" for the Oct 12 week). `PeriodTotal.start`
  is the Monday.

## Gotchas

- **Info.plists.** The app uses `GENERATE_INFOPLIST_FILE` and `INFOPLIST_FILE = Pocus-Info.plist` together. They merge, and the plist only holds `UIAppFonts`. Add new keys as `INFOPLIST_KEY_*` build settings where one exists. Keep both plists at the repo root: inside a synchronized folder they'd be copied as resources.
- **App settings.** Display name is `Chopped` (app and widget extension). `UIUserInterfaceStyle = Dark` is set, plus `.preferredColorScheme(.dark)`.
- **Font files are flat.** They're copied into the bundle root. The `UIAppFonts` entries are bare filenames.
- **Sim snapshot colours.** Simulator snapshots render accents slightly lighter/desaturated compared with device snapshots. Judge colour on the device PNG.
- **Live Activity state.** `PocusActivityAttributes.ContentState` gained optional `icon`, `periodBase`, `goalMinutes` and `period`. For the lock screen and DI: "22:49 / 25:00" = `periodBase` + elapsed since `start`.
- **Font metrics.** `TypeStyle` reads the natural line height from `UIFont`. If a font ever fails to register, the text falls back to the system font and spacing drifts. Check `missingFonts=[]` in the log.
- **Tracker card layout.** The `GlyphView` size is the SVG box width. In `TrackerBezel` the inner block stretches to full width, and you supply its padding.
