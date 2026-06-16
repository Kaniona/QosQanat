-- =============================================================================
-- QosQanat 2.0 — Supabase Database Schema
-- =============================================================================
-- Run this entire file in the Supabase SQL Editor (one shot). It is idempotent
-- where practical and safe to re-run.
--
-- Contents:
--   00. Extensions
--   01. Helper functions (qosqanat_id generator, updated_at, friendship guard)
--   02. Tables (users, equipment, inventory, friendships, battles, tournaments,
--       tournament_participants, task_progress, daily_quests, user_achievements,
--       news, notifications)
--   03. Indexes
--   04. updated_at trigger wiring
--   05. SECURITY DEFINER read functions (friend profiles, leaderboard)
--   06. Row Level Security: enable + policies
--
-- Security model summary is in the comment block at the very bottom.
-- =============================================================================


-- =============================================================================
-- 00. EXTENSIONS
-- =============================================================================
create extension if not exists "pgcrypto";   -- gen_random_uuid()


-- =============================================================================
-- 01. HELPER FUNCTIONS
-- =============================================================================

-- Generate a unique QosQanat ID of the form QQ-XXXXXXXXX (9 uppercase
-- alphanumeric chars). Loops until it finds an unused value. SECURITY DEFINER so
-- the uniqueness check can read the users table regardless of the caller's RLS.
create or replace function public.generate_qosqanat_id()
returns varchar
language plpgsql
security definer
set search_path = public
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no 0/O/1/I
  candidate varchar;
  i int;
begin
  loop
    candidate := 'QQ-';
    for i in 1..9 loop
      candidate := candidate ||
        substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;

    -- Exit when the candidate is not already taken.
    exit when not exists (
      select 1 from public.users u where u.qosqanat_id = candidate
    );
  end loop;

  return candidate;
end;
$$;

-- Generic updated_at maintainer.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- SECURITY DEFINER friendship check used by RLS policies WITHOUT causing
-- recursion (it bypasses RLS on the friendships table). Returns true only for an
-- ACCEPTED friendship between the two users, in either direction.
create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.friendships f
    where f.status = 'accepted'
      and (
        (f.user_a_id = a and f.user_b_id = b) or
        (f.user_a_id = b and f.user_b_id = a)
      )
  );
$$;


-- =============================================================================
-- 02. TABLES
-- =============================================================================

-- 1. users -------------------------------------------------------------------
-- Profile row, 1:1 with auth.users. The app inserts this at registration.
create table if not exists public.users (
  id                    uuid primary key references auth.users(id) on delete cascade,
  qosqanat_id           varchar(12) not null unique
                          default public.generate_qosqanat_id(),
  full_name             varchar(120) not null,
  phone                 varchar(20) unique,
  iin                   varchar(12) unique,
  city                  varchar(80),
  school                varchar(160),
  grade                 int check (grade between 1 and 11),
  assistant_type        varchar(10) not null default 'bektur'
                          check (assistant_type in ('bektur', 'nazym')),
  profile_photo_url     text,
  level                 int not null default 1 check (level >= 1),
  xp                    int not null default 0 check (xp >= 0),
  coins                 int not null default 0 check (coins >= 0),
  akyl_points           int not null default 0 check (akyl_points >= 0),
  current_streak        int not null default 0 check (current_streak >= 0),
  longest_streak        int not null default 0 check (longest_streak >= 0),
  last_login_date       date,
  total_tasks_completed int not null default 0 check (total_tasks_completed >= 0),
  total_battles_won     int not null default 0 check (total_battles_won >= 0),
  total_battles_played  int not null default 0 check (total_battles_played >= 0),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  constraint iin_is_12_digits check (iin is null or iin ~ '^[0-9]{12}$')
);

-- 2. user_equipment ----------------------------------------------------------
-- Currently equipped cosmetic per slot (one item per slot per user).
create table if not exists public.user_equipment (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  slot        varchar(40) not null,
  item_id     varchar(80) not null,
  equipped_at timestamptz not null default now(),
  unique (user_id, slot)
);

-- 3. user_inventory ----------------------------------------------------------
-- Owned cosmetics. One row per (user, item).
create table if not exists public.user_inventory (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.users(id) on delete cascade,
  item_id        varchar(80) not null,
  purchased_at   timestamptz not null default now(),
  purchase_price int not null default 0 check (purchase_price >= 0),
  unique (user_id, item_id)
);

