-- Bethuel Sang Portfolio: complete Supabase setup
-- Run once: SQL Editor -> New query -> paste all -> Run. Safe to re-run.
-- Covers: content table, contact messages, image storage, admin (owner) permissions.

-- 1) Portfolio content --------------------------------------------------
create table if not exists public.portfolio_store (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.portfolio_store add column if not exists updated_at timestamptz not null default now();

create or replace function public.set_portfolio_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists portfolio_store_updated_at on public.portfolio_store;
create trigger portfolio_store_updated_at
before update on public.portfolio_store
for each row execute function public.set_portfolio_updated_at();

grant usage on schema public to anon, authenticated, service_role;
grant select on table public.portfolio_store to anon;
grant select, insert, update, delete on table public.portfolio_store to authenticated, service_role;

alter table public.portfolio_store enable row level security;

drop policy if exists "Public portfolio data reads"        on public.portfolio_store;
drop policy if exists "Service role manages portfolio data" on public.portfolio_store;
drop policy if exists "public read content"                on public.portfolio_store;
drop policy if exists "owner write content"                on public.portfolio_store;

-- Visitors read portfolio content (never the old admin_auth password record).
create policy "public read content" on public.portfolio_store
  for select to anon, authenticated
  using (key <> 'admin_auth');

-- Only you (signed in with this email) can add, edit or delete from the admin page.
create policy "owner write content" on public.portfolio_store
  for all to authenticated
  using      ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');

-- Server-side role keeps full access.
create policy "Service role manages portfolio data" on public.portfolio_store
  for all to service_role using (true) with check (true);

-- 2) Contact form messages ---------------------------------------------
create table if not exists public.contact_messages (
  id         bigint generated always as identity primary key,
  name       text not null check (char_length(name) between 1 and 200),
  email      text not null check (char_length(email) between 3 and 320),
  message    text not null check (char_length(message) between 1 and 5000),
  created_at timestamptz not null default now()
);
alter table public.contact_messages enable row level security;

drop policy if exists "visitors can send" on public.contact_messages;
drop policy if exists "owner can read"    on public.contact_messages;
drop policy if exists "owner can delete"  on public.contact_messages;

create policy "visitors can send" on public.contact_messages
  for insert to anon, authenticated with check (true);
create policy "owner can read" on public.contact_messages
  for select to authenticated using ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
create policy "owner can delete" on public.contact_messages
  for delete to authenticated using ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');

grant insert on public.contact_messages to anon, authenticated;
grant select, delete on public.contact_messages to authenticated;
grant all on public.contact_messages to service_role;

-- 3) Image storage (profile picture, project screenshots) ---------------
insert into storage.buckets (id, name, public)
values ('portfolio-assets', 'portfolio-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "Public portfolio asset reads"          on storage.objects;
drop policy if exists "Service role manages portfolio assets" on storage.objects;
drop policy if exists "public read assets"                    on storage.objects;
drop policy if exists "owner upload assets"                   on storage.objects;
drop policy if exists "owner update assets"                   on storage.objects;
drop policy if exists "owner delete assets"                   on storage.objects;

create policy "public read assets" on storage.objects
  for select to anon, authenticated using (bucket_id = 'portfolio-assets');
create policy "owner upload assets" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'portfolio-assets' and (auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
create policy "owner update assets" on storage.objects
  for update to authenticated
  using (bucket_id = 'portfolio-assets' and (auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
create policy "owner delete assets" on storage.objects
  for delete to authenticated
  using (bucket_id = 'portfolio-assets' and (auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
create policy "Service role manages portfolio assets" on storage.objects
  for all to service_role
  using (bucket_id = 'portfolio-assets') with check (bucket_id = 'portfolio-assets');

-- Refresh the API so the new tables are visible immediately.
notify pgrst, 'reload schema';\n
-- 4) Admin reply history ------------------------------------------------
create table if not exists public.contact_replies (
  id bigint generated always as identity primary key,
  message_id bigint not null references public.contact_messages(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 5000),
  status text not null default 'saved' check (status in ('saved','sent')),
  created_at timestamptz not null default now()
);
alter table public.contact_replies enable row level security;
drop policy if exists "owner can read replies" on public.contact_replies;
drop policy if exists "owner can create replies" on public.contact_replies;
drop policy if exists "owner can delete replies" on public.contact_replies;
create policy "owner can read replies" on public.contact_replies
  for select to authenticated using ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
create policy "owner can create replies" on public.contact_replies
  for insert to authenticated with check ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
create policy "owner can delete replies" on public.contact_replies
  for delete to authenticated using ((auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
grant select, insert, delete on public.contact_replies to authenticated;
grant all on public.contact_replies to service_role;
