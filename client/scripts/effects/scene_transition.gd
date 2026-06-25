extends CanvasLayer
## 🌀 场景转场动画 — 修仙风格过渡效果
##
## 用法：
##   SceneTransition.fade_to_scene("res://scenes/world.tscn")
##   SceneTransition.circle_wipe(callback)
##   SceneTransition.cloud_scroll(callback)

class_name SceneTransition

# ==================== 转场类型 ====================
enum TransitionStyle {
	CIRCLE_WIPE,    # 圆形擦除（传送门效果）
	VERTICAL_WIPE,  # 上下合拢（闭眼效果）
	CLOUD_SCROLL,   # 云卷云舒（修仙风）
	FLASH_FADE,     # 闪白淡入淡出（通用）
	LIGHT_BURST,    # 光爆扩散
}

# ==================== 单例实例 ====================
static var _instance: SceneTransition = null

static func get_instance() -> SceneTransition:
	if not _instance:
		var root = Engine.get_main_loop().current_scene
		_instance = SceneTransition.new()
		_instance.name = "__SceneTransition__"
		root.add_child(_instance)
	return _instance

# ==================== 静态调用 ====================

static func fade_to_scene(scene_path: String, style: int = TransitionStyle.CLOUD_SCROLL) -> void:
	"""淡出 → 切换场景 → 淡入"""
	var inst = get_instance()
	
	# 淡出
	await inst.play_out(style)
	
	# 切换场景
	get_tree().change_scene_to_file(scene_path)
	
	# 淡入
	inst.play_in(style)

static func execute(callback: Callable, style: int = TransitionStyle.CIRCLE_WIPE, duration: float = 0.6) -> void:
	"""执行转场动画，中间执行回调"""
	var inst = get_instance()
	await inst.play_out(style, duration)
	callback.call()
	inst.play_in(style, duration)

# ==================== 主播放接口 ====================

func play_out(style: int = TransitionStyle.CIRCLE_WIPE, duration: float = 0.6) -> void:
	"""播放转出动画（从清晰到遮挡）"""
	match style:
		TransitionStyle.CIRCLE_WIPE:
			await _circle_wipe_out(duration)
		TransitionStyle.VERTICAL_WIPE:
			await _vertical_wipe_out(duration)
		TransitionStyle.CLOUD_SCROLL:
			await _cloud_scroll_out(duration)
		TransitionStyle.FLASH_FADE:
			await _flash_fade_out(duration)
		TransitionStyle.LIGHT_BURST:
			await _light_burst_out(duration)

func play_in(style: int = TransitionStyle.CIRCLE_WIPE, duration: float = 0.6) -> void:
	"""播放转入动画（从遮挡到清晰）"""
	match style:
		TransitionStyle.CIRCLE_WIPE:
			await _circle_wipe_in(duration)
		TransitionStyle.VERTICAL_WIPE:
			await _vertical_wipe_in(duration)
		TransitionStyle.CLOUD_SCROLL:
			await _cloud_scroll_in(duration)
		TransitionStyle.FLASH_FADE:
			await _flash_fade_in(duration)
		TransitionStyle.LIGHT_BURST:
			await _light_burst_in(duration)

# ==================== 🌀 圆形擦除 ====================

func _circle_wipe_out(dur: float) -> void:
	"""圆形闭合遮罩 - 类似传送门关闭"""
	var size = get_viewport().get_visible_rect().size
	var center = size / 2
	var max_radius = size.length() * 0.75
	
	# 用 TextureRect + 圆形遮罩
	var mask = ColorRect.new()
	mask.color = Color(0, 0, 0, 1)
	mask.anchors_preset = Control.PRESET_FULL_RECT
	mask.material = _make_circle_mask_material(0.0, center, max_radius)
	add_child(mask)
	
	var tween = create_tween()
	tween.tween_method(func(v):
		if mask.material:
			mask.material.set_shader_parameter("radius", v)
	, 0.0, max_radius + 0.1, dur).set_trans(Tween.TRANS_QUINT)
	
	await tween.finished

