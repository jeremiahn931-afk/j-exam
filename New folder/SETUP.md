# J-EXAM — Netlify + Supabase starter

A React online examination app with teacher and student views, five requested question types, timed tests, auto-submit, objective auto-marking, and teacher result listing.

## Important before real student use

This is a working front-end starter, not yet a hardened production examination service. The sample exam works locally using code `JEXAM1`. Real teacher login, exam storage, and question storage use Supabase. The current browser-side student submission path is deliberately not enabled by the supplied security policies. Before publishing for real students, implement the submission Netlify Function described below. Never expose a Supabase service-role key in `VITE_` variables or browser code.

## 1. Install and run locally

Install Node.js LTS. In this folder run:

```bash
npm install
cp .env.example .env
npm run dev
```

Open the local URL printed by Vite. On Windows PowerShell, use `Copy-Item .env.example .env` instead of `cp`.

## 2. Create Supabase project

1. Create a project at https://supabase.com.
2. Open SQL Editor and run all of `supabase/schema.sql`.
3. In Project Settings → API, copy the Project URL and `anon` public key into `.env`:

```env
VITE_SUPABASE_URL=https://YOUR-PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR-ANON-PUBLIC-KEY
```

4. In Authentication → Users, create the teacher account (email/password). Disable public sign-ups if only you should administer exams.
5. Restart `npm run dev`.

## 3. Enable the AI Bible question generator

The AI generator runs through a Netlify Function. Your API key stays on the server and is not included in the website bundle.

1. Create an API key with your AI provider (OpenAI).
2. In Netlify, open Site configuration → Environment variables.
3. Add `OPENAI_API_KEY` with your secret API key as the value.
4. Optionally add `OPENAI_MODEL` with a model name available to your API account. The default is `gpt-4o-mini`.
5. Redeploy the site after adding the variable.

The AI generator is available in the examination editor. It can draft multiple-choice, true/false, short-answer, essay and fill-in-the-blank Bible questions. It adds them to the exam as editable draft questions. Review Scripture references and answers against the Bible translation you teach before publishing. AI output can make mistakes.

The AI API account may incur usage charges. Netlify Functions are required; opening the HTML file directly from your computer will not run the AI endpoint.

## 4. Build and publish on Netlify

1. Push this project to a private or public Git repository.
2. In Netlify choose Add new site → Import an existing project.
3. Build command: `npm run build`; publish directory: `dist`.
4. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` under Site configuration → Environment variables.
5. Deploy.

## 5. Required production hardening

The app must not reveal answer keys to students. The current starter loads question rows (including `answer`) from Supabase for a simplified prototype, so do NOT use it for a high-stakes or live graded exam until this is changed.

For production, create a server-side Netlify Function:
- `GET /.netlify/functions/exam?code=...` returns the published exam and questions WITHOUT answer keys.
- `POST /.netlify/functions/submit` validates the exam's start/deadline on the server, grades objective questions using answer keys server-side, stores the attempt and essay responses, and returns the score.
- Keep the Supabase service-role key only in Netlify environment variables, never in `VITE_` variables.
- Add per-student attempt limits, unique attempt tokens, server-authoritative start times, rate limiting, and a policy for reconnecting/resuming.
- Add essay marking in the teacher dashboard before treating the displayed automatic score as a final total.

The browser countdown is a user-interface aid only. A secure exam deadline must be enforced in the server-side submit function.

## Included question types

- Multiple choice (four options)
- True / False
- Short answer (case-insensitive exact match)
- Essay (saved for manual marking)
- Fill in the blanks (case-insensitive exact match)

## Notes

- `JEXAM1` previews the sample examination without a database.
- Short-answer and fill-in-the-blank marking currently uses case-insensitive exact text comparison. Add accepted-answer variants for more flexible marking.
- Results dashboard currently lists saved attempts. Add a dedicated essay grading workflow and CSV export in the next development pass.

## AI Bible question generation

The AI feature uses `netlify/functions/generate-questions.mjs`. It reads `OPENAI_API_KEY` only from Netlify's server-side environment. Do not rename it to a `VITE_` variable or put the secret in frontend code.
