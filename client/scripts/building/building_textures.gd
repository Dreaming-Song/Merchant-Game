## 🎨 群系主题方块纹理生成
## 每个群系拥有独特的建材纹理风格
## 运行时根据建造地点所在群系自动切换材质

class_name BuildingTextures

const TEXTURE_SIZE: int = 64

## 获取某个群系下的建材纹理
static func generate(piece_type: int, biome_tag: int = 0) -> ImageTexture:
	var img = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	
	var light := Color(1.0, 1.0, 1.0)
	var dark := Color(0.7, 0.7, 0.7)
	
	# 按群系标签选择色调
	match biome_tag:
		0:  # GREEN — 竹林/桃花源（青绿调）
			light = Color(0.50, 0.65, 0.45)
			dark  = Color(0.35, 0.50, 0.30)
		1:  # RED — 枫林/火山（红褐调）
			light = Color(0.70, 0.35, 0.20)
			dark  = Color(0.50, 0.22, 0.12)
		2:  # WHITE — 雪山（冷白调）
			light = Color(0.85, 0.88, 0.92)
			dark  = Color(0.65, 0.68, 0.75)
		3:  # PURPLE — 沼泽/星辰沙漠（紫灰调）
			light = Color(0.50, 0.42, 0.55)
			dark  = Color(0.35, 0.28, 0.42)
		4:  # YELLOW — 雷暴平原（金褐调）
			light = Color(0.70, 0.62, 0.30)
			dark  = Color(0.50, 0.42, 0.18)
		_:  # 默认
			light = Color(1.0, 1.0, 1.0)
			dark  = Color(0.7, 0.7, 0.7)
	
	match piece_type:
		BuildingSystem.PieceType.WALL:
			_generate_wall_texture(img, light, dark, biome_tag)
		BuildingSystem.PieceType.FLOOR:
			_generate_floor_texture(img, light, dark, biome_tag)
		BuildingSystem.PieceType.FOUNDATION:
			_generate_foundation_texture(img, biome_tag)
		BuildingSystem.PieceType.ROOF:
			_generate_roof_texture(img, light, biome_tag)
		BuildingSystem.PieceType.PILLAR:
			_generate_pillar_texture(img, biome_tag)
		BuildingSystem.PieceType.DOOR:
			_generate_door_texture(img, light, dark, biome_tag)
		BuildingSystem.PieceType.FENCE:
			_generate_fence_texture(img, biome_tag)
		BuildingSystem.PieceType.DECORATION:
			_generate_decoration_texture(img, biome_tag)
		_:
			_generate_default_texture(img, biome_tag)
	
	return ImageTexture.create_from_image(img)

# ==================== 🧱 墙面 ====================

static func _generate_wall_texture(img: Image, light: Color, dark: Color, biome: int) -> void:
	var size = img.get_size().x
	var brick_h = size / 8
	var brick_w = size / 4
	
	for row in range(8):
		var offset = (brick_w / 2) if row % 2 == 0 else 0
		for col in range(4):
			var x0 = col * brick_w + offset
			var y0 = row * brick_h
			var c = dark if (row + col) % 2 == 0 else light
			# 群系特色：加入纹理噪点
			var noise_factor = 0.05 * _get_biome_noise(biome)
			for x in range(brick_w - 1):
				for y in range(brick_h - 1):
					var px = x0 + x
					var py = y0 + y
					if px < size and py < size:
						var noise = sin(px * 0.3 + py * 0.2) * noise_factor
						var final_c = Color(
							clamp(c.r + noise, 0.0, 1.0),
							clamp(c.g + noise * 0.8, 0.0, 1.0),
							clamp(c.b + noise * 0.6, 0.0, 1.0)
						)
						img.set_pixel(px, py, final_c)
			# 砖缝
			var seam_color = _get_seam_color(biome)
			for x in range(brick_w):
				if x0 + x < size:
					img.set_pixel(x0 + x, y0 + brick_h - 2, seam_color)

