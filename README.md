# Esports Latency Optimizer — Reference Implementation

This is a runnable **reference scaffold**: real backend code, real Flutter
app structure, real relay-selection logic. Read this file before you assume
anything is "production-ready" — a few pieces are explicitly out of scope
for any zip file and require real-world setup (accounts, servers, devices).

## What works out of the box

### Backend (`/backend`)
- Express + Socket.io server, runs with `npm install && npm start`
- Falls back to an **in-memory store** if you don't set `DATABASE_URL`, so
  you can run it in 30 seconds with no Postgres install
- JWT auth, register/login, relay listing, relay selection endpoint
- A transparent heuristic relay-scoring engine (`services/routingEngine.js`)
  — this replaces the "pre-trained TensorFlow model" from the original
  spec. That model needs real historical latency data to train; nobody can
  hand you a working one without that data. The heuristic is a legitimate,
  usable starting point that you can swap for a real ML model later without
  changing the API surface.

Run it:
```bash
cd backend
cp .env.example .env
npm install
npm start
# or with Docker: docker compose up --build   (from repo root)
```
Health check: `GET http://localhost:3000/health`

### Flutter app (`/flutter_app`)
- Full dashboard: real-time ping gauge, latency history chart, stability
  stats, Riverpod state management, WebSocket client
- Points at the backend above via `--dart-define=API_BASE_URL=...`

Run it (requires Flutter SDK installed on your machine — not available in
this sandbox):
```bash
cd flutter_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=WS_URL=ws://localhost:3000
```

## What this zip deliberately does NOT include, and why

**1. Native VPN tunneling (Android `VpnService`, iOS `NetworkExtension`)**
Actually intercepting and rerouting device traffic requires:
- An Apple Developer Program account ($99/yr) + a Packet Tunnel Provider
  entitlement Apple grants per-app after review
- A Google Play developer account + the app declaring VPN permissions
- Physical or emulator testing with real network interfaces
No code sample can make this "fully working" without those accounts and a
real device — writing fake Kotlin/Swift files that can't be compiled or
tested here would just be misleading. Once you have those accounts, the
Android `VpnService` / iOS `NEPacketTunnelProvider` APIs are the right ones
to build against — happy to help write that code against your actual Xcode
project or Android Studio project where it can be compiled and tested.

**2. The relay server network**
The "relay nodes in US/EU/APAC" need actual servers deployed to actual
cloud regions, actually reachable from the internet, actually relaying
traffic. `backend/db/schema.sql` seeds 4 fake relay rows so the API has
something to return — replace `ip_address` with real reachable relays
before this does anything useful.

**3. Payments**
`/api/subscription/upgrade-premium` returns `501 Not Implemented` on
purpose. Wiring fake "success" responses would mean the app claims to have
charged a card when nothing happened. Real integration needs a Stripe
account, a webhook endpoint, and PCI-considerations — ask me to build the
webhook handler once you have Stripe keys.

**4. The ML relay-selection model**
See the routing engine note above — a `.h5`/`.tflite` file with random or
fabricated weights would just add latency for no benefit. The heuristic
scorer is the honest MVP; train a real model once you're logging real
`network_metrics` rows.

## Suggested next steps, in order
1. Run the backend locally, confirm `/health` and `/api/relays` work
2. Get the Flutter app talking to it in an emulator (mocked network data,
   no VPN yet) to validate UI/UX
3. Set up a Google Play + Apple Developer account, then build the native
   VPN piece against a real Xcode/Android Studio project
4. Rent 2-3 real relay servers (even just plain cloud VMs) and point the
   `relay_servers` table at them
5. Add Stripe once you have a live product to sell