-- 4. friendships -------------------------------------------------------------
-- Canonical ordering enforced (user_a_id < user_b_id) so each pair is unique and
-- direction-independent. initiated_by records who sent the request.
create table if not exists public.friendships (
  id           uuid primary key default gen_random_uuid(),
  user_a_id    uuid not null references public.users(id) on delete cascade,
  user_b_id    uuid not null references public.users(id) on delete cascade,
  status       varchar(10) not null default 'pending'
                 check (status in ('pending', 'accepted', 'blocked')),
  initiated_by uuid not null references public.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  accepted_at  timestamptz,
  unique (user_a_id, user_b_id),
  constraint friendship_distinct check (user_a_id <> user_b_id),
  constraint friendship_canonical_order check (user_a_id < user_b_id)
);

-- 5. battles -----------------------------------------------------------------
-- 1v1 Akyl quiz battles. questions_data holds the shared question set.
create table if not exists public.battles (
  id               uuid primary key default gen_random_uuid(),
  challenger_id    uuid not null references public.users(id) on delete cascade,
  opponent_id      uuid not null references public.users(id) on delete cascade,
  question_count   int not null default 5 check (question_count > 0),
  subject_filter   varchar(80),
  status           varchar(12) not null default 'pending'
                     check (status in ('pending', 'accepted', 'in_progress',
                                       'completed', 'cancelled')),
  challenger_score int not null default 0 check (challenger_score >= 0),
  opponent_score   int not null default 0 check (opponent_score >= 0),
  winner_id        uuid references public.users(id) on delete set null,
  questions_data   jsonb not null default '[]'::jsonb,
  started_at       timestamptz,
  ended_at         timestamptz,
  created_at       timestamptz not null default now(),
  expires_at       timestamptz not null default (now() + interval '15 minutes'),
  constraint battle_distinct_players check (challenger_id <> opponent_id)
);

-- 6. tournaments -------------------------------------------------------------
create table if not exists public.tournaments (
  id               uuid primary key default gen_random_uuid(),
  title            varchar(160) not null,
  description      text,
  status           varchar(10) not null default 'upcoming'
                     check (status in ('upcoming', 'active', 'completed')),
  start_date       timestamptz not null,
  end_date         timestamptz,
  max_participants int check (max_participants is null or max_participants > 0),
  prize_pool       jsonb not null default '{}'::jsonb,
  created_at       timestamptz not null default now(),
  constraint tournament_dates check (end_date is null or end_date >= start_date)
);

-- 7. tournament_participants -------------------------------------------------
create table if not exists public.tournament_participants (
  id            uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  user_id       uuid not null references public.users(id) on delete cascade,
  score         int not null default 0 check (score >= 0),
  rank          int check (rank is null or rank > 0),
  joined_at     timestamptz not null default now(),
  unique (tournament_id, user_id)
);

-- 8. task_progress -----------------------------------------------------------
-- Per-node progress on the learning map.
create table if not exists public.task_progress (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.users(id) on delete cascade,
  subject_id   varchar(80) not null,
  module_id    varchar(80) not null,
  node_id      varchar(80) not null,
  status       varchar(10) not null default 'locked'
                 check (status in ('locked', 'available', 'completed', 'mastered')),
  best_score   int not null default 0 check (best_score >= 0),
  attempts     int not null default 0 check (attempts >= 0),
  xp_earned    int not null default 0 check (xp_earned >= 0),
  coins_earned int not null default 0 check (coins_earned >= 0),
  akyl_earned  int not null default 0 check (akyl_earned >= 0),
  completed_at timestamptz,
  unique (user_id, subject_id, module_id, node_id)
);

-- 9. daily_quests ------------------------------------------------------------
create table if not exists public.daily_quests (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.users(id) on delete cascade,
  quest_id     varchar(80) not null,
  date         date not null default current_date,
  status       varchar(10) not null default 'active'
                 check (status in ('active', 'completed', 'claimed')),
  progress     int not null default 0 check (progress >= 0),
  target       int not null default 1 check (target > 0),
  completed_at timestamptz,
  claimed_at   timestamptz,
  unique (user_id, quest_id, date)
);

