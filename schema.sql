-- ============================================================
--  Lube Control — схема базы для Supabase
--  Выполнить один раз: Supabase → SQL Editor → New query → Run
--  Файл можно прогонять повторно: он не ломает уже созданное.
--  Версия от 16.09.2026 — прайс, закупки (склад), фото стеллажей,
--  статусы поставки и подробные движения. Стартовых данных нет.
-- ============================================================

-- ---------- 1. Таблицы ----------

-- ПРАЙС: справочник всего, чем торгуем. Стеллажи заполняются отсюда.
create table if not exists public.catalog (
  id          text primary key,
  category    text not null default 'other',   -- motor | gear | coolant | brake | washer | other
  name        text not null,
  brand       text default '',
  volume      text default '',
  sku         text default '',
  cost        numeric default 0,               -- закупка
  price       numeric default 0,               -- продажа
  archived    boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists catalog_active_idx on public.catalog(archived, name);

create table if not exists public.racks (
  code        text primary key,
  station     text not null,
  address     text default '',
  post        text default '',
  operator    text default '',
  created_at  timestamptz not null default now()
);
-- фото стеллажа: строка data:image/jpeg;base64,... (сайт сам ужимает снимок)
alter table public.racks add column if not exists photo text default '';

create table if not exists public.items (
  id          text primary key,
  rack_code   text not null references public.racks(code) on delete cascade,
  name        text not null,
  volume      text default '',
  price       numeric default 0,
  qty         integer not null default 0,
  max         integer not null default 10,
  sort        integer default 0
);
-- новые поля позиции на стеллаже (копия из прайса на момент установки)
alter table public.items add column if not exists catalog_id text references public.catalog(id);
alter table public.items add column if not exists brand    text default '';
alter table public.items add column if not exists sku      text default '';
alter table public.items add column if not exists category text default 'other';
alter table public.items add column if not exists cost     numeric default 0;
create index if not exists items_rack_idx on public.items(rack_code);
create index if not exists items_catalog_idx on public.items(catalog_id);

create table if not exists public.ops (
  id          text primary key,
  rack_code   text not null,
  item_id     text,
  item_name   text default '',
  type        text not null,
  qty         integer default 0,
  amount      numeric default 0,
  user_login  text default '',
  user_name   text default '',
  note        text default '',
  cancelled   boolean not null default false,
  created_at  timestamptz not null default now()
);
-- новые поля движения товара
alter table public.ops add column if not exists brand     text default '';
alter table public.ops add column if not exists sku       text default '';
alter table public.ops add column if not exists price     numeric default 0;
alter table public.ops add column if not exists cost      numeric default 0;
alter table public.ops add column if not exists margin    numeric default 0;
alter table public.ops add column if not exists qty_after integer;
-- ссылка на прайс: по ней считается остаток склада (закуплено − отгружено)
alter table public.ops add column if not exists catalog_id text;
-- rack_code у операций с прайсом пустой — снимаем ограничение not null
alter table public.ops alter column rack_code drop not null;
alter table public.ops alter column rack_code set default '';
create index if not exists ops_rack_idx on public.ops(rack_code, created_at desc);
create index if not exists ops_date_idx on public.ops(created_at desc);

-- ЗАКУПКИ: что привезли на склад. Со склада товар уезжает на стеллажи.
create table if not exists public.purchases (
  id          text primary key,
  date        date not null default current_date,   -- дата поставки
  catalog_id  text references public.catalog(id),
  name        text not null,
  brand       text default '',
  volume      text default '',
  sku         text default '',
  category    text default 'other',
  supplier    text default '',                      -- поставщик
  cost        numeric default 0,                    -- цена входящая (закуп)
  qty         integer not null default 0,
  amount      numeric default 0,                    -- cost * qty
  payment     text default '',                      -- способ оплаты
  note        text default '',
  user_login  text default '',
  user_name   text default '',
  created_at  timestamptz not null default now()
);
create index if not exists purchases_date_idx on public.purchases(date desc);
create index if not exists purchases_catalog_idx on public.purchases(catalog_id);
create index if not exists purchases_supplier_idx on public.purchases(supplier);

create table if not exists public.requests (
  id              text primary key,
  rack_code       text not null,
  note            text default '',
  status          text not null default 'open',   -- open | packed | done
  created_by      text default '',
  created_by_name text default '',
  created_at      timestamptz not null default now()
);
-- статус поставки для точки: админ увидел заявку / поставка собрана
alter table public.requests add column if not exists seen_at   timestamptz;
alter table public.requests add column if not exists packed_at timestamptz;
alter table public.requests add column if not exists packed_by text default '';
create index if not exists requests_status_idx on public.requests(status);

create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  login      text unique not null,
  name       text not null,
  title      text default '',
  role       text not null default 'seller',
  rack_code  text
);

-- ---------- 2. Заготовка пяти аккаунтов ----------
-- Профиль создаётся автоматически, когда вы заводите пользователя
-- в Supabase → Authentication → Users → Add user.

