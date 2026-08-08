create extension if not exists "pgcrypto";
create type public.subscription_tier as enum ('free','pro');
create type public.event_type as enum ('school','medical','activity','family','other');
create type public.finance_type as enum ('income','expense');

create table public.users (
 id uuid primary key references auth.users(id) on delete cascade,
 email text not null unique, name text not null default '', subscription_tier public.subscription_tier not null default 'free', stripe_customer_id text unique,
 onboarding_complete boolean not null default false, timezone text not null default 'America/New_York', notification_prefs jsonb not null default '{"email_reminders":true,"google_calendar":{}}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.children (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,name text not null,dob date,school text,grade text,doctor text,insurance_info jsonb not null default '{}'::jsonb,notes text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.events (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,child_id uuid references public.children(id) on delete set null,title text not null,start_time timestamptz not null,end_time timestamptz not null,type public.event_type not null default 'other',location text,conflict_flagged boolean not null default false,conflict_notes text,source text not null default 'keiru',google_event_id text,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),check(end_time > start_time));
create unique index events_google_event_id_unique on public.events(user_id,google_event_id) where google_event_id is not null;
create index events_user_start_idx on public.events(user_id,start_time);
create table public.milestones (id uuid primary key default gen_random_uuid(),child_id uuid not null references public.children(id) on delete cascade,type text not null,title text not null,due_date date not null,completed boolean not null default false,completed_date date,notes text,reminder_sent boolean not null default false,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create index milestones_child_due_idx on public.milestones(child_id,due_date);
create table public.finance_entries (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,type public.finance_type not null,category text not null,amount numeric(12,2) not null check(amount>=0),date date not null,recurring boolean not null default false,recurrence_rule text,notes text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create index finance_entries_user_date_idx on public.finance_entries(user_id,date);
create table public.assistance_matches (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,program_name text not null,program_type text not null,eligibility_score integer not null check(eligibility_score between 0 and 100),application_url text,deadline date,applied boolean not null default false,dismissed boolean not null default false,found_at timestamptz not null default now());
create index assistance_matches_user_idx on public.assistance_matches(user_id);
create table public.ai_drafts (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,draft_type text not null,prompt text not null,content text not null,used boolean not null default false,created_at timestamptz not null default now());
create table public.childcare_options (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,name text not null,type text not null,phone text,address text,verified boolean not null default false,rating numeric(2,1) check(rating between 0 and 5),notes text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.ai_usage (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,period_start date not null,request_count integer not null default 0,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(user_id,period_start));

create or replace function public.touch_updated_at() returns trigger language plpgsql security invoker as $$ begin new.updated_at=now(); return new; end $$;
create trigger users_touch before update on public.users for each row execute function public.touch_updated_at();
create trigger children_touch before update on public.children for each row execute function public.touch_updated_at();
create trigger events_touch before update on public.events for each row execute function public.touch_updated_at();
create trigger milestones_touch before update on public.milestones for each row execute function public.touch_updated_at();
create trigger finances_touch before update on public.finance_entries for each row execute function public.touch_updated_at();
create trigger childcare_touch before update on public.childcare_options for each row execute function public.touch_updated_at();

alter table public.users enable row level security; alter table public.children enable row level security; alter table public.events enable row level security; alter table public.milestones enable row level security; alter table public.finance_entries enable row level security; alter table public.assistance_matches enable row level security; alter table public.ai_drafts enable row level security; alter table public.childcare_options enable row level security; alter table public.ai_usage enable row level security;
create policy users_select on public.users for select using(id=auth.uid()); create policy users_insert on public.users for insert with check(id=auth.uid()); create policy users_update on public.users for update using(id=auth.uid()) with check(id=auth.uid()); create policy users_delete on public.users for delete using(id=auth.uid());
create policy children_all on public.children for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy events_all on public.events for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy milestones_all on public.milestones for all using(exists(select 1 from public.children c where c.id=child_id and c.user_id=auth.uid())) with check(exists(select 1 from public.children c where c.id=child_id and c.user_id=auth.uid()));
create policy finance_all on public.finance_entries for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy assistance_all on public.assistance_matches for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy drafts_all on public.ai_drafts for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy childcare_all on public.childcare_options for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy usage_all on public.ai_usage for all using(user_id=auth.uid()) with check(user_id=auth.uid());