-- 10. user_achievements ------------------------------------------------------
create table if not exists public.user_achievements (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.users(id) on delete cascade,
  achievement_id varchar(80) not null,
  unlocked_at    timestamptz not null default now(),
  unique (user_id, achievement_id)
);

-- 11. news -------------------------------------------------------------------
-- Admin-posted announcements shown in the Home feed.
create table if not exists public.news (
  id              uuid primary key default gen_random_uuid(),
  title           varchar(200) not null,
  body            text not null,
  cover_image_url text,
  category        varchar(40),
  is_published    boolean not null default false,
  published_at    timestamptz,
  created_at      timestamptz not null default now()
);

-- 12. notifications ----------------------------------------------------------
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  type       varchar(40) not null,
  title      varchar(200) not null,
  body       text,
  data       jsonb not null default '{}'::jsonb,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);


-- =============================================================================
-- 03. INDEXES
-- =============================================================================

-- users: leaderboard (akyl desc) + city/school scoped boards.
create index if not exists idx_users_akyl_points on public.users (akyl_points desc);
create index if not exists idx_users_city          on public.users (city);
create index if not exists idx_users_school        on public.users (school);

-- foreign-key / lookup indexes
create index if not exists idx_equipment_user      on public.user_equipment (user_id);
create index if not exists idx_inventory_user      on public.user_inventory (user_id);

create index if not exists idx_friendships_a       on public.friendships (user_a_id);
create index if not exists idx_friendships_b       on public.friendships (user_b_id);
create index if not exists idx_friendships_status  on public.friendships (status);

create index if not exists idx_battles_challenger  on public.battles (challenger_id);
create index if not exists idx_battles_opponent    on public.battles (opponent_id);
create index if not exists idx_battles_status      on public.battles (status);

create index if not exists idx_tparticipants_tour  on public.tournament_participants (tournament_id);
create index if not exists idx_tparticipants_user  on public.tournament_participants (user_id);

create index if not exists idx_task_progress_user  on public.task_progress (user_id);
create index if not exists idx_task_progress_subj  on public.task_progress (user_id, subject_id);

create index if not exists idx_daily_quests_user   on public.daily_quests (user_id, date);

create index if not exists idx_user_achievements_u on public.user_achievements (user_id);

create index if not exists idx_news_published      on public.news (is_published, published_at desc);

create index if not exists idx_notifications_user  on public.notifications (user_id, is_read);


-- =============================================================================
-- 04. updated_at TRIGGER (users)
-- =============================================================================
drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
  before update on public.users
  for each row
  execute function public.set_updated_at();


-- =============================================================================
-- 05. SECURITY DEFINER READ FUNCTIONS (safe cross-user reads)
-- =============================================================================
-- These run with the function owner's privileges and expose ONLY public profile
-- columns, so non-friends can still appear on leaderboards without leaking
-- phone / iin / email. RLS stays strict on the base table.

-- Public-profile shape returned to other users.
create or replace function public.get_leaderboard(
  scope       text default 'global',  -- 'global' | 'city' | 'school' | 'friends'
  scope_value text default null,       -- city or school name (for those scopes)
  limit_count int  default 100
)
returns table (
  user_id           uuid,
  qosqanat_id       varchar,
  full_name         varchar,
  city              varchar,
  school            varchar,
  grade             int,
  level             int,
  akyl_points       int,
  profile_photo_url text,
  rank              bigint
)
language sql
security definer
set search_path = public
stable
as $$
  select
    u.id, u.qosqanat_id, u.full_name, u.city, u.school, u.grade,
    u.level, u.akyl_points, u.profile_photo_url,
    row_number() over (order by u.akyl_points desc, u.level desc) as rank
  from public.users u
  where
    case scope
      when 'city'    then u.city   is not distinct from scope_value
      when 'school'  then u.school is not distinct from scope_value
      when 'friends' then public.are_friends(auth.uid(), u.id) or u.id = auth.uid()
      else true
    end
  order by u.akyl_points desc, u.level desc
  limit limit_count;
$$;