create table if not exists public.user_seed (
  login      text primary key,
  name       text not null,
  title      text default '',
  role       text not null default 'seller',
  rack_code  text
);

insert into public.user_seed (login, name, title, role, rack_code) values
  ('admin',   'Виталий К.', 'Владелец сети', 'admin',  null),
  ('seller1', 'Алексей П.', 'Продавец',      'seller', 'СТ-101'),
  ('seller2', 'Сергей В.',  'Продавец',      'seller', 'СТ-102'),
  ('seller3', 'Ирина Л.',   'Продавец',      'seller', 'СТ-103'),
  ('seller4', 'Дмитрий Н.', 'Продавец',      'seller', 'СТ-104')
on conflict (login) do update
  set name = excluded.name, title = excluded.title,
      role = excluded.role, rack_code = excluded.rack_code;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  seed public.user_seed%rowtype;
  l text := split_part(new.email, '@', 1);
begin
  select * into seed from public.user_seed where login = l;
  insert into public.profiles (id, login, name, title, role, rack_code)
  values (
    new.id, l,
    coalesce(seed.name, l),
    coalesce(seed.title, 'Продавец'),
    coalesce(seed.role, 'seller'),
    seed.rack_code
  )
  on conflict (id) do update
    set login = excluded.login, name = excluded.name,
        title = excluded.title, role = excluded.role, rack_code = excluded.rack_code;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- 3. Вспомогательные функции доступа ----------

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;

create or replace function public.my_rack()
returns text language sql stable security definer set search_path = public as $$
  select p.rack_code from public.profiles p where p.id = auth.uid();
$$;

-- ---------- 4. Row Level Security ----------

alter table public.catalog   enable row level security;
alter table public.purchases enable row level security;
alter table public.racks    enable row level security;
alter table public.items    enable row level security;
alter table public.ops      enable row level security;
alter table public.requests enable row level security;
alter table public.profiles enable row level security;

-- профили: свой всегда, все — админу
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());

-- ПРАЙС: видят все вошедшие (продавцу нужны названия и цены), правит только админ
drop policy if exists catalog_read on public.catalog;
create policy catalog_read on public.catalog
  for select to authenticated using (true);

drop policy if exists catalog_write on public.catalog;
create policy catalog_write on public.catalog
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ЗАКУПКИ: только администратор — и читает, и пишет
drop policy if exists purchases_all on public.purchases;
create policy purchases_all on public.purchases
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- стеллажи: читают все вошедшие, меняет только админ
drop policy if exists racks_read on public.racks;
create policy racks_read on public.racks
  for select to authenticated using (true);

drop policy if exists racks_write on public.racks;
create policy racks_write on public.racks
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- позиции: читают все; менять остаток может админ или продавец своего стеллажа
drop policy if exists items_read on public.items;
create policy items_read on public.items
  for select to authenticated using (true);

drop policy if exists items_update on public.items;
create policy items_update on public.items
  for update to authenticated
  using (public.is_admin() or rack_code = public.my_rack())
  with check (public.is_admin() or rack_code = public.my_rack());

drop policy if exists items_insert on public.items;
create policy items_insert on public.items
  for insert to authenticated with check (public.is_admin());

drop policy if exists items_delete on public.items;
create policy items_delete on public.items
  for delete to authenticated using (public.is_admin());

-- движения: читают все; пишет админ или продавец своего стеллажа
-- (rack_code пустой — это операции с прайсом, их пишет только админ)
drop policy if exists ops_read on public.ops;
create policy ops_read on public.ops
  for select to authenticated using (true);

drop policy if exists ops_insert on public.ops;
create policy ops_insert on public.ops
  for insert to authenticated
  with check (public.is_admin() or rack_code = public.my_rack());

drop policy if exists ops_update on public.ops;
create policy ops_update on public.ops
  for update to authenticated
  using (public.is_admin() or rack_code = public.my_rack())
  with check (public.is_admin() or rack_code = public.my_rack());

-- заявки: читают все; создаёт продавец своего стеллажа или админ; закрывает админ
drop policy if exists requests_read on public.requests;
create policy requests_read on public.requests
  for select to authenticated using (true);

drop policy if exists requests_insert on public.requests;
create policy requests_insert on public.requests
  for insert to authenticated
  with check (public.is_admin() or rack_code = public.my_rack());

drop policy if exists requests_update on public.requests;
create policy requests_update on public.requests
  for update to authenticated
  using (public.is_admin() or rack_code = public.my_rack())
  with check (public.is_admin() or rack_code = public.my_rack());

-- ---------- 5. Мгновенные обновления (realtime) ----------

do $$
begin
  begin alter publication supabase_realtime add table public.catalog;   exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.purchases; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.items;    exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.ops;      exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.requests; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.racks;    exception when duplicate_object then null; end;
end $$;

-- ---------- 6. Стартовых данных нет ----------
-- Прайс, стеллажи и закупки заводятся руками из панели администратора:
--   Прайс → «Позиция в прайс»
--   Закупки → «Новая закупка»
--   Стеллажи → «Добавить стеллаж» → «+ Позиция»
