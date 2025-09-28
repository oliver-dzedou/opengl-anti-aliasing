package graphics

Resolution :: struct {
	width:  int,
	height: int,
}

// Converts a resolution struct to a f32 tuple
to_f32 :: proc(resolution: Resolution) -> [2]f32 {
	return [2]f32{f32(resolution.width), f32(resolution.height)}
}

UnitType :: enum {
	ABSOLUTE,
	RELATIVE,
}

// A scalable unit
// Use [get_absolute] to get screen pixels value
Unit :: struct {
	type: UnitType,
	val:  f32,
}

// The dimension the unit should be scaled to
Dimension :: enum {
	WIDTH,
	HEIGHT,
}

// Scales scalable(percentage) units to absolute values
// Does not for absolute values
get_absolute :: proc(unit: Unit, #any_int scaling: int) -> Unit {
	switch unit.type {
	case .ABSOLUTE:
		return Unit{.ABSOLUTE, unit.val}
	case .RELATIVE:
		return Unit{.ABSOLUTE, (unit.val / 100) * f32(scaling)}
	}
	// won't be hit
	return Unit{}
}

get_relative :: proc(unit: Unit, #any_int scaling: int) -> Unit {
	switch unit.type {
	case .ABSOLUTE:
		return Unit{.RELATIVE, (unit.val * 100) / f32(scaling)}
	case .RELATIVE:
		return Unit{.RELATIVE, unit.val}
	}
	// won't be hit
	return Unit{}
}

add_units :: proc(x1, x2: Unit, #any_int scaling: int) -> Unit {
	x1abs := get_absolute(x1, scaling)
	x2abs := get_absolute(x2, scaling)
	return Unit{.ABSOLUTE, x1abs.val + x2abs.val}
}
