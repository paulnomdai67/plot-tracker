-- ============================================================
--  Plot Tracker v4 — Supabase Schema Update
--  Run this in SQL Editor to upgrade from v3
-- ============================================================

-- 1. Add user roles table
create table if not exists user_roles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null unique references auth.users(id) on delete cascade,
  role       text not null default 'standard',  -- 'admin' or 'standard'
  created_at timestamptz default now()
);

-- 2. Add product type and installation date to plots
alter table plots add column if not exists product_type  text not null default '';
alter table plots add column if not exists install_date  date;

-- 3. Add delivery tracking table
create table if not exists deliveries (
  id            uuid primary key default gen_random_uuid(),
  plot_id       uuid not null references plots(id) on delete cascade,
  site_id       uuid not null,
  item          text not null,
  expected_date date,
  arrived_date  date,
  status        text not null default 'Pending',  -- Pending, On Order, Arrived, Delayed
  notes         text not null default '',
  created_by    text not null default '',
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- 4. Add snagging sign-off fields to plots
alter table plots add column if not exists snag_resolved_at   timestamptz;
alter table plots add column if not exists snag_resolved_by   text not null default '';

-- 5. Add defect category to snagging photos / notes
alter table plots add column if not exists defect_category text not null default '';

-- Indexes
create index if not exists idx_user_roles_user_id   on user_roles(user_id);
create index if not exists idx_deliveries_plot_id   on deliveries(plot_id);
create index if not exists idx_deliveries_site_id   on deliveries(site_id);
create index if not exists idx_plots_install_date   on plots(install_date);

-- RLS
alter table user_roles  enable row level security;
alter table deliveries  enable row level security;

-- Policies
do $$ begin
  if not exists (select 1 from pg_policies where tablename='user_roles' and policyname='auth read roles') then
    create policy "auth read roles"   on user_roles for select using (auth.role()='authenticated');
    create policy "auth insert roles" on user_roles for insert with check (auth.role()='authenticated');
    create policy "auth update roles" on user_roles for update using (auth.role()='authenticated');
  end if;
  if not exists (select 1 from pg_policies where tablename='deliveries' and policyname='auth read deliveries') then
    create policy "auth read deliveries"   on deliveries for select using (auth.role()='authenticated');
    create policy "auth insert deliveries" on deliveries for insert with check (auth.role()='authenticated');
    create policy "auth update deliveries" on deliveries for update using (auth.role()='authenticated');
    create policy "auth delete deliveries" on deliveries for delete using (auth.role()='authenticated');
  end if;
end $$;

-- ============================================================
--  HOW TO MAKE A USER AN ADMIN
--  Run this in SQL Editor, replacing the email address:
--
--  insert into user_roles (user_id, role)
--  select id, 'admin' from auth.users where email = 'paul@thecranntara.scot'
--  on conflict (user_id) do update set role = 'admin';
--
-- ============================================================
