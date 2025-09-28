package graphics

import "vendor:raylib"

// Represents color in rgba format with values ranging from 0 to 1
Color :: struct {
	r, g, b, a: f32,
}

// Turn 0->1 color into 0->255 color
to_u8 :: proc(color: Color) -> [4]u8 {
	return [4]u8{u8(color.r * 255), u8(color.g * 255), u8(color.b * 255), u8(color.a * 255)}
}

// Turn 0->1 color into Raylib (0->255) color
to_rl :: proc(color: Color) -> raylib.Color {
	return raylib.Color(to_u8(color))
}

adjust_alpha :: proc(color: Color, alpha: f32) -> Color {
	return Color{color.r, color.g, color.b, alpha}
}

// Greyscale
