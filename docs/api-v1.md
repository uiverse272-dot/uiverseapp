# Uiverse mobile API, v1

Contract between the Flutter app and the web backend (`uiverse.tech`). The app is built against this
document and `tool/fake_server.dart`; the routes below do not exist on web yet. Request and response
examples live in `test/api/fixtures/`, and tests parse them, so a change here must change those too.

## Conventions

- JSON bodies, `Content-Type: application/json`.
- Signed-in calls send `Authorization: Bearer <token>`. The app never sends `Cookie`.
- Errors are JSON: `{"error": "<code>"}`, plus `minutes` on a form rate limit.
- Timestamps are epoch milliseconds.

| Status | Meaning | App behaviour |
|---|---|---|
| 200 | Done | |
| 400 | Malformed, or `SESSION_EXPIRED` on delete-user | Delete asks to sign in again |
| 401 | Not signed in or session ended | Keep local data, prompt to sign in |
| 422 | Refused for good, with an error code | Saves: drop the op, resync. Forms: show the field |
| 429 | Rate limited; send `Retry-After` in seconds | Wait, then retry |
| 503 | Accounts or database off. Never 401 for this | Retry later, keep the session |
| 5xx | Server failure | Back off, retry |

## Saves

Thin wrappers over `src/lib/saves/db.ts`, with `currentUser()` for auth. `auth.api.getSession` reads
the `Authorization` header once the `bearer()` plugin is on. Note that `context()` in
`components/save/actions.ts` returns null for both "signed out" and "no database"; these routes must
tell them apart (401 and 503).

### `GET /api/v1/saves`

Returns `SavesState`, as `loadSaves` does. See `fixtures/saves_state.json`.

```json
{
  "saves": [{"slug": "s001-ledgerly-homepage", "at": 1759000000000, "note": ""}],
  "collections": [{"id": "refs", "name": "Refs", "description": ""}],
  "pins": [{"slug": "s001-ledgerly-homepage", "collectionId": "refs", "at": 1759000000000}]
}
```

`saves` and `pins` may name designs the app's catalog lacks. The app keeps them.

### `POST /api/v1/saves/sync`

Body `{"guest": GuestState}`, wrapping `importSaves`. Returns the merged `SavesState`. Must stay safe
to repeat: the app retries a merge it never saw finish. `importSaves` already is, because every
insert is `onConflictDoNothing`.

### `POST /api/v1/saves/op`

Body is one `SaveOp`, the type in `components/save/actions.ts`, plus an optional `at`:

```json
{"type": "set", "slug": "s001-ledgerly-homepage", "saved": true, "at": 1759000000000}
{"type": "pin", "slug": "s001-ledgerly-homepage", "collectionId": "refs", "pinned": true, "at": 1759000000000}
{"type": "create", "id": "refs", "name": "Refs", "description": ""}
{"type": "update", "id": "refs", "name": "Refs", "description": "Client work"}
{"type": "delete", "id": "refs"}
{"type": "note", "slug": "s001-ledgerly-homepage", "note": "spacing"}
```

Returns `{"ok": true}`. Pass `at` through to `setSaved` and `setPinned`, which already accept it, so
a save made offline keeps its real time. Ops are sent one at a time, in order, and must stay
idempotent. Rate limit as `saveOp`: 120 a minute per user.

422 codes are `SavesError` codes: `unknown-item`, `unknown-collection`, `invalid`, `limit`.

## Forms

Public, no auth. Same logic, limits and honeypot as `submitFind` and `requestTakedown`, with JSON in
place of `FormData`: `confirm` is a boolean. Move the validation out of the server actions into
shared functions so both entry points stay the same.

### `POST /api/v1/finds`

```json
{
  "title": "Tidal", "creator": "Ana", "email": "ana@example.com",
  "url": "https://example.com/tidal", "imageUrl": "https://example.com/tidal.png",
  "creatorUrl": "", "tags": ["motion"], "note": "", "confirm": true
}
```

Returns `{"ref": "FD-20261101-A1B2C3", "email": "ana@example.com"}`.

