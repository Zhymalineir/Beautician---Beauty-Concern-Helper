# Beautician — Build Plan

See [ARCHITECTURE.md](ARCHITECTURE.md) for the design. Log every work session in [PROGRESS.md](PROGRESS.md).

## Who does what

| Owner | Strengths | Gets tasks that are… |
|---|---|---|
| **Gemini 3.8 Flash** | Long multi-step coding, agentic work, image/video input, 1M-token context | Multi-file, architectural, or involve photo analysis / AI calls |
| **GPT-6 Luna** | Fast and cheap; good at single-file work, schemas, JSON and forms | Small, well-defined, single-file tasks |
| **User** | Owns accounts, keys and deploys | Vercel, Supabase/Firebase and API key setup |

**Status legend:** ⬜ Not started · 🟨 In progress · ✅ Done · ⛔ Blocked

**Rules for the AI models**
1. Only work on tasks assigned to you, in phase order. Don't start a phase until the previous one is ✅ (unless a task says otherwise).
2. When you start a task, set its status to 🟨. When it's finished and checked, set it to ✅.
3. If you need something from the user (keys, a decision), set the task to ⛔ and say why in PROGRESS.md.
4. Add an entry to PROGRESS.md every time you're prompted, even if nothing was finished.
5. Never commit API keys or secrets. Use environment variables (see ARCHITECTURE.md §7).
6. Always commit and push project changes to the user's repository.

---

## Phase 0: Setup (User)

| # | Task | Owner | Status |
|---|---|---|---|
| 0.1 | Create a Vercel account and import this folder as a project (or use `vercel` CLI) | User | ⬜ |
| 0.2 | Choose **Supabase** or **Firebase** and write the choice in PROGRESS.md | User | ⬜ |
| 0.3 | Create the Supabase/Firebase project; enable Auth (email and/or Google) | User | ⬜ |
| 0.4 | Create a private storage bucket named `face-photos` | User | ⬜ |
| 0.5 | Get a vision-model API key and pick the model ID | User | ⬜ |
| 0.6 | Add all env vars from ARCHITECTURE.md §7 in Vercel → Project → Settings → Environment Variables, and in a local `.env` (git-ignored) | User | ⬜ |
| 0.7 | Run `supabase/schema.sql` (made in 1.2) in the Supabase SQL editor, or set up the Firestore collections | User | ⬜ |

> Phase 1 can begin before Phase 0 is finished. Any task that needs live keys waits for 0.6.

## Phase 1: Foundation

| # | Task | Owner | Status |
|---|---|---|---|
| 1.1 | Restructure the project into the folder layout from ARCHITECTURE.md §5; add a hash-based router in `script.js` and empty screen modules | Gemini 3.8 Flash | ✅ |
| 1.2 | Write `supabase/schema.sql`: tables, enums and row-level security policies from ARCHITECTURE.md §4 | GPT-6 Luna | ✅ |
| 1.3 | Write `lib/db.js`: backend client wrapper (auth, profile CRUD, photo upload) | Gemini 3.8 Flash | ⬜ |
| 1.4 | Add `.gitignore` (`.env`, `node_modules`, `.vercel`), `.env.example` and `package.json` | GPT-6 Luna | ✅ |
| 1.5 | Base styles: colour tokens, buttons, cards, form inputs, mobile-first layout in `style.css` | GPT-6 Luna | ✅ |

## Phase 2: Profile Setup & Test Hub

| # | Task | Owner | Status |
|---|---|---|---|
| 2.1 | Start screen + sign-in / sign-up using `lib/db.js` | Gemini 3.8 Flash | ⬜ |
| 2.2 | Profile Setup screen: name, optional known traits, skin-concerns multi-select | GPT-6 Luna | ⬜ |
| 2.3 | Test Hub: four test cards showing done/not-done status, free navigation between tests | GPT-6 Luna | ⬜ |
| 2.4 | Photo consent screen + lighting tips component | GPT-6 Luna | ⬜ |

## Phase 3: The four tests

| # | Task | Owner | Status |
|---|---|---|---|
| 3.1 | `js/camera.js`: camera capture/upload, resize/compress, face-outline overlay | Gemini 3.8 Flash | ⬜ |
| 3.2 | `/api/analyze-photo`: auth check, fetch photo from storage, vision-model call with strict JSON output for undertone / depth / face_shape | Gemini 3.8 Flash | ⬜ |
| 3.3 | Undertone Test screen: photo + Vein Test picker + T-shirt Test, combined into one result with confidence | Gemini 3.8 Flash | ⬜ |
| 3.4 | Depth Test screen (photo → `/api/analyze-photo`) | GPT-6 Luna | ⬜ |
| 3.5 | Face Shape Test screen (camera overlay → `/api/analyze-photo`) | GPT-6 Luna | ⬜ |
| 3.6 | Skin Type Quiz: questions as JSON + local scoring function | GPT-6 Luna | ⬜ |
| 3.7 | Manual override: let the user correct any test result | GPT-6 Luna | ⬜ |

## Phase 4: Matching Engine

| # | Task | Owner | Status |
|---|---|---|---|
| 4.1 | `data/products.seed.json` (40+ products across categories) and `data/styles.seed.json` (one or more styles per face shape) | GPT-6 Luna | ⬜ |
| 4.2 | `lib/rules.js`: undertone palettes, depth tolerance, ingredient good/avoid lists per skin type and concern | GPT-6 Luna | ⬜ |
| 4.3 | `lib/matcher.js`: shade, colour, ingredient and style scoring, with "why it suits you" reasons (ARCHITECTURE.md §3.3) | Gemini 3.8 Flash | ⬜ |
| 4.4 | `/api/match` endpoint | Gemini 3.8 Flash | ⬜ |
| 4.5 | Unit tests for the matcher (one sample profile per undertone and skin type) | Gemini 3.8 Flash | ⬜ |
| 4.6 | Seed script to load the JSON into the database | GPT-6 Luna | ⬜ |

## Phase 5: Recommendations, Save Profile & End

| # | Task | Owner | Status |
|---|---|---|---|
| 5.1 | Product Recommendation screen: grouped by category, shade swatch, reason, link | GPT-6 Luna | ⬜ |
| 5.2 | Makeup Style Recommendation screen: style cards | GPT-6 Luna | ⬜ |
| 5.3 | Save Profile: store results + recommendations; `/api/profile` GET/PUT/DELETE | Gemini 3.8 Flash | ⬜ |
| 5.4 | Saved Profile screen: view, retake a test (re-runs matching), delete profile + photos | Gemini 3.8 Flash | ⬜ |
| 5.5 | End / summary screen | GPT-6 Luna | ⬜ |

## Phase 6: Polish & Launch

| # | Task | Owner | Status |
|---|---|---|---|
| 6.1 | Full end-to-end check of the flow (Start → End); fix bugs found | Gemini 3.8 Flash | ⬜ |
| 6.2 | Loading, error and empty states on every screen | GPT-6 Luna | ⬜ |
| 6.3 | Accessibility pass: labels, contrast, keyboard navigation | GPT-6 Luna | ⬜ |
| 6.4 | Write `README.md` with setup and run steps | GPT-6 Luna | ⬜ |
| 6.5 | Deploy to production on Vercel and test the live URL on a phone | User | ⬜ |

