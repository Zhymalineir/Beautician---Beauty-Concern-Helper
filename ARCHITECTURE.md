# Beautician — Architecture

Beautician is a web app that profiles a user's skin and face, then recommends matching products (shade, colour, ingredients) and makeup styles. The profile is saved so the user can come back to it.

## 1. User flow

```
Start
  └─► Profile Setup (Undertone, Depth, Skin type, Face shape, Skin concerns)
        ├─► Undertone Test   (Photo, Vein Test, T-shirt Test)
        ├─► Depth Test       (Photo analysis)
        ├─► Face Shape Test  (Photo filter)
        └─► Skin Type Test   (Quiz)
              │  (the four tests can be taken in any order; the user can move
              │   back and forth between them before continuing)
              ▼
        Matching Engine (Shade, Colour, Product Ingredients)
              ├─► Product Recommendation
              └─► Makeup Style Recommendation
                        ▼
                   Save Profile
                        ▼
                       End
```

| Step | What happens | Output |
|---|---|---|
| Profile Setup | User creates a profile and picks skin concerns (acne, dryness, redness, hyperpigmentation, ageing, etc.). Any trait they already know (e.g. "I'm warm-toned") can be entered manually and its test skipped. | `profile` record with known traits + concerns |
| Undertone Test | Three methods, combined into one result: **Photo** (AI reads undertone from a face photo), **Vein Test** (user picks vein colour: green / blue / mix), **T-shirt Test** (user picks whether white or off-white looks better). | `undertone`: `warm` \| `cool` \| `neutral` \| `olive`, plus confidence |
| Depth Test | AI reads skin depth from a face photo taken in natural light. | `depth`: `fair` \| `light` \| `medium` \| `tan` \| `deep` \| `rich` (or a 1–10 scale) |
| Face Shape Test | Face photo with an outline overlay ("photo filter"); AI classifies the shape. | `face_shape`: `oval` \| `round` \| `square` \| `heart` \| `diamond` \| `oblong` |
| Skin Type Test | Short multiple-choice quiz, scored locally. | `skin_type`: `oily` \| `dry` \| `combination` \| `normal` \| `sensitive` |
| Matching Engine | Combines all traits and concerns and scores the product catalogue. | Ranked products and style IDs |
| Product Recommendation | Foundation / concealer / blush / lipstick shades and skincare whose ingredients fit the skin type and concerns. | Product list with reasons |
| Makeup Style Recommendation | Contouring, blush placement, brows and colour palette suited to face shape and undertone. | Style cards |
| Save Profile | Results and recommendations are stored against the user. | Saved `profile` + `recommendations` |

## 2. System overview

```
┌──────────────────────────┐        ┌───────────────────────────────┐
│  Frontend (Vercel)       │        │  Serverless API (Vercel /api) │
│  HTML + CSS + JS         │──────► │  /api/analyze-photo           │──► Vision AI model
│  - profile setup         │        │  /api/match                   │
│  - test screens          │        │  /api/profile                 │
│  - results screens       │        └──────────────┬────────────────┘
└────────────┬─────────────┘                       │
             │ auth + data                         │
             ▼                                     ▼
      ┌───────────────────────────────────────────────────┐
      │ Supabase (or Firebase)                            │
      │  - Auth (email / Google)                          │
      │  - Database: profiles, test_results, products,    │
      │    styles, recommendations                        │
      │  - Storage: face photos (private bucket)          │
      └───────────────────────────────────────────────────┘
```

- **Frontend:** builds on the existing `index.html`, `style.css`, `script.js` (vanilla HTML/CSS/JS, no build step). Split into ES modules as it grows (see §5).
- **API:** Vercel serverless functions in `/api`. These hold the AI API key and the backend service key so neither ever reaches the browser.
- **AI photo analysis:** one vision-model call per photo test with a strict JSON response format. The model is set by the `VISION_MODEL` environment variable so it can be swapped.
- **Backend:** Supabase is the default (Postgres + Auth + Storage). Firebase works too (Firestore + Auth + Storage); only `lib/db.js` changes.

## 3. Components

### 3.1 Frontend screens
1. **Landing / Start:** sign in or continue.
2. **Profile Setup:** name, known traits (optional), skin concerns (multi-select).
3. **Test Hub:** four cards (Undertone, Depth, Face Shape, Skin Type) with done / not-done status; free navigation between them.
4. **Undertone Test:** photo capture/upload, vein colour picker, T-shirt comparison.
5. **Depth Test:** photo capture/upload with lighting tips.
6. **Face Shape Test:** camera view with face-outline overlay, then upload.
7. **Skin Type Quiz:** around 8 questions, one per screen.
8. **Results:** product recommendations tab + makeup style tab.
9. **Saved Profile:** view, retake a test, delete profile and photos.

