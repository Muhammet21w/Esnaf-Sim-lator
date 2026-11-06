create table if not exists public.game_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  save_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.game_saves
  add column if not exists save_data jsonb not null default '{}'::jsonb;
alter table public.game_saves
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'game_saves'
      and column_name = 'game_state'
  ) then
    execute 'update public.game_saves set save_data = game_state::jsonb where game_state is not null and save_data = ''{}''::jsonb';
    execute 'alter table public.game_saves alter column game_state drop not null';
  end if;
end
$$;

alter table public.game_saves enable row level security;
revoke all on public.game_saves from public, anon;
grant select, insert, update on public.game_saves to authenticated;

drop policy if exists "game_saves_select_own" on public.game_saves;
create policy "game_saves_select_own"
  on public.game_saves for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "game_saves_insert_own" on public.game_saves;
create policy "game_saves_insert_own"
  on public.game_saves for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "game_saves_update_own" on public.game_saves;
create policy "game_saves_update_own"
  on public.game_saves for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create table if not exists public.leaderboard (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  money bigint not null default 0,
  level integer not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.leaderboard enable row level security;
revoke all on public.leaderboard from public, anon, authenticated;
grant select (username, money, level) on public.leaderboard to anon;
grant select (user_id, username, money, level) on public.leaderboard to authenticated;
grant insert (user_id, username, money, level, updated_at)
  on public.leaderboard to authenticated;
grant update (username, money, level, updated_at)
  on public.leaderboard to authenticated;
grant update on public.leaderboard to authenticated;

drop policy if exists "leaderboard_read_public" on public.leaderboard;
create policy "leaderboard_read_public"
  on public.leaderboard for select to anon, authenticated
  using (true);

drop policy if exists "leaderboard_insert_own" on public.leaderboard;
create policy "leaderboard_insert_own"
  on public.leaderboard for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "leaderboard_update_own" on public.leaderboard;
create policy "leaderboard_update_own"
  on public.leaderboard for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
