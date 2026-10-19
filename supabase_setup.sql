-- Run once in Supabase: SQL Editor -> New query -> Run
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
