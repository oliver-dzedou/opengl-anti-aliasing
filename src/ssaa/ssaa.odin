package ssaa

import "../graphics"
import "core:log"

@(private)
ssaa := cstring(#load("ssaa.glsl"))
@(private)
ssaa_loaded: graphics.Shader
@(private)
ssaa_texture: graphics.Texture

// Runs a ssaa pass on the provided scene 
pass :: proc(
	scene: graphics.Texture,
	res: graphics.Resolution,
	ssaa_factor: int,
) -> graphics.Texture {
	if !graphics.check_texture_matches_resolution(res, ssaa_texture) {
		ssaa_texture = graphics.create_texture(res.width, res.height)
	}
	if ssaa_loaded.id < 1 {
		ssaa_loaded = graphics.load_shader(ssaa, "ssaa")
	}

	f32_res := graphics.to_f32(res)
	sf := ssaa_factor

	graphics.begin_texture(ssaa_texture)
	graphics.begin_shader(ssaa_loaded)
	graphics.set_shader_uniform_330(ssaa_loaded, "resolution", .VEC2, &f32_res)
	graphics.set_shader_texture_330(ssaa_loaded, "scene", scene)
	graphics.set_shader_uniform_330(ssaa_loaded, "ssaa_factor", .INT, &sf)
	graphics.rect(res.width, res.height)
	graphics.end_shader()
	graphics.end_texture()
	return ssaa_texture
}

destroy :: proc() {
	graphics.unload_texture(&ssaa_texture)
	graphics.unload_shader(&ssaa_loaded)
}
