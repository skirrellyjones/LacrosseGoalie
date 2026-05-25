# LacrosseGoalie 🥍

An iOS app for tracking women's lacrosse goalie statistics in real time.

## Features

### In-Game Tracking
- **Cage grid** — tap the 3×3 goal zone where each shot went (toggleable)
- **Shot type** — log each shot as 8-Meter Arc, Inside/Near Crease, or Outside/Far
- **Save / Goal logging** with per-half breakdowns
- **Clear tracking** — log successful and failed clears, see clear %
- **Ground balls** — quick +/- counter

### Stats
| Stat | Description |
|---|---|
| Save % | Overall and per-half |
| Goals Against | Total goals allowed |
| Shot Placement | Heatmap of saves/goals by cage zone |
| Clear % | Successful clears / total attempts |
| Ground Balls | Loose balls secured outside the crease |

### Season History *(optional)*
- Save every game and review it later
- Season-wide totals: save %, GAA, clears, ground balls
- Save % per-game bar chart
- Enable in **Settings → Track Season History**

## Requirements
- iOS 16+
- Xcode 15+
- Swift 5.9+

## Getting Started
1. Clone the repo
2. Open `LacrosseGoalie.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build & run (⌘R)

## Settings
| Toggle | Default | Effect |
|---|---|---|
| Track Shot Location | **On** | Shows cage grid; logs zone with each shot |
| Track Season History | Off | Saves completed games for season stats |

## Project Structure
```
LacrosseGoalie/
├── LacrosseGoalieApp.swift   # App entry point
├── ContentView.swift          # Root navigation
├── Models.swift               # Data models (Shot, Game, Clear, enums)
├── DataStore.swift            # Persistence + season aggregates
└── Views/
    ├── HomeView.swift
    ├── GameSetupView.swift
    ├── LiveGameView.swift     # Main in-game screen
    ├── CageGridView.swift     # Interactive 3×3 goal grid
    ├── ShotLogSheet.swift     # Shot entry bottom sheet
    ├── GameSummaryView.swift  # Post-game stats + heatmap
    ├── HistoryView.swift      # List of past games
    ├── SeasonStatsView.swift  # Season totals + bar chart
    └── SettingsView.swift
```

## License
MIT
