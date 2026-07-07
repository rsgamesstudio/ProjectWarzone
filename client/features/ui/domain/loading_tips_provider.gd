class_name LoadingTipsProvider
extends RefCounted
## Cycles through the loading screen's rotating tip text. Pure logic,
## no engine/scene dependency, so it's fully unit-testable — the
## `loading_screen.gd` presentation script just calls `next()` on a
## timer and sets a Label's text.
##
## Tips are original copy — no borrowed phrasing from any other game.

const TIPS: Array[String] = [
	"Stay aware of the shrinking safe zone — it never stops moving.",
	"Loot smart, not everything is worth carrying.",
	"Coordinate with your squad before pushing a fight.",
	"High ground wins more fights than a better weapon does.",
	"Vehicles are loud — expect company if you drive through a hot zone.",
]

var _index: int = 0

func current() -> String:
	return TIPS[_index]

## Advances to the next tip (wrapping around) and returns it.
func next() -> String:
	_index = (_index + 1) % TIPS.size()
	return current()

func count() -> int:
	return TIPS.size()
