# Esnaf Simülatör

Tek sayfalı tarayıcı oyunu. `index.html`, Türkçe isimli oyun dosyasına yönlendirir; Netlify depo kökünü yayımlayabilir.

## Supabase Kurulumu

Supabase projesinin **SQL Editor** bölümünde aşağıdaki SQL'i çalıştırın. Oyun kayıtları yalnızca oturum açmış sahibine açık kalır. Herkese açık sıralama tablosunda anonim ziyaretçiler yalnızca kullanıcı adı, para ve seviye sütunlarını okuyabilir.

```sql
create table if not exists public.game_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  save_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.game_saves
  add column if not exists save_data jsonb not null default '{}'::jsonb;
alter table public.game_saves
  add column if not exists updated_at timestamptz not null default now();

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
```

Supabase **Authentication → URL Configuration** bölümünde `Site URL` alanını yayımdan sonraki Netlify adresiyle ayarlayın ve aynı adresi `Redirect URLs` listesine ekleyin (ör. `https://oyun-adiniz.netlify.app/**`). E-posta doğrulaması açıksa yeni oyuncular kayıt sonrası e-postalarındaki bağlantıya tıklamalıdır.

HTML içindeki Supabase URL'si ve `publishable` anahtarı tarayıcıda kullanılmak üzere tasarlanmıştır. `service_role` anahtarını HTML'e, depoya veya Netlify'ın herkese açık değişkenlerine koymayın. Özel veriyi koruyan asıl sınır yukarıdaki RLS politikalarıdır.

## Netlify'de Yayınlama

1. Depoyu GitHub'a gönderin.
2. Netlify'da **Add new site → Import an existing project** ile GitHub deposunu seçin.
3. Build komutunu boş bırakın; publish directory değerini `.` (depo kökü) yapın.
4. Deploy tamamlanınca Netlify adresini açın. `index.html` oyuna yönlendirecektir.
5. Supabase URL Configuration alanlarını bu adresle güncelleyin. Gizli pencerede hesap oluşturma, e-posta doğrulama, giriş, buluta kaydetme ve sıralamayı test edin.

Daha önce kullanıcı adından sahte `@esnafsimulator.com` adresi üreten sürümle açılmış hesaplar gerçek e-posta ile giriş yapamaz. Bu hesapların sahipleri yeni sürümde gerçek e-posta ile hesap açmalıdır; eski kayıtları otomatik eşleştirilmez.

## Bilinen Sınır

Oyun istemci tarafında çalıştığı için oyuncular tarayıcı verisini değiştirip kendi skorlarını yükseltebilir. Bu kurulum kayıt gizliliğini ve sıralama erişimini sınırlar, ancak hileye dayanıklı rekabet sağlamaz. Skorları doğrulayan güvenilir bir sıralama için oyun ilerlemesinin sunucu tarafında doğrulanması gerekir.