func _circle_wipe_in(dur: float) -> void:
	"""圆形展开遮罩 - 类似传送门开启"""
	var size = get_viewport().get_visible_rect().size
	var center = size / 2
	var max_radius = size.length() * 0.75
	
	var mask = ColorRect.new()
	mask.color = Color(0, 0, 0, 1)
	mask.anchors_preset = Control.PRESET_FULL_RECT
	mask.material = _make_circle_mask_material(max_radius, center, max_radius)
	add_child(mask)
	
	var tween = create_tween()
	tween.tween_method(func(v):
		if mask.material:
			mask.material.set_shader_parameter("radius", v)
	, max_radius, -0.1, dur).set_trans(Tween.TRANS_QUINT)
	
	await tween.finished
	mask.queue_free()

func _make_circle_mask_material(initial_radius: float, center: Vector2, max_r: float) -> Material:
	"""创建圆形遮罩 ShaderMaterial"""
	# 用 CanvasItemMaterial 不支持圆形遮罩，改用 ColorRect + modulate 
	# 简化：直接用 TextureRect 的 shader
	var mat = ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = """
shader_type canvas_item;

uniform vec2 center;
uniform float max_radius;
uniform float radius : hint_range(0.0, 2000.0);

void fragment() {
	vec2 uv = UV * vec2(textureSize(TEXTURE, 0));
	float dist = distance(uv, center);
	float alpha = smoothstep(radius - 2.0, radius, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	mat.set_shader_parameter("center", center)
	mat.set_shader_parameter("max_radius", max_r)
	mat.set_shader_parameter("radius", initial_radius)
	return mat

# ==================== 🔲 上下合拢 ====================

func _vertical_wipe_out(dur: float) -> void:
	"""上下合拢遮罩"""
	var size = get_viewport().get_visible_rect().size
	
	var top_bar = ColorRect.new()
	top_bar.color = Color(0, 0, 0, 1)
	top_bar.size = Vector2(size.x, 0)
	top_bar.position = Vector2(0, 0)
	add_child(top_bar)
	
	var bot_bar = ColorRect.new()
	bot_bar.color = Color(0, 0, 0, 1)
	bot_bar.size = Vector2(size.x, 0)
	bot_bar.position = Vector2(0, size.y)
	add_child(bot_bar)
	
	var t1 = create_tween()
	t1.tween_property(top_bar, "size:y", size.y / 2 + 1, dur * 0.5).set_trans(Tween.TRANS_QUINT)
	var t2 = create_tween()
	t2.tween_property(bot_bar, "size:y", size.y / 2 + 1, dur * 0.5).set_trans(Tween.TRANS_QUINT)
	t2.parallel().tween_property(bot_bar, "position:y", size.y / 2, dur * 0.5)
	
	await t2.finished

func _vertical_wipe_in(dur: float) -> void:
	"""上下展开遮罩"""
	var size = get_viewport().get_visible_rect().size
	
	var top_bar = ColorRect.new()
	top_bar.color = Color(0, 0, 0, 1)
	top_bar.size = Vector2(size.x, size.y / 2 + 1)
	top_bar.position = Vector2(0, 0)
	add_child(top_bar)
	
	var bot_bar = ColorRect.new()
	bot_bar.color = Color(0, 0, 0, 1)
	bot_bar.size = Vector2(size.x, size.y / 2 + 1)
	bot_bar.position = Vector2(0, size.y / 2)
	add_child(bot_bar)
	
	var t1 = create_tween()
	t1.tween_property(top_bar, "size:y", 0, dur * 0.5).set_trans(Tween.TRANS_QUINT)
	var t2 = create_tween()
	t2.tween_property(bot_bar, "size:y", 0, dur * 0.5).set_trans(Tween.TRANS_QUINT)
	t2.parallel().tween_property(bot_bar, "position:y", size.y, dur * 0.5)
	
	await t2.finished
	top_bar.queue_free()
	bot_bar.queue_free()

# ==================== ☁️ 云卷云舒 ====================

func _cloud_scroll_out(dur: float) -> void:
	"""云卷 — 两侧云雾合拢"""
	var size = get_viewport().get_visible_rect().size
	
	# 左云
	var left_cloud = ColorRect.new()
	left_cloud.color = Color(0.15, 0.15, 0.2, 1)
	left_cloud.size = Vector2(0, size.y)
	left_cloud.position = Vector2(0, 0)
	left_cloud.material = _make_cloud_material()
	add_child(left_cloud)
	
	# 右云
	var right_cloud = ColorRect.new()
	right_cloud.color = Color(0.15, 0.15, 0.2, 1)
	right_cloud.size = Vector2(0, size.y)
	right_cloud.position = Vector2(size.x, 0)
	right_cloud.material = _make_cloud_material()
	add_child(right_cloud)
	
	var t1 = create_tween()
	t1.tween_property(left_cloud, "size:x", size.x / 2 + 1, dur).set_trans(Tween.TRANS_SINE)
	var t2 = create_tween()
	t2.tween_property(right_cloud, "position:x", size.x / 2, dur).set_trans(Tween.TRANS_SINE)
	t2.parallel().tween_property(right_cloud, "size:x", size.x / 2 + 1, dur)
	
	await t2.finished

func _cloud_scroll_in(dur: float) -> void:
	"""云舒 — 两侧云雾散开"""
	var size = get_viewport().get_visible_rect().size
	
	var left_cloud = ColorRect.new()
	left_cloud.color = Color(0.15, 0.15, 0.2, 1)
	left_cloud.size = Vector2(size.x / 2 + 1, size.y)
	left_cloud.position = Vector2(0, 0)
	left_cloud.material = _make_cloud_material()
	add_child(left_cloud)
	
	var right_cloud = ColorRect.new()
	right_cloud.color = Color(0.15, 0.15, 0.2, 1)
	right_cloud.size = Vector2(size.x / 2 + 1, size.y)
	right_cloud.position = Vector2(size.x / 2, 0)
	right_cloud.material = _make_cloud_material()
	add_child(right_cloud)
	
	var t1 = create_tween()
	t1.tween_property(left_cloud, "size:x", 0, dur).set_trans(Tween.TRANS_SINE)
	t1.tween_callback(left_cloud.queue_free)
	
	var t2 = create_tween()
	t2.tween_property(right_cloud, "size:x", 0, dur).set_trans(Tween.TRANS_SINE)
	t2.parallel().tween_property(right_cloud, "position:x", size.x, dur)
	t2.tween_callback(right_cloud.queue_free)
	
	await t2.finished

func _make_cloud_material() -> Material:
	"""创建云雾材质（边缘柔化）"""
	var mat = ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = """
shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	float edge = 1.0 - abs(uv.x - 0.5) * 2.0;
	edge = pow(edge, 1.5);
	COLOR = vec4(0.12, 0.12, 0.18, edge);
}
"""
	return mat

# ==================== 💥 闪白淡出 ====================

func _flash_fade_out(dur: float) -> void:
	"""闪白转出"""
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(1, 1, 1, 1), dur * 0.6).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(flash, "color", Color(0, 0, 0, 1), dur * 0.4)
	
	await tween.finished

func _flash_fade_in(dur: float) -> void:
	"""闪白转入"""
	var flash = ColorRect.new()
	flash.color = Color(0, 0, 0, 1)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(0, 0, 0, 0), dur * 0.8).set_trans(Tween.TRANS_EXPO)
	
	await tween.finished
	flash.queue_free()

# ==================== 💡 光爆扩散 ====================

func _light_burst_out(dur: float) -> void:
	"""光爆闭合 — 中心白光扩散覆盖全屏"""
	var size = get_viewport().get_visible_rect().size
	var center = size / 2
	
	var light = ColorRect.new()
	light.color = Color(1, 1, 1, 0)
	light.size = Vector2(0, 0)
	light.position = center
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light)
	
	var tween = create_tween()
	tween.tween_property(light, "size", size * 1.5, dur * 0.5).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(light, "color", Color(1, 1, 1, 1), dur * 0.5)
	tween.tween_property(light, "color", Color(0, 0, 0, 1), dur * 0.3)
	
	await tween.finished

func _light_burst_in(dur: float) -> void:
	"""光爆展开 — 黑屏中白光扩散消失"""
	var size = get_viewport().get_visible_rect().size
	var center = size / 2
	
	var light = ColorRect.new()
	light.color = Color(1, 1, 1, 1)
	light.size = size * 1.5
	light.position = center - size * 0.75
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)
	
	var tween = create_tween()
	tween.tween_property(light, "size", Vector2(0, 0), dur * 0.7).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(light, "color", Color(1, 1, 1, 0), dur * 0.7)
	tween.tween_property(bg, "color", Color(0, 0, 0, 0), dur * 0.3)
	
	await tween.finished
	light.queue_free()
	bg.queue_free()
