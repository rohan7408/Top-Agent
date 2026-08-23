# Football Agent Game — Project Specification

## 1. Game Concept

The player takes the role of a **football agent**.

The main goal is to:
- Recruit football players.
- Develop recruited players with hired staff.
- Suggest players to clubs.
- Receive contract offers from clubs.
- Accept or decline offers.
- Earn agent fees when represented players sign contracts.
- Manage the agency, players, staff, finances, emails, and career progression across seasons.

---

## 2. Core Gameplay Loop

1. Find or recruit a football player.
2. Add the player to **My Players**.
3. Hire coaching/training staff.
4. Staff help train and develop recruited players.
5. Use the **Suggest** button on a player.
6. One or more clubs may make an offer.
7. A club offer contains:
   - Salary
   - Agent fee
   - Contract length
8. The agent can:
   - **Suggest Deal**
   - **Decline**
9. If **Suggest Deal** is chosen:
   - The player joins the club.
   - Salary and contract information are stored.
   - The agent receives the agent fee.
10. Continue advancing weeks and managing players.

---

## 3. New Game Flow

The game starts from a main menu.

### Main Menu
- New Game

### New Game Setup
The user enters:
- Agent Name
- Agency Name
- Agent Age

After setup, the game starts and opens the main game interface.

---

## 4. Main Game Pages

### My Players

Shows all players currently represented by the agent.

Each player should eventually show information such as:
- Name
- Age
- Position
- Current club
- Contract
- Salary
- Player value
- Development
- Agent relationship/status

Main actions:
- Open player profile
- Suggest player to clubs
- View contract
- View career information

---

### Talents

Young players can spawn here.

The agent can discover and recruit these players.

Possible player information:
- Name
- Age
- Position
- Ability
- Potential
- Value
- Current status

Main action:
- Recruit player

---

### Email

The game sends important events and notifications here.

Examples from the current design:
- Player transferred to a club
- Contract expired
- Club offer received
- Other player/agency events

---

### Finance

Shows the agent/agency financial activity.

Should track:
- Income
- Expenses
- Agent fees
- Staff costs
- Other future agency expenses

---

### Staff

The user can recruit staff from this page.

The page also shows already recruited staff.

Staff can include coaching/training staff who help develop recruited players.

---

## 5. Player-to-Club Deal System

A represented player has a **Suggest** button.

### Suggest Flow

`Player -> Suggest -> Club Interest -> Club Offer`

A club offer should contain:

- Club
- Offered salary
- Agent fee
- Contract length

The agent receives two options:

### Suggest Deal

If selected:
- Player accepts/joins the club.
- Club is assigned to the player.
- Contract length is stored.
- Salary is stored.
- Agent receives the agent fee.
- An email/event can be generated.

### Decline

If selected:
- The offer is rejected.
- Player remains in the current state.
- No agent fee is paid.

---

## 6. Football World

The game needs seeded football leagues.

The initial example league is:

**Premier League**

The league contains clubs.

Each club should have:
- Club name
- Players
- Club value
- Squad value
- Total player salary
- Budget

Each club therefore needs its own squad and financial information.

---

## 7. Time System

The main progression button is:

**Next Week**

The game uses a **50-week season**.

Current season structure from the original design:

| Weeks | Phase |
|---|---|
| 1–20 | Play Weeks |
| 20–25 | Mid Transfer Weeks |
| 25–40 | Play Weeks |
| 40–50 | Main Transfer Window |

After week 50:
- The season ends.
- A new season begins.
- Week returns to 1.

> Note: The current design has overlapping boundary weeks (20, 25, and 40). Keep this behavior until the exact boundary rules are decided.

---

## 8. Next Week Simulation

Pressing **Next Week** should eventually process game systems such as:

- Advance current week
- Update season phase
- Generate talents
- Develop/train represented players
- Process contracts
- Detect expired contracts
- Generate emails
- Process club/player events
- Process transfers during transfer periods
- Update finances
- Start a new season after week 50

---

## 9. Core Game Data

Recommended core entities for implementation:

### Agent
- id
- name
- agencyName
- age
- money
- reputation
- currentWeek
- currentSeason

### Player
- id
- name
- age
- position
- ability
- potential
- value
- clubId
- agentId
- salary
- contractEnd
- recruited status

