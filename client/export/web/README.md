# Web export — Firebase wiring

Google/Email login only works in the HTML5/Web export today (see
`features/authentication/README.md`). This folder is where the
Firebase glue for that export lives.

## One-time setup

1. **Firebase console** (https://console.firebase.google.com):
   - Create a project (or use an existing one).
   - Build → Authentication → Sign-in method → enable **Google** and
     **Email/Password**.
   - Project settings → General → "Your apps" → add a **Web app** →
     copy the config object it gives you.
   - Project settings → General → copy the **Project ID** too (you'll
     need it separately for the server).

2. **Client config**:
   - Copy `firebase_config.example.js` → `firebase_config.js` in this
     same folder and paste in your real config. This file is
     gitignored (add it to `.gitignore` if it isn't already) — never
     commit real Firebase keys.

3. **Server config** — already scaffolded in
   `infra/docker/nakama/local.yml` under `runtime.env`. Replace the
   placeholder with your real Firebase **Project ID**:
   ```yaml
   runtime:
     env:
       - "FIREBASE_PROJECT_ID=your-real-project-id"
   ```
   This is what `server/modules/authentication` uses to verify Google
   ID tokens before letting `authenticateCustom` succeed (see
   ADR-0004). Restart the Nakama container after changing it.

4. **Godot export shell**:
   - Project → Export → Web preset → check **Custom HTML Shell** and
     point it at a copy of Godot's default shell (Godot gives you one
     to start from when you check that box — save it here as
     `index.html`).
   - Right before the closing `</body>` tag (after Godot's own engine
     script tags), add:
     ```html
     <script type="module" src="firebase_config.js"></script>
     <script type="module" src="firebase_auth_shim.js"></script>
     ```
   - Export → make sure both `firebase_config.js` and
     `features/authentication/infrastructure/web/firebase_auth_shim.js`
     get copied alongside the exported `index.html` (add them as
     "Export Files" in the export preset if Godot doesn't pick them up
     automatically since they're plain `.js`, not Godot resources).

## Testing the flow end-to-end

1. `cd infra/docker && docker compose up -d` (with your `.env` and the
   updated `local.yml`).
2. Export and run the Web build (or `godot --path client --export-debug Web export/web/index.html` then serve it — file:// won't work for Google's popup flow, use a local HTTP server).
3. On the login screen, "Sign in with Google" should pop up Google's
   auth window, then hand off to Nakama automatically.
4. Check `warzone_accounts` in Postgres (or Nakama's console at
   `:7351`) for a newly provisioned account after a successful login.

## What still doesn't work here

Native Android/iOS Google/Email login needs Firebase's native SDKs
via a real Godot GDExtension plugin — not built yet (see
`features/authentication/README.md`). Guest login has no such
limitation and works everywhere already.
