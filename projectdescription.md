# TenjoMovil - Project Description

## Overview
A delivery app platform for a small town (~15,000 people max), connecting **consumers**, **delivery drivers**, and **restaurants/stores** through role-specific mobile apps, backed by a shared backend and an admin platform for onboarding merchants.

---

## Tech Stack

### Mobile Apps (Consumer, Driver, Restaurant)
- **Framework:** Flutter (Dart)
- **Why:** Excellent performance on low-end Android phones (important for drivers), smooth map/real-time animations, true single-codebase for iOS + Android, lower battery drain than React Native, pairs well with a modern .NET backend.
- **State Management:** Riverpod (suggested)
- **Structure:** Single Flutter codebase, role-based UI split into `/features/consumer`, `/features/driver`, `/features/restaurant`, with shared `/core` (models, services, utils).

### Admin Web Platform
- **Framework:** React (or Blazor, since backend is .NET)
- **Why:** Admins need a desktop-friendly experience — map interface, data tables, bulk actions. Not a good fit for mobile-first Flutter.
- **Key feature (v1):** Map-based store enrollment tool — admin selects a location on the map, enters store details, and sends an email invitation to the store owner.

### Backend
- **Framework:** ASP.NET Core (.NET 8+)
- **Why:** Mature, scalable, cross-platform, strong typing, excellent tooling, built-in real-time support via SignalR.
- **Real-time:** SignalR (order status updates, driver location broadcasting).
- **Background jobs:** Hangfire (for notifications, scheduled tasks).

### Database
- **Primary:** PostgreSQL (with PostGIS for geospatial queries — driver matching, delivery zones, distance calculations).
- **Caching:** Redis (planned, for real-time order status / driver locations at scale).

### Notifications
- **Push notifications:** Firebase Cloud Messaging (FCM) — free tier, integrates natively with Flutter.
- **SMS fallback:** Twilio — used for driver notifications in case of unreliable push delivery (older phones, poor connectivity).

### Maps & Routing
- **Chosen candidate:** Mapbox — better route optimization for multi-stop deliveries, custom branding/styling, offline map support.
- **Alternative:** Google Maps API — better raw accuracy/global coverage, simpler integration, but higher cost per request and less routing flexibility.
- **Decision:** Leaning Mapbox for delivery-specific routing needs; Google Maps remains a fallback if regional map data quality is better for the town in question.

### Email Service (Admin → Store Invitations)
- **SendGrid** (free tier: 100 emails/day, sufficient for small-town scale).

### Hosting (target: 15,000-person town scale)
| Service | Provider | Est. Cost |
|---|---|---|
| Backend hosting | DigitalOcean App Platform | ~$12/month |
| Database | DigitalOcean Managed PostgreSQL | ~$15/month |
| Push notifications | Firebase | Free tier |
| Maps/routing | Mapbox | ~$10-50/month (usage-based) |
| Domain | Namecheap/GoDaddy | ~$12/year |
| **Estimated total** | | **~$40-60/month** |

Alternative considered: Azure App Service (native .NET fit, ~$15-50/month) — viable if deeper Azure ecosystem integration is desired later (e.g. Azure AD, Azure Maps).

---

## App Publishing
- **Google Play Console:** $25 one-time registration fee. Release via `flutter build appbundle --release`, signed `.aab` upload.
- **Apple App Store:** $99/year Apple Developer Program. Release via `flutter build ios --release`, archived and uploaded through Xcode/Transporter to App Store Connect.
- Both require: privacy policy, support contact, app icon (1024x1024), screenshots, and justification for permissions (location, camera, etc).

---

## System Architecture

```
Admin Web Portal (React)
        │
        ▼
ASP.NET Core API (.NET 8+)
        │
        ├── PostgreSQL (stores, users, invitations, orders)
        ├── SignalR (real-time order/driver updates)
        ├── SendGrid (invitation emails)
        ├── Firebase (push notifications)
        ├── Twilio (SMS fallback)
        └── Mapbox / Google Maps (routing, geolocation)
        │
        ▼
Flutter Apps (role-based UI)
    ├── Consumer App
    ├── Driver App
    └── Restaurant App
```

---

## Data Model (initial)

### stores
- id, name, address, latitude, longitude, phone, category, status (pending/invited/active/suspended), created_by, created_at, activated_at

### invitations
- id, store_id, email, token, status (sent/opened/completed/expired), expires_at, created_at

### restaurant_users
- id, store_id, email, password_hash, name, role (owner/manager/staff), created_at, last_login

*(consumer, driver, and order tables to be defined in later phases)*

---

## Build Order / Roadmap

1. **Admin platform — store enrollment via map** (current phase)
   - Admin selects location on map, enters store info, sends invitation email.
2. **Store owner signup + login flow**
   - Secure token-based invitation link, password setup, JWT login.
3. **Basic restaurant portal**
   - Login + placeholder dashboard ("orders coming soon").
4. **Consumer app**
   - Browse enrolled restaurants, place orders.
5. **Driver app**
   - Accept deliveries, real-time tracking, earnings.
6. **Real-time order flow end-to-end**
   - Restaurant receives order → driver accepts → consumer tracks live.

---

## Key Design Principles
- **Role separation:** Each user type (consumer/driver/restaurant/admin) gets its own isolated UI flow — no mixed navigation.
- **Shared core:** Common models/services live in a shared layer to avoid duplication across Flutter role modules.
- **Backend-enforced authorization:** Role checks happen server-side (`[Authorize(Roles = "...")]`), not just hidden in the UI.
- **Start with supply side:** Onboard restaurants first via the admin tool before building full order flow — enables early real-world traction while the rest of the app is built.

---

*Last updated: reflects architecture and stack decisions as of project kickoff conversation.*
