# keiru-ai
Keiru.ai — AI Chief of Staff for single parents.
Full-stack: Next.js 14 (App Router), Supabase (Postgres + Row Level Security + Auth), OpenAI, Stripe, Google Calendar sync, Resend.

## Features

- Child profiles &multi-child support
- Calendar sync (Google) + iCalendar export
- Milestone tracking + reminders
- Finance tracker (childcare, aliming, support)
- AI chied of staff: task drafting, assistance matching, weekly plan review
- Local assistance dircovery (government, food banks, financial aud)
- Childcare provider management
- Subscriptions (stripe): free, pro ($).

## Setup

1. cp .env.example .env.local and fill in credentials
2. Create a Supabase project; run `supabase/migrations/0001_initial_schema.sql`; optional `supabase/seed.sql`.
3. `npm install` && `npm run dev`

## Deploy

Vercel: connect repo, set env variables, set production `NEXTPUBLIC_APP_URL` and Stripe webhook to `/home/api/stripe/webhook`.
