# ADR-0005: Original Naming for Map, Modes, and Currencies

**Status:** Accepted
**Date:** 2026-07-04

## Context

Building the splash/loading/lobby UI prototype required concrete
placeholder content: a map name, game modes, and in-game currencies.
Reference images supplied for layout inspiration used real Call of
Duty trademarks and copyrighted character art (Verdansk, Rebirth
Island, Rust, Plunder, Blood Money, the "Ghost" skull-mask character,
and a wordmark treatment that closely copies Call of Duty: Warzone's
actual trade dress). None of that can be used, per this project's own
rule against copying names/assets from existing titles.

## Decision

Original content introduced for the UI prototype (Phase 9/11 territory,
built early per explicit request — see PHASE_04 report):

- **Map:** "Meridian" — the project's original battle royale map
  (still greybox/unbuilt; Phase 10 remains where it's actually
  constructed. This is just the name reserved for it).
- **Modes:** "Battle Royale" (generic genre term, not itself
  trademarked) on Meridian; "Skirmish" as an original small-team mode
  name, replacing the reference image's "Team Deathmatch on Rust".
- **Currencies:** "Credits" (soft/earned currency) and "Marks"
  (premium/purchased currency), replacing the reference image's
  "CP"/cash-pile iconography.
- **Player character representation:** no specific character art or
  mask design — the lobby prototype uses a generic silhouette
  placeholder, since a distinctive named/masked character design is
  exactly the kind of thing that reads as "copying a character" even
  when original, until real concept art exists.

## Consequences

- These names are placeholders in the sense that art/lore may refine
  them later (e.g. Phase 10's actual map design may suggest a better
  name than "Meridian") — but they are original starting points, not
  provisional copies of someone else's trademark.
- Any future contributor adding UI mockups or reference art should
  route it through this same filter: genre conventions (HUD layout,
  currency-in-corner, mode-select cards) are fine to draw inspiration
  from; specific names, character designs, and logo trade dress from
  existing commercial titles are not.

## Addendum (Phase 6): Additional Names from a Second Reference Round

A second round of reference images (for login/lobby layout) surfaced
different concerns than the first: not trademarked map/mode names this
time, but **branded mechanic names from specific existing titles**, and
Activision's product name appearing inside in-game content rather than
just as our own external project codename. Replaced:

- **"Luck Royale"** (a named Garena Free Fire gacha-style feature) →
  **"Fortune Cache"**
- **"Shadow Strike"** (promo bundle name, resembling existing
  operator/bundle naming conventions) → **"Nightfall Bundle"**
- **"Warzone Championship"** / **"Warzone Royale"** (puts Activision's
  product name inside actual game content, not just our external
  codename) → **"Founders Cup"** (event), map/mode stay **Meridian**/
  **Battle Royale** as already established above
- **"Battle Pass"** — not copied from a specific title, but has real
  trademark history (Epic Games) attached to the exact phrase →
  **"Season Path"**, to be safe rather than rely on how genericized the
  term has become

Same filter as above: the underlying mechanics (a progression track, a
gacha-style feature, a live competitive event, a promo bundle) are
completely ordinary genre conventions and fine to build — only the
specific names were the issue.
