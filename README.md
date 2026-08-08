# Keiru.ai

> **AI Chief of Staff for single parents.**

![Next.js](https://img.shields.io/badge/Next.js-14-black) ![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6) ![Supabase](https://img.shields.io/badge/Supabase-Auth%20%2B%20Postgres-3ECF8E) ![Stripe](https://img.shields.io/badge/Stripe-Billing-635BFF) ![OpenAI](https://img.shields.io/badge/OpenAI-gpt--4o-412991) ![License](https://img.shields.io/badge/License-MIT-blue)

## What it is

Keiru.ai is an operational assistant for single parents managing school schedules, childcare, household finances, milestones, and family communications from one private workspace. It turns scattered obligations into an actionable plan, highlights collisions before they become emergencies, and helps parents draft the messages and applications that consume scarce time.

Keiru is designed for parents—not workplaces or co-parent surveillance—and protects each family’s information with Supabase Auth and RLS.

## Key Features

- Create child profiles with age, school, routines, and reminder preferences.
- Manage a smart family calendar with Google Calendar sync, conflict detection, and iCalendar export.
- Track developmental, medical, school, and personal milestones with scheduled reminders.
- Generate editable, context-aware school communication drafts with AI.
- Match a parent’s household profile to assistance programs and record application progress.
- Record income, bills, spending, and recurring obligations for a single-income household view.
- Search and compare nearby childcare options against schedule needs.
- Receive milestone reminder emails from the Vercel Cron endpoint at `/api/milestones/reminders`.
- Export account data or request account deletion for GDPR-oriented data portability and erasure workflows.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Next.js 14 App Router |
| Language and UI | TypeScript, React, Tailwind CSS |
| Identity and data | Supabase Auth, PostgreSQL, RLS |
| AI drafting | OpenAI `gpt-4o` |
| Calendar integration | Google Calendar API, OAuth 2.0, iCalendar generation |
| Billing | Stripe subscriptions, Checkout, Customer Portal, webhooks |
| Email | Resend |
| Scheduled work | Vercel Cron |
| Hosting | Vercel |

## Architecture Overview

Keiru uses Server Components for authenticated data views and route handlers for privileged integrations. Google OAuth tokens are held server-side and calendar synchronization maps external events into the family event model. OpenAI is invoked only after server-side session and plan checks; Stripe webhook events update entitlements. The reminder cron authenticates with a cron secret, identifies due milestones, and sends idempotent email notifications.

```text
keiru-ai/
├── app/
│   ├── (auth)/
│   ├── (dashboard)/                 # Calendar, children, finance, assistance
│   ├── api/
│   │   ├── calendar/                # Google connect, sync, iCal export
│   │   ├── ai/school-drafts/
│   │   ├── milestones/reminders/    # Vercel Cron target
│   │   ├── privacy/                 # GDPR export and deletion requests
│   │   └── stripe/
│   └── pricing/
├── components/
│   ├── calendar/
│   ├── finance/
│   └── school-comms/
├── lib/
│   ├── google-calendar.ts
│   ├── openai.ts
│   ├── stripe.ts
│   └── supabase/
├── supabase/migrations/
├── vercel.json
└── types/
```

## Database Schema

**RLS is enabled on every table below.** Policies scope family data to the authenticated owner and permit service-role access only for controlled webhook, cron, and deletion workflows.

| Table | Purpose |
| --- | --- |
| `users` | Parent profile, plan entitlement, Stripe identifiers, timezone, and privacy-request state. |
| `children` | Parent-owned child profiles and planning preferences. |
| `events` | Family events, sync metadata, source calendar IDs, and conflict-relevant timing. |
| `milestones` | Milestone records, due dates, reminder rules, and delivery state. |
| `finance_entries` | Income, expenses, recurring bills, categories, and budgeting metadata. |
| `assistance_matches` | Assistance program recommendations, eligibility notes, and application status. |
| `ai_drafts` | Generated school communication drafts, inputs, edits, and retention metadata. |
| `childcare_options` | Childcare providers, availability notes, costs, location, and user save state. |

## Getting Started

### Prerequisites

- Node.js 20.9+
- npm 10+ or pnpm
- Supabase CLI and a Supabase project
- OpenAI API access
- Google Cloud OAuth credentials with Calendar API enabled
- Stripe account and Stripe CLI
- Resend account with a verified domain

### Local setup

1. Clone and install.

   ```bash
   git clone https://github.com/your-org/keiru-ai.git
   cd keiru-ai
   npm install
   ```

2. Create a Supabase project and configure Auth redirect URLs:

   ```text
   http://localhost:3000/auth/callback
   ```

3. Link Supabase and apply migrations.

   ```bash
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push
   ```

4. In Google Cloud, enable the Google Calendar API. Add this local OAuth redirect URI:

   ```text
   http://localhost:3000/api/calendar/google/callback
   ```

5. Copy and populate local configuration.

   ```bash
   cp .env.example .env.local
   ```

6. Create Free, Pro, and Family Stripe products/prices. Register a webhook at `/api/stripe/webhook`.

7. Start development and, in another terminal, forward Stripe events.

   ```bash
   npm run dev
   stripe listen --forward-to localhost:3000/api/stripe/webhook
   ```

## Environment Variables

| Variable | Description | Required |
| --- | --- | --- |
| `NEXT_PUBLIC_APP_URL` | Application origin used for callbacks and links. | Yes |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase URL. | Yes |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public Supabase anon key. | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-only key for cron, webhooks, exports, and deletion. | Yes |
| `OPENAI_API_KEY` | Key for school-communication generation. | Yes |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID. | Yes |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret. | Yes |
| `GOOGLE_REDIRECT_URI` | Calendar OAuth callback URL. | Yes |
| `STRIPE_SECRET_KEY` | Stripe secret key. | Yes |
| `STRIPE_WEBHOOK_SECRET` | Webhook signature secret. | Yes |
| `STRIPE_PRO_PRICE_ID` | Monthly or annual Pro price. | Yes |
| `STRIPE_FAMILY_PRICE_ID` | Monthly or annual Family price. | Yes |
| `RESEND_API_KEY` | Resend email API key. | Yes |
| `EMAIL_FROM` | Verified reminder sender. | Yes |
| `CRON_SECRET` | Shared bearer secret for Vercel Cron requests. | Yes |

## API Reference

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/api/calendar/google/connect` | Starts Google Calendar OAuth. |
| `POST` | `/api/calendar/google/sync` | Imports or reconciles connected Google events. |
| `GET` | `/api/calendar/ical` | Exports the authenticated family calendar as iCalendar. |
| `POST` | `/api/events/conflicts` | Detects event overlaps and planning conflicts. |
| `POST` | `/api/ai/school-drafts` | Produces an editable school message draft. |
| `POST` | `/api/assistance/match` | Calculates and saves assistance-program matches. |
| `POST` | `/api/milestones/reminders` | Cron-only endpoint that sends due reminder emails. |
| `GET` | `/api/privacy/export` | Builds a user-scoped data export. |
| `DELETE` | `/api/privacy/account` | Starts authenticated account deletion. |
| `POST` | `/api/stripe/checkout` | Creates a selected plan Checkout Session. |
| `POST` | `/api/stripe/webhook` | Synchronizes subscription state from Stripe. |

## Payments & Subscriptions

| Tier | Includes |
| --- | --- |
| Free | Child profiles, core calendar, basic milestones, and limited planning tools. |
| Pro | Expanded AI drafting, finance and assistance workflows, advanced calendar tools, and Google Calendar sync. |
| Family | Pro capabilities with expanded household capacity and shared family planning features. |

Stripe Checkout is created server-side after validating the requested price. Webhook processing handles `checkout.session.completed`, subscription updates/deletions, and payment failures, then writes entitlement state to `users`. The app gates plan-specific server actions rather than trusting a browser-supplied tier. Subscribers manage billing through the Stripe Customer Portal.

## Deployment

1. Run migrations in production: `supabase link --project-ref <prod-ref> && supabase db push`.
2. Add production Auth and Google OAuth callback URLs.
3. Deploy the repository to Vercel and add all production environment variables.
4. Configure Stripe’s production webhook as `https://<domain>/api/stripe/webhook`.
5. Configure `vercel.json` to invoke `/api/milestones/reminders` on the intended schedule; keep `CRON_SECRET` configured and validate it in the handler.
6. Verify the Resend domain before enabling reminders.
7. Test Google token refresh, cancellation webhooks, iCal export, and GDPR export/delete flows in production-like staging.

## Roadmap

- Shared caregiver roles with explicit, revocable permissions.
- School district calendar imports and event templates.
- Better childcare availability integrations.
- Cash-flow forecasting and benefit renewal reminders.
- Localized assistance catalogs and multilingual school drafts.

## Contributing

Open an issue for product or schema changes before implementing them. Use least-privilege RLS policies, never log child or finance data, and add tests for cron idempotency, calendar sync, and subscription gates. Before submitting a PR, run `npm run lint`, `npm run typecheck`, and the test suite.

## License

Released under the [MIT License](LICENSE).