# ==================== 🪵 地板 ====================

static func _generate_floor_texture(img: Image, light: Color, dark: Color, biome: int) -> void:
	var size = img.get_size().x
	var plank_w = size / 8
	var seam_color = _get_seam_color(biome)
	
	for i in range(8):
		var x0 = i * plank_w
		var c = light if i % 2 == 0 else dark
		var grain = sin(i * 2.5) * 0.08  # 木纹
		for x in range(plank_w - 1):
			for y in range(size):
				var px = x0 + x
				var noise = 0.05 * sin(y * 0.3 + i * 1.2) + grain
				var final_c = Color(
					clamp(c.r + noise, 0.0, 1.0),
					clamp(c.g + noise * 0.7, 0.0, 1.0),
					clamp(c.b + noise * 0.5, 0.0, 1.0)
				)
				img.set_pixel(px, y, final_c)
		for y in range(size):
			img.set_pixel(x0 + plank_w - 1, y, seam_color)

# ==================== 🪨 地基 ====================

static func _generate_foundation_texture(img: Image, biome: int) -> void:
	var size = img.get_size().x
	var base_c = _get_biome_stone_color(biome)
	for x in range(size):
		for y in range(size):
			var noise = sin(x * 0.3) * cos(y * 0.25) * 0.15
			var c = Color(
				base_c.r + noise,
				base_c.g + noise * 0.9,
				base_c.b + noise * 0.8
			)
			img.set_pixel(x, y, c)
	var pebble_count = 30 + biome * 5
	for _i in range(pebble_count):
		var sx = randi() % size
		var sy = randi() % size
		var darker = Color(
			base_c.r * 0.6,
			base_c.g * 0.6,
			base_c.b * 0.6
		)
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var px = sx + dx
				var py = sy + dy
				if px >= 0 and px < size and py >= 0 and py < size:
					img.set_pixel(px, py, darker)

# ==================== 🏠 屋顶 ====================

static func _generate_roof_texture(img: Image, base_color: Color, biome: int) -> void:
	var size = img.get_size().x
	var tile_r = 6
	var seam = _get_seam_color(biome)
	
	for row in range(0, size, tile_r * 2):
		var offset_x = tile_r if int(row / (tile_r * 2)) % 2 == 1 else 0
		for col in range(offset_x, size, tile_r * 2):
			for dx in range(-tile_r, tile_r):
				for dy in range(-tile_r, 0):
					if dx * dx + dy * dy < tile_r * tile_r:
						var px = col + dx
						var py = row + dy + tile_r
						if px >= 0 and px < size and py >= 0 and py < size:
							img.set_pixel(px, py, base_color)
			for dx in range(-tile_r, tile_r):
				var px = col + dx
				var py = row + tile_r
				if px >= 0 and px < size and py >= 0 and py < size:
					img.set_pixel(px, py, seam)

# ==================== 🏛️ 柱子 ====================

static func _generate_pillar_texture(img: Image, biome: int) -> void:
	var size = img.get_size().x
	var stone_c = _get_biome_stone_color(biome)
	for x in range(size):
		for y in range(size):
			var noise = sin(x * 0.2 + y * 0.15) * cos(x * 0.1 - y * 0.2) * 0.1
			var c = Color(
				stone_c.r + noise,
				stone_c.g + noise,
				stone_c.b + noise
			)
			img.set_pixel(x, y, c)
	var vein_color = Color(stone_c.r * 0.7, stone_c.g * 0.7, stone_c.b * 0.7)
	for _i in range(12 + biome * 3):
		var bx = randi() % size
		var by = randi() % size
		var angle = randf() * PI
		for t in range(20):
			var px = bx + int(cos(angle) * t)
			var py = by + int(sin(angle) * t)
			if px >= 0 and px < size and py >= 0 and py < size:
				img.set_pixel(px, py, vein_color)

# ==================== 🚪 门 ====================

