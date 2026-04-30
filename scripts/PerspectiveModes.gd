extends Node
class_name PerspectiveModes

enum Mode { SIDE, TOPDOWN }

static func mode_name(mode: int) -> String:
	match mode:
		Mode.SIDE:
			return "SIDE"
		Mode.TOPDOWN:
			return "TOPDOWN"
		_:
			return "UNKNOWN"
