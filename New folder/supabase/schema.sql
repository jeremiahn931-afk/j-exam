-- Run this entire script in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.exams (
 id uuid primary key default gen_random_uuid(),
 title text not null, description text default '',
 duration_minutes int not null check(duration_minutes between 1 and 300),
 access_code text unique not null,
 published boolean not null default false,
 created_by uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
create table if not exists public.questions (
 id uuid primary key default gen_random_uuid(),
 exam_id uuid not null references public.exams(id) on delete cascade,
 position int not null,
 type text not null check(type in ('mcq','tf','short','essay','blank')),
 prompt text not null,
 options jsonb,
 answer text,
 points int not null default 1 check(points > 0)
);
create table if not exists public.attempts (
 id uuid primary key default gen_random_uuid(),
 exam_id uuid not null references public.exams(id) on delete cascade,
 student_name text not null,
 student_code text default '',
 answers jsonb not null default '{}'::jsonb,
 score numeric not null default 0,
 max_score numeric not null default 0,
 status text not null default 'submitted',
 submitted_at timestamptz not null default now()
);
create table if not exists public.essay_responses (
 id uuid primary key default gen_random_uuid(),
 attempt_id uuid not null references public.attempts(id) on delete cascade,
 question_id uuid not null references public.questions(id) on delete cascade,
 response text default '',
 teacher_score numeric,
 teacher_feedback text
);
alter table public.exams enable row level security;
alter table public.questions enable row level security;
alter table public.attempts enable row level security;
alter table public.essay_responses enable row level security;
-- Teachers can manage only their own exams.
create policy "teacher manages own exams" on public.exams for all to authenticated
 using (created_by = auth.uid()) with check (created_by = auth.uid());
create policy "published exams readable" on public.exams for select to anon, authenticated using (published = true);
create policy "teacher manages questions" on public.questions for all to authenticated
 using (exists(select 1 from public.exams e where e.id=exam_id and e.created_by=auth.uid()))
 with check (exists(select 1 from public.exams e where e.id=exam_id and e.created_by=auth.uid()));
create policy "published questions readable" on public.questions for select to anon, authenticated
 using (exists(select 1 from public.exams e where e.id=exam_id and e.published=true));
-- IMPORTANT: Public direct writes are intentionally NOT enabled. Student submission must be
-- moved behind a Netlify Function using the Supabase service-role key before production use.
create policy "teacher reads attempts" on public.attempts for select to authenticated
 using (exists(select 1 from public.exams e where e.id=exam_id and e.created_by=auth.uid()));
create policy "teacher reads essays" on public.essay_responses for select to authenticated
 using (exists(select 1 from public.attempts a join public.exams e on e.id=a.exam_id where a.id=attempt_id and e.created_by=auth.uid()));