### Club
- id
- name
- leagueId
- clubValue
- squadValue
- totalSalary
- budget

### Contract
- id
- playerId
- clubId
- salary
- agentFee
- contractLength
- startSeason
- endSeason

### Staff
- id
- name
- role
- ability
- salary
- agencyId

### Email
- id
- subject
- body
- type
- createdWeek
- createdSeason
- read status

### Finance Transaction
- id
- type
- description
- amount
- week
- season

### League
- id
- name
- clubs

---

## 10. Suggested Project Structure

Recommended Flutter structure:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
│
├── models/
│   ├── agent.dart
│   ├── player.dart
│   ├── club.dart
│   ├── league.dart
│   ├── contract.dart
│   ├── staff.dart
│   ├── email.dart
│   └── finance_transaction.dart
│
├── database/
│   ├── database.dart
│   ├── tables/
│   └── repositories/
│
├── simulation/
│   ├── game_engine.dart
│   ├── season_engine.dart
│   ├── transfer_engine.dart
│   ├── talent_engine.dart
│   ├── training_engine.dart
│   ├── contract_engine.dart
│   └── finance_engine.dart
│
├── providers/
│   ├── game_provider.dart
│   ├── player_provider.dart
│   ├── club_provider.dart
│   └── finance_provider.dart
│
└── screens/
    ├── main_menu/
    ├── new_game/
    ├── home/
    ├── my_players/
    ├── talents/
    ├── email/
    ├── finance/
    ├── staff/
    ├── player_profile/
    └── club_profile/
```

---

## 11. Recommended Technical Stack

Current project stack:

- **Flutter**
- **Dart**
- **Riverpod** — game/app state
- **Drift + SQLite** — local save database
- **go_router** — navigation
- **fl_chart** — financial/statistical charts
- **build_runner** — code generation for Drift

Keep the football simulation separate from UI code.

Example:

```text
UI
 ↓
Riverpod Providers
 ↓
Game/Simulation Engine
 ↓
Repositories
 ↓
Drift / SQLite
```

---

## 12. MVP Development Order

Build the first playable version in this order:

### Phase 1 — Foundation
- Agent model
- Player model
- Club model
- League model
- Game state
- Week/season state

### Phase 2 — New Game
- Main menu
- New Game screen
- Agent name
- Agency name
- Agent age

### Phase 3 — Main Navigation
- My Players
- Talents
- Email
- Finance
- Staff

### Phase 4 — Player Recruitment
- Generate talents
- Recruit talent
- Add recruited player to My Players

### Phase 5 — Club System
- Seed Premier League
- Seed clubs
- Give clubs squads
- Add budgets and squad values

### Phase 6 — Deals
- Suggest button
- Generate club interest
- Generate offer
- Salary
- Agent fee
- Contract length
- Suggest Deal
- Decline

### Phase 7 — Contracts and Finance
- Save contracts
- Pay agent fees
- Track agent income
- Track staff expenses
- Contract expiration

### Phase 8 — Staff and Training
- Recruit staff
- Staff salaries
- Player training/development

### Phase 9 — Next Week
- Advance week
- Run weekly simulation
- Generate emails
- Process player development
- Process contracts
- Process finances

### Phase 10 — Seasons and Transfers
- 50-week season
- Play periods
- Mid transfer period
- Main transfer window
- New season reset

### Phase 11 — Save/Load
- Store game state in SQLite
- Continue saved game
- New Game / Load Game

---

## 13. First Playable Goal

The first playable build does **not** need a full football match engine.

A successful first version only needs this loop:

```text
New Game
   ↓
See Talents
   ↓
Recruit Player
   ↓
Player appears in My Players
   ↓
Suggest Player
   ↓
Club makes Offer
   ↓
Accept / Decline
   ↓
Player signs Contract
   ↓
Agent receives Fee
   ↓
Next Week
   ↓
Repeat
```

Once this works reliably, expand the football world, staff system, player development, contracts, finances, emails, and seasonal simulation.

---

## 14. Important Design Rule

Keep these three parts separate:

### UI
What the user sees and taps.

### Game State
The current agent, players, clubs, week, season, money, emails, etc.

### Simulation
The rules that change the world when the player presses **Next Week**.

Do not place the main simulation logic directly inside Flutter widgets.

This separation will make the game much easier to expand later.
