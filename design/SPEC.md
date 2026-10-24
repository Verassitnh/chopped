# Chopped: Focus Time — build spec

The Xcode project is still named **Pocus** (targets `Pocus`, `PocusWidgets`). We are **replacing the existing Pocus UI in place** with the Chopped design. Keep the existing AppIcon (`Pocus/AppIcon.icon`). User-facing name = **Chopped** (home screen label), full name "Chopped: Focus Time".

## Source of truth
- Paper file `01M5P16A2BNS9XSW8JFT3NNGP4` (Paper MCP tools: `get_jsx`, `get_computed_styles`, `get_tree_summary`, `get_screenshot`). Use these for exact px values — never eyeball from PNGs when a value can be read.
- PNG refs at 3x: `design/refs/*.png` (artboards are 440pt wide = iPhone Pro Max class).
- HTML generators that produced the designs (readable values): `design/gen/c3/gen.py` (icons, card helpers), `design/gen/f/gen.py` (lock/widgets/island), `design/gen/n/gen.py` (new tracker), `design/gen/r/*` + `design/gen/s/gen.py` (stats), `design/gen/d/*` (tracker detail).

| # | Screen | Paper node (FINAL copy) | Ref PNG |
|---|---|---|---|
| 01 | Home | `AB6-0` | 01-home |
| 02 | Tracker detail (sheet, H3) | `AGW-0` | 02-tracker-detail |
| 03 | Stats (R3) | `AL7-0` | 03-stats |
| 04 | Tracker stats (T2, pushed page) | `AYR-0` | 04-tracker-stats |
| 05 | New tracker sheet (N2) | `B2U-0` | 05-new-tracker |
| 06 | Lock screen Live Activity | `B70-0` (card node `B7A-0`) | 06-lock-screen |
| 07 | Home-screen widgets (medium, small running, small idle) | `B7U-0` | 07-widgets |
| 08 | Dynamic Island compact/minimal/expanded + Control Center controls | `BBE-0` | 08-dynamic-island-controls |

## Design system
- Background `#0C0C0E`; sheets `#141416`; raised `#1C1C1E`.
- Text: primary `#F2F2F7`, secondary `#8E8E93`, tertiary `#6C6C70`, `#AEAEB2`.
- Fonts (bundle in app AND widget extension):
  - **Geist** — names/labels/UI text.
  - **Geist Mono** — every number except the big live counter/hero total.
  - **Geist Pixel** (Square variant, ELSH=0) — ONLY the big running timer and the hero total.
  - Use exact px font sizes, line heights, letter-spacing from Paper (letter-spacing em → points = em × size).
- Section labels: Geist Mono 11, uppercase, tracking 0.08em, `#6C6C70`.
- Tracker card (C3.2): tinted outer bezel (radius 26, padding 5/5/12) → bright accent inner block (radius 21) with black text/glyphs → 20-tick segment strip below (tick h 6, gap 3, unfilled = accent @ 0.2, strip padding 0 17 0 19). Black circular Play/Stop buttons.
- Accent restraint: accent only on "now" items; past values grays (`#26262A`, `#48484C`, `#3A3A3E`).
- Palette (accent / tint): Deep Work `#4A8BE5`/`#172335`, Meetings `#F7A23A`/`#362716`, Exercise `#1DB3A6`/`#0F2A29`, Email `#9D68F0`/`#261D37`, Reading `#EF6B6B`/`#351D1F`, Pink `#F07EB8`/`#3A1C2C`; also `#7CCB8E`, `#E9C95A` in the picker. Up/green `#39D353`.
- Icons: stroke glyphs defined in `design/gen/c3/gen.py` ICONS (+ `music` in f/gen.py); port as SwiftUI `Shape`/`Path` (24×24 viewBox, stroke 2, round caps/joins).
- **No progress strip** on lock-screen live activity or new-tracker preview. Lock-screen live activity shows ONLY Pixel timer + stop inside the bright block; dim bezel is a uniform 5pt border.

## Data model additions
Activity needs: `icon` (string key), `goalMinutes`, `period` (day/week/month/year). Migrate existing SQLite DB without data loss.

## QC harness (required)
- Launch args: `-QCScreen <home|detail|stats|trackerStats|newTracker>` opens that screen directly; `-QCDemo` seeds deterministic demo data matching the designs (Deep Work running 00:50:01 started 20:06, 22:49 of 25h week, Meetings 5:24, Exercise 0:30/0:45, Email 0:27, Reading …; use values in the designs) into a separate in-memory/temporary DB, and freezes "now" so timers match.
- `-QCSnapshot` → after layout settles (~1.5s), render key window to PNG at native scale and write to app Documents as `qc-<screen>.png`. Pull from device with `xcrun devicectl device copy from --device <udid> --domain-type appDataContainer --domain-identifier com.jackson.Pocus --source Documents/qc-home.png --destination <path>`.
- Simulator for fast iteration: iPhone 18 Pro Max `73276883-8B7C-4FD1-A8E0-30F60ADA31DC` (440pt wide, matches artboards). Device: iPhone 15 Pro Max `00008130-000949181A06001C` (430pt wide — layout must be fluid, not hard-coded to 440).

## Build
`export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Use a private `-derivedDataPath` per agent (e.g. `/tmp/dd-<agent>`) so parallel builds don't collide. Team `QBWSX5JLV3`, automatic signing; bundle ids `com.jackson.Pocus`, `com.jackson.Pocus.Widgets`. Project uses fileSystemSynchronizedGroups (new files in `Pocus/`, `PocusWidgets/`, `Shared/` are auto-included; check target membership for Shared).

## Animations (subtle, reasonable)
Spring (response ~0.35, damping ~0.85) for start/stop card transitions; numeric text transitions (`.contentTransition(.numericText())`) on timers/totals where appropriate; segment ticks fill with a short stagger; sheet presentations use system sheets; button press scale 0.96; chart bars grow in on first appear (≤0.5s). Respect Reduce Motion.
