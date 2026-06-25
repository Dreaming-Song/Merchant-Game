extends Control
## 迷雾地图 — 右上角缩略图 + Fog of War
##
## 功能：
##   1. 实时显示玩家周围地形（根据 MapGenerator 的 biome_map）
##   2. 经过的区域永久可见，未探索的覆盖迷雾
##   3. 玩家位置标记 + 方向指示
##   4. 按 M 键切换全屏/小地图

class_name Minimap

# ==================== 配置 ====================
@export var map_size: int = 200          # 地图像素大小
@export var view_radius: int = 50        # 当前可见范围（像素）
@export var fog_color: Color = Color(0.05, 0.05, 0.1, 0.95)
@export var explored_alpha: float = 0.0  # 已探索区域的迷雾透明度

# ==================== 内部 ====================
var _map_image: Image                    # 完整地图
var _fog_image: Image                    # 迷雾层
var _map_texture: ImageTexture           # 地图纹理
var _fog_texture: ImageTexture           # 迷雾纹理
var _player_pos_2d: Vector2 = Vector2.ZERO
var _map_gen: Node = null
var _camera: Camera3D = null
var _is_fullscreen: bool = false
var _last_player_chunk: Vector2i = Vector2i(999, 999)

func _ready() -> void:
	_map_gen = get_node("/root/GameManager/MapGenerator") if has_node("/root/GameManager/MapGenerator") else null
	
	# 初始化图像
	_map_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
	_fog_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
	
	# 填充迷雾
	_fog_image.fill(fog_color)
	
	_map_texture = ImageTexture.create_from_image(_map_image)
	_fog_texture = ImageTexture.create_from_image(_fog_image)
	
	# 绘制基础地图
	_draw_base_map()

func _draw_base_map() -> void:
	"""用 MapGenerator 的生物群系数据绘制基础地图"""
	if not _map_gen:
		return
	
	var biome_map = {}
	if _map_gen.has_method("_generate_biome_map"):
		biome_map = _map_gen._generate_biome_map()
	
	if biome_map.is_empty():
		return
	
	# 遍历地图像素，映射到世界坐标
	var world_size = _map_gen.get("world_size") or 1024
	var pixels_per_unit = map_size / (world_size * 2.0)  # -world_size ~ +world_size
	
	for px in range(map_size):
		for py in range(map_size):
			# 像素 → 世界坐标
			var wx = (px - map_size / 2.0) / pixels_per_unit
			var wz = (py - map_size / 2.0) / pixels_per_unit
			
			var cx = int(wx / _map_gen.chunk_size)
			var cz = int(wz / _map_gen.chunk_size)
			var key = "%d_%d" % [cx, cz]
			
			var biome = biome_map.get(key, _map_gen.Biome.PLAINS)
			var color = _map_gen.get_biome_color(biome)
			color.a = 1.0
			
			_map_image.set_pixel(px, py, color)
	
	_map_texture.update(_map_image)

## 更新玩家位置和探索区域
func update_player_position(player_world_pos: Vector3) -> void:
	if not _map_gen:
		return
	
	# 世界坐标 → 地图像素
	var world_size = _map_gen.get("world_size") or 1024
	var pixels_per_unit = map_size / (world_size * 2.0)
	
	var mx = player_world_pos.x * pixels_per_unit + map_size / 2.0
	var my = player_world_pos.z * pixels_per_unit + map_size / 2.0
	_player_pos_2d = Vector2(mx, my)
	
	# 更新迷雾（以玩家为中心揭开）
	var radius_px = view_radius
	for x in range(max(0, int(mx) - radius_px), min(map_size, int(mx) + radius_px)):
		for y in range(max(0, int(my) - radius_px), min(map_size, int(my) + radius_px)):
			var dist = Vector2(x, y).distance_to(_player_pos_2d)
			if dist <= radius_px:
				# 揭开迷雾
				var fog_val = lerp(explored_alpha, 1.0, dist / radius_px)
				var current_fog = _fog_image.get_pixel(x, y)
				if current_fog.a > fog_val:
					var new_fog = Color(fog_color.r, fog_color.g, fog_color.b, fog_val)
					_fog_image.set_pixel(x, y, new_fog)
	
	_fog_texture.update(_fog_image)

## 获取最终地图纹理（地图 + 迷雾）
func get_map_texture() -> ImageTexture:
	# 合并地图和迷雾
	var combined = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
	combined.blit_rect(_map_image, Rect2i(0, 0, map_size, map_size), Vector2i.ZERO)
	combined.blit_rect(_fog_image, Rect2i(0, 0, map_size, map_size), Vector2i.ZERO)
	return ImageTexture.create_from_image(combined)

func get_fog_texture() -> ImageTexture:
	return _fog_texture

func get_player_map_pos() -> Vector2:
	return _player_pos_2d

## 全屏切换
func toggle_fullscreen() -> void:
	_is_fullscreen = not _is_fullscreen
	if _is_fullscreen:
		# 放大地图到全屏
		map_size = 600
	else:
		map_size = 200
	# 重新绘制
	_ready()