static func _generate_door_texture(img: Image, light: Color, dark: Color, biome: int) -> void:
	# 门用木板拼纹
	var size = img.get_size().x
	for y in range(size):
		var c = light if y % 16 < 8 else dark
		var grain = sin(y * 0.5) * 0.06
		for x in range(size):
			var final_c = Color(
				clamp(c.r + grain, 0.0, 1.0),
				clamp(c.g + grain * 0.7, 0.0, 1.0),
				clamp(c.b + grain * 0.5, 0.0, 1.0)
			)
			img.set_pixel(x, y, final_c)

# ==================== 🚧 栅栏 ====================

static func _generate_fence_texture(img: Image, biome: int) -> void:
	var size = img.get_size().x
	var c = _get_biome_stone_color(biome)
	for x in range(size):
		for y in range(size):
			var noise = sin(x * 0.4 + y * 0.3) * 0.08
			var final_c = Color(
				c.r + noise,
				c.g + noise * 0.8,
				c.b + noise * 0.6
			)
			img.set_pixel(x, y, final_c)

# ==================== 🎭 装饰 ====================

static func _generate_decoration_texture(img: Image, biome: int) -> void:
	var size = img.get_size().x
	var c = _get_biome_accent_color(biome)
	for x in range(size):
		for y in range(size):
			var pattern = sin(x * 0.5) * cos(y * 0.5)
			var noise = pattern * 0.15
			var final_c = Color(
				c.r + noise,
				c.g + noise * 0.8,
				c.b + noise * 0.6
			)
			img.set_pixel(x, y, final_c)

# ==================== 默认兜底 ====================

static func _generate_default_texture(img: Image, biome: int) -> void:
	var size = img.get_size().x
	var c = _get_biome_stone_color(biome)
	for x in range(size):
		for y in range(size):
			var noise = sin(x * 0.5 + y * 0.3) * 0.08
			var final_c = Color(
				c.r + noise,
				c.g + noise,
				c.b + noise
			)
			img.set_pixel(x, y, final_c)

# ==================== 🧪 群系配色辅助 ====================

static func _get_biome_noise(biome: int) -> float:
	# 不同群系的纹理噪点程度
	match biome:
		0: return 0.8  # 竹林 — 粗糙竹纹
		1: return 0.6  # 枫林 — 适中
		2: return 0.3  # 雪山 — 光滑
		3: return 0.9  # 沼泽 — 粗糙
		4: return 0.7  # 雷暴 — 适中
		_: return 0.5

static func _get_seam_color(biome: int) -> Color:
	match biome:
		0: return Color(0.20, 0.30, 0.15)  # 深绿缝
		1: return Color(0.35, 0.18, 0.10)  # 深褐缝
		2: return Color(0.40, 0.42, 0.50)  # 灰蓝缝
		3: return Color(0.18, 0.15, 0.22)  # 深紫缝
		4: return Color(0.35, 0.30, 0.12)  # 深金缝
		_: return Color(0.2, 0.15, 0.1)

static func _get_biome_stone_color(biome: int) -> Color:
	match biome:
		0: return Color(0.50, 0.55, 0.42)  # 青石
		1: return Color(0.55, 0.35, 0.22)  # 红石
		2: return Color(0.70, 0.72, 0.78)  # 白石
		3: return Color(0.38, 0.32, 0.42)  # 紫石
		4: return Color(0.52, 0.48, 0.30)  # 金石
		_: return Color(0.5, 0.5, 0.5)

static func _get_biome_accent_color(biome: int) -> Color:
	match biome:
		0: return Color(0.65, 0.75, 0.35)  # 竹青
		1: return Color(0.80, 0.40, 0.20)  # 枫红
		2: return Color(0.60, 0.70, 0.90)  # 冰蓝
		3: return Color(0.50, 0.35, 0.65)  # 暗紫
		4: return Color(0.85, 0.75, 0.30)  # 金色
		_: return Color(0.7, 0.7, 0.7)
