class_name MatchOpcodes
extends RefCounted
## Match message opcodes. MUST stay in sync with
## `server/modules/match_handler/src/domain/match_opcodes.ts` — see
## that file's docstring for the same note from the other side. No
## shared build step exists between TypeScript and GDScript in this
## project, so this sync is currently manual.

const PLAYER_INPUT: int = 1
const SNAPSHOT: int = 2
const POSITION_CORRECTION: int = 3
const WEAPON_FIRE_CLAIM: int = 4
const DAMAGE_EVENT: int = 5
const ELIMINATION_EVENT: int = 6
