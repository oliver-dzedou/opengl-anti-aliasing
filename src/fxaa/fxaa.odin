package fxaa

import "../graphics"
import "core:log"

@(private)
fxaa := cstring(#load("fxaa.glsl"))
@(private)
fxaa_loaded: graphics.Shader
@(private)
fxaa_texture: graphics.Texture

// Runs a fxaa pass on the provided scene 
pass :: proc(scene: graphics.Texture, res: graphics.Resolution) -> graphics.Texture {
	if !graphics.check_texture_matches_resolution(res, fxaa_texture) {
		fxaa_texture = graphics.create_texture(res.width, res.height)
	}
	if fxaa_loaded.id < 1 {
		fxaa_loaded = graphics.load_shader(fxaa, "fxaa")
	}

	f32_res := graphics.to_f32(res)

	graphics.begin_texture(fxaa_texture)
	graphics.begin_shader(fxaa_loaded)
	graphics.set_shader_uniform_330(fxaa_loaded, "resolution", .VEC2, &f32_res)
	graphics.set_shader_texture_330(fxaa_loaded, "scene", scene)
	graphics.rect(res.width, res.height)
	graphics.end_shader()
	graphics.end_texture()
	return fxaa_texture
}

destroy :: proc() {
	graphics.unload_shader(&fxaa_loaded)
	graphics.unload_texture(&fxaa_texture)
}
