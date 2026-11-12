-- Run in the Supabase SQL editor. Product and style rows are public read-only data.
create extension if not exists pgcrypto;

create type public.undertone as enum ('warm', 'cool', 'neutral', 'olive');
create type public.skin_depth as enum ('fair', 'light', 'medium', 'tan', 'deep', 'rich');
create type public.face_shape as enum ('oval', 'round', 'square', 'heart', 'diamond', 'oblong');
create type public.skin_type as enum ('oily', 'dry', 'combination', 'normal', 'sensitive');
create type public.test_name as enum ('undertone', 'depth', 'face_shape', 'skin_type');
create type public.test_method as enum ('photo', 'vein', 'tshirt', 'quiz');
create type public.product_category as enum ('foundation', 'concealer', 'blush', 'lip', 'eye', 'skincare');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  undertone public.undertone,
  undertone_confidence numeric(4,3) check (undertone_confidence between 0 and 1),
  depth public.skin_depth,
  depth_confidence numeric(4,3) check (depth_confidence between 0 and 1),
  face_shape public.face_shape,
  skin_type public.skin_type,
  concerns text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.test_results (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  test public.test_name not null,
  method public.test_method not null,
  raw jsonb not null default '{}'::jsonb,
  result text not null,
  created_at timestamptz not null default now()
);
create index test_results_profile_created_idx on public.test_results(profile_id, created_at desc);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text not null,
  category public.product_category not null,
  shade_name text,
  depth public.skin_depth,
  undertones public.undertone[] not null default '{}',
  colour_hex text check (colour_hex is null or colour_hex ~ '^#[0-9A-Fa-f]{6}$'),
  ingredients text[] not null default '{}',
  good_for text[] not null default '{}',
  avoid_for text[] not null default '{}',
  url text
);

create table public.styles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  face_shapes public.face_shape[] not null default '{}',
  undertones public.undertone[] not null default '{}',
  image_url text
);

create table public.recommendations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  product_ids uuid[] not null default '{}',
  style_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);
create index recommendations_profile_created_idx on public.recommendations(profile_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.test_results enable row level security;
alter table public.products enable row level security;
alter table public.styles enable row level security;
alter table public.recommendations enable row level security;

create policy "Users manage own profile" on public.profiles for all to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "Users manage own test results" on public.test_results for all to authenticated
  using ((select auth.uid()) = profile_id) with check ((select auth.uid()) = profile_id);
create policy "Users manage own recommendations" on public.recommendations for all to authenticated
  using ((select auth.uid()) = profile_id) with check ((select auth.uid()) = profile_id);
create policy "Anyone can read products" on public.products for select to anon, authenticated using (true);
create policy "Anyone can read styles" on public.styles for select to anon, authenticated using (true);

