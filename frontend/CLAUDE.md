# QosQanat 2.0 Flutter - Claude Code Instructions

## Project Overview
QosQanat ("Eagle Wings") is a world-class gamified educational app for Kazakh 
school students (grades 5-11). Flutter, offline-first (local cache; the ONLY 
online feature is the planned AI voice assistant — see TASK.md section 2).
Rivals Duolingo and Brawl Stars quality.

## Design Reference
Primary design handoff: `~/Downloads/QosQanatElements/design_handoff_qosqanat/`
(tokens, components, screens — README.md there is authoritative).
Extra refs in `design_reference/`. Match designs EXACTLY — colors, spacing,
layout, components.

## Tech Stack
- Flutter 3.x + Dart, Riverpod (state), go_router (nav), Hive + 
  SharedPreferences (ALL data local, offline-first; NO Supabase — .env keeps 
  placeholder creds for a future backend), google_fonts, flutter_svg, 
  lottie + flutter_animate, image_picker (profile photo), confetti.
- Old Supabase-based v1 code is backed up at ../qosqanat_2_0_v1_backup_lib.

## Code Rules (STRICT)
- Proper null-safety, const constructors everywhere possible
- Split large widgets into small reusable widgets
- Business logic in Riverpod providers/notifiers, NEVER in widgets
- NEVER hardcode colors (use AppColors) or strings (Kazakh constants)
- Handle loading/error/empty states
- async/await + try-catch around storage I/O
- Battles are offline: opponent behavior is deterministic mock

## Folder Structure
lib/
  core/ (theme, constants, utils)
  models/
  services/
  providers/
  data/
  screens/ (auth, home, learn, shop, friends, battle, tournament, rating, profile)
  widgets/ (avatar, ui, game)
  navigation/

## Design System (from design_reference/00-design-system)
- Eagle Blue #4A6CF7, Steppe Gold #F5A623, Cosmic Purple #7B61FF
- Success Jade #00C48C, Danger Coral #FF4757, Warning Sunset #FF8C42
- Night Ink #1A1A4E, Background #FAFBFF
- Radius: 12,16,20,28,999. Spacing: 4,8,12,16,20,24,32. Material 3.

## App Navigation (EXACT)
Home screen top HUD (left→right): Level badge → Akyl pill → Coins pill → Profile 
photo (tappable → Profile).
Home middle: News feed (admin-posted announcements).
Bottom nav (5 tabs, left→right): Басты бет, Рейтинг, Оқу, Shop, Профиль (Оқу 
raised middle).
Left-edge swipe → side drawer: Турнир, Достар, Баптаулар.

## Kazakh Language
ALL UI text in Kazakh. Buttons: Жалғастыру, Болдырмау, Дайын, Таңдау. 
Loading: Жүктелуде...

## Voice assistant (UPDATED 2026-06-11)
The old "NO voice assistant" rule is revoked by the product owner. An AI voice
assistant (STT/TTS + Claude API via a Supabase Edge Function proxy) is planned —
the full step-by-step plan lives in TASK.md section 2. NEVER embed API keys in
the app; all Claude calls go through the backend proxy.