422 `error`: `title`, `creator`, `email`, `url`, `imageUrl`, `creatorUrl`, `confirm`.
429: `{"error": "rate", "minutes": 42}`. 502: `{"error": "failed"}`.

### `POST /api/v1/takedowns`

```json
{"domain": "example.com", "name": "Ana", "email": "ana@example.com", "role": "owner", "details": "", "confirm": true}
```

Returns `{"ref": "TD-20261101-A1B2C3", "domain": "example.com", "email": "ana@example.com", "held": 3}`.

422 `error`: `domain`, `name`, `email`, `confirm`. 429 and 502 as above.

## Mobile sign-in

The app opens the system browser and comes back through `uiverse://auth`. Any app can register a
custom scheme, so the token in that link is bound to a verifier only this install holds.

1. App makes a random `verifier`, keeps it in secure storage (it must survive the process being
   killed while the browser is open), and computes `c = base64url(sha256(verifier))`, no padding.
2. App starts sign-in:
   - Link: `POST /api/mobile/magic-link {"email", "c"}` returns `{"ok": true}`. The emailed link ends
     at step 3 with `c` carried through.
   - OAuth: open `GET /api/mobile/start?provider=google|apple&c=<c>` in the browser.
3. `GET /api/mobile/done?c=<c>` runs with the new session cookie. It creates a one-time token bound
   to `c` and returns an HTML page (`Cache-Control: no-store`) with an "Open Uiverse" button linking
   to `uiverse://auth?token=<token>`. It may also try the redirect, but the button must exist:
   automatic scheme redirects get blocked, and a link opened on a desktop needs somewhere to end.
   On failure it links to `uiverse://auth?error=<code>`, via `errorCallbackURL`.
4. App exchanges: `POST /api/mobile/exchange {"token", "verifier"}` returns
   `{"token": "<session token>", "user": {"id", "email", "name", "image"}}`. Single use. 401 if the
   token is unknown, used or expired, or if `sha256(verifier)` is not the `c` it was bound to.

The app ignores any `uiverse://auth` link while no verifier is pending. That also stops someone
signing the app into their own account with a crafted link.

Routes sit under `/api/mobile/`, not `/mobile/`: `proxy.ts` rewrites page paths under `[lang]`.

## Account

- `POST /api/auth/sign-out`, `Authorization: Bearer`.
- `POST /api/auth/delete-user`, `Authorization: Bearer`, body `{}`. Cascades through saves, boards and
  pins. Only a session under an hour old may delete; otherwise 400 `{"code": "SESSION_EXPIRED"}`. The
  app then asks for a fresh sign-in and returns to the account page, where the person confirms by
  typing the address shown, so a sign-in as someone else can't delete the wrong account.

## Web checklist

In `src/lib/auth.ts`:

- [ ] Add `bearer()` and `oneTimeToken()`, before `nextCookies()`.
- [ ] Put `/one-time-token/generate` and `/one-time-token/verify` in `disabledPaths`, so the HTTP
      routes are off and only `/api/mobile/*` reaches them through `auth.api`. Set
      `disableClientRequest` and `disableSetSessionCookie`.
- [ ] Bind token to `c` server-side, for example an HMAC over both, and check it in `exchange`.
- [ ] Apple provider, with `https://appleid.apple.com` in `trustedOrigins`. Do not add `uiverse://`:
      our own route does that redirect and a same-origin `callbackURL` already passes.
- [ ] Apple's client secret expires within 6 months: note the rotation. Check whether deletion must
      revoke Apple tokens.
- [ ] Privacy policy and account copy name Google and GitHub; add Apple.
- [ ] Decide session lifetime. Inactive sessions die after 7 days, and a longer `expiresIn` also
      changes web.

Routes: `src/app/api/v1/{saves,saves/sync,saves/op,finds,takedowns}` and
`src/app/api/mobile/{start,magic-link,done,exchange}`.

**Security, check first:** the migrations define no RLS, and the `public` tables hold session and
OAuth tokens. Confirm Supabase's Data API cannot reach them with the anon key.

Also: limits in `rateLimit.ts` live in memory, so they apply per instance. Public JSON form endpoints
are easier to script than server actions, so consider a shared limiter.