### 3.2 API endpoints
| Endpoint | Method | Input | Output |
|---|---|---|---|
| `/api/analyze-photo` | POST | `{ test: "undertone"\|"depth"\|"face_shape", imagePath }` | `{ value, confidence, notes }` |
| `/api/match` | POST | `{ profileId }` | `{ products: [...], styles: [...] }` |
| `/api/profile` | GET / PUT / DELETE | profile fields | profile JSON |

All endpoints check the user's auth token before doing anything.

### 3.3 Matching Engine
Rule-based scoring, not an AI call, so results are predictable and cheap:

1. **Shade match:** filter base products where `product.undertones` contains the user's undertone and `product.depth` is within ±1 of the user's depth.
2. **Colour match:** score blush/lip/eye colours by undertone palette (warm → corals, peaches, golds; cool → pinks, berries, silvers; neutral → both; olive → muted, earthy tones).
3. **Ingredient match:** add points for ingredients that suit the skin type/concerns (e.g. oily → niacinamide, salicylic acid; dry → hyaluronic acid, ceramides), and remove products with flagged ingredients (e.g. sensitive → fragrance, alcohol denat.).
4. **Style match:** look up styles tagged with the user's face shape + undertone.
5. Return the top N per category, each with a short "why it suits you" reason.

The rules live in one config file (`lib/rules.js`) so they can be tuned without touching logic.

## 4. Data model

```
profiles
  id (uuid, = auth user id)   name   created_at   updated_at
  undertone   undertone_confidence
  depth       depth_confidence
  face_shape  skin_type
  concerns (text[])

test_results            -- raw answers per test, for retakes/history
  id  profile_id  test (undertone|depth|face_shape|skin_type)
  method (photo|vein|tshirt|quiz)  raw (jsonb)  result  created_at

products
  id  name  brand  category (foundation|concealer|blush|lip|eye|skincare)
  shade_name  depth  undertones (text[])  colour_hex
  ingredients (text[])  good_for (text[])  avoid_for (text[])  url

styles
  id  name  description  face_shapes (text[])  undertones (text[])  image_url

recommendations
  id  profile_id  product_ids (uuid[])  style_ids (uuid[])  created_at
```

- **Storage:** private `face-photos` bucket, path `{user_id}/{test}/{timestamp}.jpg`.
- **Row-level security:** users can only read/write rows where `profile_id = auth.uid()`. `products` and `styles` are read-only for everyone.

## 5. Folder structure (target)

```
TestFolder/
├── index.html
├── style.css
├── script.js              # app entry, router
├── js/
│   ├── screens/           # one module per screen
│   ├── tests/             # undertone.js, depth.js, faceShape.js, skinQuiz.js
│   ├── camera.js          # capture + face-outline overlay
│   └── api.js             # calls to /api/*
├── api/
│   ├── analyze-photo.js
│   ├── match.js
│   └── profile.js
├── lib/
│   ├── db.js              # Supabase/Firebase client (the only backend-specific file)
│   ├── rules.js           # matching rules config
│   └── matcher.js         # matching engine
├── data/
│   ├── products.seed.json
│   └── styles.seed.json
├── supabase/schema.sql
├── ARCHITECTURE.md
├── PLAN.md
└── PROGRESS.md
```

## 6. Privacy & safety
- Face photos are personal data: store them in a private bucket, send them only to the vision API, and let users delete their photos and profile at any time.
- Ask for consent before the first photo upload and say what the photo is used for.
- Photo results are estimates. Show the confidence level and let users override any result manually.
- Lighting affects results, so show tips (natural light, no filter, no makeup) before each capture.

## 7. Environment variables
| Name | Where | Purpose |
|---|---|---|
| `SUPABASE_URL` | Vercel + frontend | Project URL |
| `SUPABASE_ANON_KEY` | Vercel + frontend | Public client key (safe with RLS) |
| `SUPABASE_SERVICE_ROLE_KEY` | Vercel only | Server-side writes |
| `AI_API_KEY` | Vercel only | Vision model key |
| `VISION_MODEL` | Vercel only | Model ID for photo analysis |

If you use Firebase instead, swap in the Firebase config values and a service-account key.

