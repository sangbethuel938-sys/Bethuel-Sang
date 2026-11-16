-- Run once in Supabase: SQL Editor -> New query -> Run
-- Creates the public image bucket used for the profile picture and project screenshots.
insert into storage.buckets (id, name, public)
values ('portfolio-assets', 'portfolio-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "public read assets"  on storage.objects;
drop policy if exists "owner upload assets" on storage.objects;
drop policy if exists "owner update assets" on storage.objects;
drop policy if exists "owner delete assets" on storage.objects;

create policy "public read assets" on storage.objects
  for select using (bucket_id = 'portfolio-assets');

create policy "owner upload assets" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'portfolio-assets' and (auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');

create policy "owner update assets" on storage.objects
  for update to authenticated
  using (bucket_id = 'portfolio-assets' and (auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');

create policy "owner delete assets" on storage.objects
  for delete to authenticated
  using (bucket_id = 'portfolio-assets' and (auth.jwt() ->> 'email') = 'sangbethuel938@gmail.com');
