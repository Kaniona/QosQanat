# QosQanat 2.0 — «Қыран қанат»

A world-class, gamified educational app for Kazakh school students (grades
5–11). Students climb a "steppe sky ascension" of subjects, battle friends in
Ақыл шайқасы, compete in tournaments and leaderboards, dress up their study
companion in the shop, and keep daily streaks — all in Kazakh, with Duolingo-
and Brawl-Stars-level polish.

> **No voice assistant.** QosQanat has **no** speech/TTS/microphone features
> anywhere by design.

---

## Tech Stack

- **Flutter 3.x + Dart** (Material 3, null-safe, `const`-heavy)
- **Supabase** — auth (phone), Postgres database, realtime (battles)
- **Riverpod** (`flutter_riverpod`) — all state & business logic
- **go_router** — routing with a stateful 5-tab shell + auth redirect
- **google_fonts** (Nunito — full Kazakh Cyrillic coverage)
- **flutter_svg**, **lottie** + **flutter_animate** — vector art & motion
- **audioplayers** — sound effects
- **confetti** — celebrations (level-up, rewards)
- **image_picker** — profile photo from the phone
- **cached_network_image**, **shared_preferences**, **flutter_dotenv**, **intl**

---

## Folder Structure

```
lib/
  core/
    constants/      app/auth/home/game/onboarding strings, app config
    theme/          AppColors, AppTypography, AppSpacing/AppRadius, AppTheme
    utils/          validators, formatters, password strength, dates
  models/           AppUser, Question, TaskNode, Battle, Tournament, …
  services/         Supabase, auth, game, shop, news, learn-progress, api
  providers/        auth, game, settings, shop, social, news, learn, onboarding
  data/             curriculum, levels, quests, shop items, achievements
  screens/
    auth/           splash, welcome, login, register (steps), assistant select
    home/           HUD + news feed
    learn/          subjects, map, task (quiz types), result
    shop/           avatar stage, item grid, purchase
    friends/        friends, requests, search
    battle/         setup, waiting, play, result
    tournament/     list, detail
    rating/         leaderboards (global/city/school/friends)
    profile/        trophy room, settings
    onboarding/     first-run spotlight tutorial
  widgets/
    avatar/         companion rendering + cosmetics
    ui/             tab bar, drawer, buttons, fields, error view, ornaments
    game/           level-up modal, XP bar, reward toast
  navigation/       app_routes, app_router (shell), main_shell
  main.dart
```

---

## Setup

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Fill in `.env`** at the project root with your Supabase credentials:

   ```env
   SUPABASE_URL=https://YOUR-PROJECT.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

   (`.env` is bundled as an asset and read at runtime via `flutter_dotenv`.)

3. **Provision the backend** — run [`SUPABASE_SETUP.sql`](SUPABASE_SETUP.sql) in
   the Supabase SQL editor. It creates the tables, row-level-security policies,
   triggers, and seed data the app expects.

4. **Run the app**

   ```bash
   flutter run
   ```

   The app is **portrait-only**. App id: `com.qosqanat.app`.

---

## Navigation

- **Bottom tab bar** (custom, rounded white with an ою-өрнек edge): Басты бет ·
  Рейтинг · **Оқу** (raised middle) · Shop · Профиль. Tab state is preserved via
  a `StatefulShellRoute.indexedStack`.
- **Top HUD** (Home): Level badge → Ақыл → Тиын → profile photo (taps to the
  Профиль tab).
- **Side drawer** (left-edge swipe): user header (photo, name, QQ-ID, stats) and
  🏆 Турнир · 👥 Достар · ⚙️ Баптаулар, plus Қолдау / QosQanat туралы and a
  Шығу footer.
- Lessons, battles, tournaments, and settings open as full-screen routes over
  the shell.

---

## Features

- 📚 **Learn** — subject map of lessons/quizzes/boss/treasure nodes with multiple
  question types (multiple choice, true/false, fill-in-blank, match pairs).
- 🎮 **Gamification** — XP & levels with rank titles, coins, ақыл points, daily
  streaks with milestone rewards, global level-up celebration modal.
- ⚔️ **Ақыл шайқасы** — realtime 1-v-1 battles against friends.
- 🏆 **Tournaments & leaderboards** — global / city / school / friends scopes.
- 🛍️ **Shop** — dress up your companion (Бектұр / Назым) with cosmetics.
- 👥 **Friends** — add by QQ-ID, requests with pending badges.
- 🧑‍🚀 **Profile** — trophy room: stats, achievements, activity heatmap, recent
  battles, editable photo.
- 📣 **Home news feed** — admin announcements.
- 🪄 **First-run tutorial** — a spotlight tour of the HUD, news, Оқу, Shop, the
  swipe drawer, and daily quests (shown once, persisted).
- 🌐 **Fully Kazakh UI**, Material 3 design system, friendly error fallback.
- 🚫 **No voice assistant / TTS / microphone** anywhere.

---

## Notes

- Welcome gift: choosing a companion grants **100 coins** (server-side via
  `chooseAssistant`) with a celebration dialog; the tutorial then closes with a
  "you're ready" card (it does not re-grant, to avoid double-crediting).
- Character art, the final eagle app icon, native splash artwork, and sound
  files are placeholders pending the brand assets from `design_reference/`.
