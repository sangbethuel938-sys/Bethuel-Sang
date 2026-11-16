-- Run once in Supabase: SQL Editor -> New query -> Run
-- Safe to re-run.

-- 1) Portfolio content (projects, experience, certifications, education, skills, profile)
create table if not exists public.portfolio_store (
  key   text primary key,
  value jsonb not null
);
alter table public.portfolio_store enable row level security;

drop policy if exists "public read content" on public.portfolio_store;
drop policy if exists "owner write content" on public.portfolio_store;

-- Visitors can read portfolio content, but never the old Streamlit password record.
create policy "public read content" on public.portfolio_store
  for select using (key <> 'admin_auth');

-- Only you (signed in with this email) can add, edit or delete.
create policy "owner write content" on public.portfolio_store
  for all to authenticated
  using ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');

-- 2) Contact form messages
create table if not exists public.contact_messages (
  id         bigint generated always as identity primary key,
  name       text not null check (char_length(name) between 1 and 200),
  email      text not null check (char_length(email) between 3 and 320),
  message    text not null check (char_length(message) between 1 and 5000),
  created_at timestamptz not null default now()
);
alter table public.contact_messages enable row level security;

drop policy if exists "visitors can send" on public.contact_messages;
drop policy if exists "owner can read" on public.contact_messages;
drop policy if exists "owner can delete" on public.contact_messages;

-- Anyone can send a message, but cannot read or change others.
create policy "visitors can send" on public.contact_messages
  for insert to anon, authenticated with check (true);

-- Only you can read and delete messages.
create policy "owner can read" on public.contact_messages
  for select to authenticated
  using ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');

create policy "owner can delete" on public.contact_messages
  for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');

grant insert on public.contact_messages to anon, authenticated;
grant select, delete on public.contact_messages to authenticated;