-- Fetch a single user's public profile (used when viewing a friend / opponent).
create or replace function public.get_public_profile(target uuid)
returns table (
  user_id           uuid,
  qosqanat_id       varchar,
  full_name         varchar,
  city              varchar,
  school            varchar,
  grade             int,
  level             int,
  xp                int,
  akyl_points       int,
  coins             int,
  current_streak    int,
  longest_streak    int,
  total_tasks_completed int,
  total_battles_won int,
  assistant_type    varchar,
  profile_photo_url text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    u.id, u.qosqanat_id, u.full_name, u.city, u.school, u.grade,
    u.level, u.xp, u.akyl_points, u.coins, u.current_streak, u.longest_streak,
    u.total_tasks_completed, u.total_battles_won, u.assistant_type,
    u.profile_photo_url
  from public.users u
  where u.id = target;
$$;

-- Look up a user by QQ-ID (for "add friend by QosQanat ID").
create or replace function public.find_user_by_qosqanat_id(qid varchar)
returns table (
  user_id           uuid,
  qosqanat_id       varchar,
  full_name         varchar,
  level             int,
  profile_photo_url text
)
language sql
security definer
set search_path = public
stable
as $$
  select u.id, u.qosqanat_id, u.full_name, u.level, u.profile_photo_url
  from public.users u
  where u.qosqanat_id = qid
  limit 1;
$$;

-- Tournament leaderboard: returns each participant's score with their public
-- profile fields ranked. Uses SECURITY DEFINER so participants who aren't
-- friends still appear without exposing private columns.
create or replace function public.get_tournament_leaderboard(target uuid)
returns table (
  user_id           uuid,
  qosqanat_id       varchar,
  full_name         varchar,
  level             int,
  profile_photo_url text,
  score             int,
  rank              bigint
)
language sql
security definer
set search_path = public
stable
as $$
  select
    u.id, u.qosqanat_id, u.full_name, u.level, u.profile_photo_url,
    tp.score,
    row_number() over (order by tp.score desc) as rank
  from public.tournament_participants tp
  join public.users u on u.id = tp.user_id
  where tp.tournament_id = target
  order by tp.score desc;
$$;

-- Public-safe friends list for the signed-in user.
create or replace function public.get_my_friends()
returns table (
  user_id           uuid,
  qosqanat_id       varchar,
  full_name         varchar,
  level             int,
  akyl_points       int,
  profile_photo_url text,
  assistant_type    varchar
)
language sql
security definer
set search_path = public
stable
as $$
  select
    u.id, u.qosqanat_id, u.full_name, u.level, u.akyl_points,
    u.profile_photo_url, u.assistant_type
  from public.friendships f
  join public.users u on
    u.id = case when f.user_a_id = auth.uid() then f.user_b_id else f.user_a_id end
  where f.status = 'accepted'
    and (f.user_a_id = auth.uid() or f.user_b_id = auth.uid());
$$;

-- Recent battles the signed-in user has played, joined to the opponent's
-- public profile fields. Used by the profile screen.
create or replace function public.get_my_recent_battles(limit_count int default 5)
returns table (
  battle_id          uuid,
  opponent_id        uuid,
  opponent_name      varchar,
  opponent_qq_id     varchar,
  opponent_photo_url text,
  my_score           int,
  opponent_score     int,
  won                boolean,
  ended_at           timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  select
    b.id,
    case when b.challenger_id = auth.uid() then b.opponent_id
         else b.challenger_id end,
    o.full_name, o.qosqanat_id, o.profile_photo_url,
    case when b.challenger_id = auth.uid() then b.challenger_score
         else b.opponent_score end,
    case when b.challenger_id = auth.uid() then b.opponent_score
         else b.challenger_score end,
    b.winner_id = auth.uid(),
    coalesce(b.ended_at, b.created_at)
  from public.battles b
  join public.users o on
    o.id = case when b.challenger_id = auth.uid() then b.opponent_id
                else b.challenger_id end
  where (b.challenger_id = auth.uid() or b.opponent_id = auth.uid())
    and b.status = 'completed'
  order by coalesce(b.ended_at, b.created_at) desc
  limit limit_count;
$$;

-- Count of registered users at the given school. Used by the rating screen to
-- gate the "school" leaderboard behind a minimum of 10 students.
create or replace function public.school_user_count(school_name varchar)
returns int
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::int from public.users where school = school_name;
$$;

-- Days the signed-in user completed at least one task. Powers the activity
-- heatmap on the profile screen.
create or replace function public.get_my_activity_days(since timestamptz)
returns table (day date, count int)
language sql
security definer
set search_path = public
stable
as $$
  select
    (completed_at at time zone 'UTC')::date as day,
    count(*)::int
  from public.task_progress
  where user_id = auth.uid()
    and completed_at is not null
    and completed_at >= since
  group by day
  order by day;
$$;

-- Pending friend requests addressed to the signed-in user (incoming) and
-- those they initiated (outgoing). Returned together with a direction flag.
create or replace function public.get_my_friend_requests()
returns table (
  friendship_id     uuid,
  other_user_id     uuid,
  qosqanat_id       varchar,
  full_name         varchar,
  level             int,
  profile_photo_url text,
  direction         text   -- 'incoming' | 'outgoing'
)
language sql
security definer
set search_path = public
stable
as $$
  select
    f.id, u.id, u.qosqanat_id, u.full_name, u.level, u.profile_photo_url,
    case when f.initiated_by = auth.uid() then 'outgoing' else 'incoming' end
  from public.friendships f
  join public.users u on
    u.id = case when f.user_a_id = auth.uid() then f.user_b_id else f.user_a_id end
  where f.status = 'pending'
    and (f.user_a_id = auth.uid() or f.user_b_id = auth.uid());
$$;


-- =============================================================================
-- 06. ROW LEVEL SECURITY
-- =============================================================================
-- Enable RLS on every table. Default-deny: with RLS on and no matching policy,
-- access is refused.

alter table public.users                   enable row level security;
alter table public.user_equipment          enable row level security;
alter table public.user_inventory          enable row level security;
alter table public.friendships             enable row level security;
alter table public.battles                 enable row level security;
alter table public.tournaments             enable row level security;
alter table public.tournament_participants enable row level security;
alter table public.task_progress           enable row level security;
alter table public.daily_quests            enable row level security;
alter table public.user_achievements       enable row level security;
alter table public.news                    enable row level security;
alter table public.notifications           enable row level security;

-- ---- users -----------------------------------------------------------------
drop policy if exists users_select_own     on public.users;
drop policy if exists users_select_friends on public.users;
drop policy if exists users_insert_own     on public.users;
drop policy if exists users_update_own     on public.users;
drop policy if exists users_delete_own     on public.users;

create policy users_select_own on public.users
  for select using (auth.uid() = id);

-- Friends may read each other's full row directly (column scoping for the
-- broader public is handled by the SECURITY DEFINER functions above).
create policy users_select_friends on public.users
  for select using (public.are_friends(auth.uid(), id));

create policy users_insert_own on public.users
  for insert with check (auth.uid() = id);

create policy users_update_own on public.users
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy users_delete_own on public.users
  for delete using (auth.uid() = id);

-- ---- user_equipment --------------------------------------------------------
drop policy if exists equipment_all_own on public.user_equipment;
create policy equipment_all_own on public.user_equipment
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---- user_inventory --------------------------------------------------------
drop policy if exists inventory_all_own on public.user_inventory;
create policy inventory_all_own on public.user_inventory
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---- friendships -----------------------------------------------------------
-- A participant of the pair can read it; either side can create a request they
-- initiated; either side can update (accept/block); either side can remove it.
drop policy if exists friendships_select on public.friendships;
drop policy if exists friendships_insert on public.friendships;
drop policy if exists friendships_update on public.friendships;
drop policy if exists friendships_delete on public.friendships;

create policy friendships_select on public.friendships
  for select using (auth.uid() = user_a_id or auth.uid() = user_b_id);

create policy friendships_insert on public.friendships
  for insert with check (
    auth.uid() = initiated_by
    and (auth.uid() = user_a_id or auth.uid() = user_b_id)
  );

create policy friendships_update on public.friendships
  for update using (auth.uid() = user_a_id or auth.uid() = user_b_id)
  with check (auth.uid() = user_a_id or auth.uid() = user_b_id);

create policy friendships_delete on public.friendships
  for delete using (auth.uid() = user_a_id or auth.uid() = user_b_id);

-- ---- battles ---------------------------------------------------------------
-- Both participants can read and update the shared battle row; the challenger
-- creates it.
drop policy if exists battles_select on public.battles;
drop policy if exists battles_insert on public.battles;
drop policy if exists battles_update on public.battles;

create policy battles_select on public.battles
  for select using (auth.uid() = challenger_id or auth.uid() = opponent_id);

create policy battles_insert on public.battles
  for insert with check (auth.uid() = challenger_id);

create policy battles_update on public.battles
  for update using (auth.uid() = challenger_id or auth.uid() = opponent_id)
  with check (auth.uid() = challenger_id or auth.uid() = opponent_id);

-- ---- tournaments -----------------------------------------------------------
-- Readable by all authenticated users; writes are admin-only (service role
-- bypasses RLS), so no public write policy is defined.
drop policy if exists tournaments_select on public.tournaments;
create policy tournaments_select on public.tournaments
  for select to authenticated using (true);

-- ---- tournament_participants ----------------------------------------------
-- Any authenticated user can read the standings; a user may join/update/leave
-- only their own participation row.
drop policy if exists tparticipants_select on public.tournament_participants;
drop policy if exists tparticipants_insert on public.tournament_participants;
drop policy if exists tparticipants_update on public.tournament_participants;
drop policy if exists tparticipants_delete on public.tournament_participants;

create policy tparticipants_select on public.tournament_participants
  for select to authenticated using (true);

create policy tparticipants_insert on public.tournament_participants
  for insert with check (auth.uid() = user_id);

create policy tparticipants_update on public.tournament_participants
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy tparticipants_delete on public.tournament_participants
  for delete using (auth.uid() = user_id);

-- ---- task_progress ---------------------------------------------------------
drop policy if exists task_progress_all_own on public.task_progress;
create policy task_progress_all_own on public.task_progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---- daily_quests ----------------------------------------------------------
drop policy if exists daily_quests_all_own on public.daily_quests;
create policy daily_quests_all_own on public.daily_quests
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---- user_achievements -----------------------------------------------------
drop policy if exists user_achievements_all_own on public.user_achievements;
create policy user_achievements_all_own on public.user_achievements
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---- news ------------------------------------------------------------------
-- All authenticated users can read PUBLISHED news. Authoring is admin-only via
-- the service role (which bypasses RLS).
drop policy if exists news_select_published on public.news;
create policy news_select_published on public.news
  for select to authenticated using (is_published = true);

-- ---- notifications ---------------------------------------------------------
-- A user reads/updates/deletes only their own notifications. Inserts are
-- normally performed server-side (service role); a self-insert is also allowed.
drop policy if exists notifications_select on public.notifications;
drop policy if exists notifications_insert on public.notifications;
drop policy if exists notifications_update on public.notifications;
drop policy if exists notifications_delete on public.notifications;

create policy notifications_select on public.notifications
  for select using (auth.uid() = user_id);

create policy notifications_insert on public.notifications
  for insert with check (auth.uid() = user_id);

create policy notifications_update on public.notifications
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy notifications_delete on public.notifications
  for delete using (auth.uid() = user_id);


-- =============================================================================
-- 07. FUNCTION EXECUTE GRANTS
-- =============================================================================
grant execute on function public.get_leaderboard(text, text, int)       to authenticated;
grant execute on function public.get_public_profile(uuid)               to authenticated;
grant execute on function public.find_user_by_qosqanat_id(varchar)      to authenticated;


-- =============================================================================
-- SECURITY MODEL (read me)
-- =============================================================================
-- 1. Default-deny: RLS is ON for every table. Without a matching policy, the
--    anon/authenticated roles get nothing. The service role (server-side only)
--    bypasses RLS and is used for admin writes (news, tournaments) + trusted
--    mutations.
--
-- 2. Ownership: per-user tables (equipment, inventory, task_progress,
--    daily_quests, user_achievements, notifications) use a single FOR ALL
--    policy keyed on auth.uid() = user_id. A user can only ever touch their
--    own rows.
--
-- 3. Shared rows: friendships and battles are co-owned by exactly two users;
--    policies allow either participant to read, and to update the shared row.
--
-- 4. Cross-user reads without recursion: RLS policies must not query a table
--    whose own policies query back (infinite recursion). The are_friends()
--    SECURITY DEFINER function reads friendships with RLS bypassed, so the
--    users "friends can read" policy is safe.
--
-- 5. Column-safe public exposure: leaderboards/profiles for NON-friends go
--    through SECURITY DEFINER functions (get_leaderboard, get_public_profile,
--    find_user_by_qosqanat_id) that return ONLY public columns — phone, iin,
--    and auth email are never exposed across users.
--
-- 6. News is readable by authenticated users only when is_published = true.
-- =============================================================================
