package smaa

import "../graphics"

@(private)
smaa_edge_detection_shader :: cstring(#load("smaa_edge_detection.glsl"))
@(private)
smaa_weights_shader :: cstring(#load("smaa_weights.glsl"))
@(private)
smaa_blend_shader :: cstring(#load("smaa_blend.glsl"))

@(private)
smaa_edge_detection_shader_loaded: graphics.Shader
@(private)
smaa_weights_shader_loaded: graphics.Shader
@(private)
smaa_blend_shader_loaded: graphics.Shader

@(private)
edges_texture: graphics.Texture
@(private)
weights_texture: graphics.Texture
@(private)
blend_texture: graphics.Texture

@(private)
area_tex: graphics.Texture
@(private)
search_tex: graphics.Texture

pass :: proc(scene: graphics.Texture, res: graphics.Resolution) -> graphics.Texture {
	if !graphics.check_texture_matches_resolution(res, edges_texture) {
		edges_texture = graphics.create_texture(res.width, res.height)
	}
	if !graphics.check_texture_matches_resolution(res, weights_texture) {
		weights_texture = graphics.create_texture(res.width, res.height)
	}
	if !graphics.check_texture_matches_resolution(res, blend_texture) {
		blend_texture = graphics.create_texture(res.width, res.height)
	}
	if !graphics.check_texture_matches_resolution(
		graphics.Resolution{AREATEX_WIDTH, AREATEX_HEIGHT},
		area_tex,
	) {
		area_tex = graphics.create_texture(
			width = AREATEX_WIDTH,
			height = AREATEX_HEIGHT,
			format = .UNCOMPRESSED_GRAY_ALPHA,
			backing_data = &AREATEX_BYTES[0],
			mipmaps = 1,
		)
	}
	if !graphics.check_texture_matches_resolution(
		graphics.Resolution{SEARCHTEX_WIDTH, SEARCHTEX_HEIGHT},
		search_tex,
	) {
		search_tex = graphics.create_texture(
			width = SEARCHTEX_WIDTH,
			height = SEARCHTEX_HEIGHT,
			format = .UNCOMPRESSED_GRAYSCALE,
			backing_data = &SEARCHTEX_BYTES[0],
			mipmaps = 1,
		)
	}

	if smaa_edge_detection_shader_loaded.id < 1 {
		smaa_edge_detection_shader_loaded = graphics.load_shader(
			smaa_edge_detection_shader,
			"smaa_edge_detection_shader",
		)
	}
	if smaa_weights_shader_loaded.id < 1 {
		smaa_weights_shader_loaded = graphics.load_shader(
			smaa_weights_shader,
			"smaa_weights_shader",
		)
	}
	if smaa_blend_shader_loaded.id < 1 {
		smaa_blend_shader_loaded = graphics.load_shader(smaa_blend_shader, "smaa_blend_shader")
	}

	f32_res := graphics.to_f32(res)
	smaa_metrics := [4]f32{1 / f32_res.x, 1 / f32_res.y, f32_res.x, f32_res.y}

	graphics.begin_texture(edges_texture)
	graphics.begin_shader(smaa_edge_detection_shader_loaded)
	graphics.set_shader_uniform_330(
		smaa_edge_detection_shader_loaded,
		"SMAA_RT_METRICS",
		.VEC4,
		&smaa_metrics,
	)
	graphics.set_shader_texture_330(smaa_edge_detection_shader_loaded, "colorTex", scene)
	graphics.rect(res.width, res.height)
	graphics.end_shader()
	graphics.end_texture()

	graphics.begin_texture(weights_texture)
	graphics.begin_shader(smaa_weights_shader_loaded)
	graphics.set_shader_uniform_330(
		smaa_weights_shader_loaded,
		"SMAA_RT_METRICS",
		.VEC4,
		&smaa_metrics,
	)
	graphics.set_shader_texture_330(smaa_weights_shader_loaded, "areaTex", area_tex)
	graphics.set_shader_texture_330(smaa_weights_shader_loaded, "searchTex", search_tex)
	graphics.set_shader_texture_330(smaa_weights_shader_loaded, "edgesTex", edges_texture)
	graphics.rect(res.width, res.height)
	graphics.end_shader()
	graphics.end_texture()

	graphics.begin_texture(blend_texture)
	graphics.begin_shader(smaa_blend_shader_loaded)
	graphics.set_shader_uniform_330(
		smaa_blend_shader_loaded,
		"SMAA_RT_METRICS",
		.VEC4,
		&smaa_metrics,
	)
	graphics.set_shader_texture_330(smaa_blend_shader_loaded, "colorTex", scene)
	graphics.set_shader_texture_330(smaa_blend_shader_loaded, "weightTex", weights_texture)
	graphics.rect(res.width, res.height)
	graphics.end_shader()
	graphics.end_texture()

	return blend_texture
}

destroy :: proc() {
	graphics.unload_texture(&weights_texture)
	graphics.unload_texture(&blend_texture)
	graphics.unload_texture(&edges_texture)
	graphics.unload_shader(&smaa_weights_shader_loaded)
	graphics.unload_shader(&smaa_blend_shader_loaded)
	graphics.unload_shader(&smaa_edge_detection_shader_loaded)
}
