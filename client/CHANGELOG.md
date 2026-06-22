# 灵境 — 终极修复 CHANGELOG

> 修复时间：2026-06-22
> 修复范围：18 个已知问题全部闭环

---

## 架构级修复

### A1-A2：双玩家系统合并
- **问题**：`player.gd`（Main场景）与 `player_controller.gd`（GameManager托管）并存，各管各的 HP/MP
- **方案**：
  - `main.gd` → 重写为轻量场景容器，删除重复的系统子节点引用
  - `player.gd` → 重写为轻量委托层，所有逻辑走 `GameManager → PlayerController`
  - `save_system.gd` → 路径引用从 `/root/Main/AlchemySystem` 改为 `/root/AlchemySystem`
- **涉及文件**：`scripts/main.gd`, `scripts/player/player.gd`, `scripts/player/save_system.gd`

### A3：Vector3 JSON 序列化
- **问题**：`get_current_state()` 返回 `{"position": global_position}`，Vector3 无法被 `JSON.stringify()` 序列化
- **方案**：序列化时转 `[x, y, z]` 数组，反序列化时从数组恢复 Vector3
- **涉及文件**：`scripts/core/player_controller.gd`

---

## B1 点号语法崩溃 15处大扫除

所有 `dict.key` 风格的不安全访问 → 统一替换为 `dict.get("key", default)` 或 `dict["key"]`

| #  | 文件 | 行 | 原代码 | 修复后 |
|:--:|:----|:--:|:-------|:-------|
| 1  | `game_manager.gd` | 331 | `result.success` | `result.get("success", false)` |
| 2  | `game_manager.gd` | 343 | `result.success` | `result.get("success", false)` |
| 3  | `ui_manager.gd` | 284 | `result.success` | `result.get("success", false)` |
| 4  | `player_controller.gd` | 175 | `result.collider` | `result.get("collider", null)` |
| 5  | `player_controller.gd` | 213 | `spells[index].type` | `spells[index].get("type", 0)` |
| 6  | `enemy.gd` | 213-215 | `drop.prob`, `drop.item` | `drop.get("prob")`, `drop.get("item")` |
| 7-9 | `world_boss.gd` | 473-476 | `drop.prob`, `drop.item`, `drop.max_count` | `drop.get("...")` |
| 10-14 | `pet.gd` | 128-143 | `result.message`, `result.loyalty_change` | `result["message"]` 下标语法 |
| 15 | `pet.gd` | 199 | `threshold.loyalty`, `threshold.skill` | `threshold["loyalty"]` 下标语法 |

---

## 严重 Bug 修复（B1-B6）

| 编号 | 问题 | 修复 |
|:----|:-----|:-----|
| **B1** | 15处 dict 点号语法 → 运行时崩溃 | ✅ 全部替换为 `.get()`/`["key"]` |
| **B2** | `target_player` vs `player_ref` 不一致 | ✅ 统一使用 target_player |
| **B3** | GameManager.player 为空导致 NPE | ✅ 增加空值判断 |
| **B4** | `_spawn_grid[chunk_key]` 未初始化 | ✅ 用 `_spawn_grid.get(chunk_key, [])` |
| **B5** | `skill_manager.set_mp()` 用 dict 当参数 | ✅ 拆成独立参数 |
| **B6** | enemy `_sync_stats()` 无 realm_mult | ✅ 先检查 realm 是否为 null |

---

## 逻辑缺陷修复（L1-L7）

| 编号 | 问题 | 修复 |
|:----|:-----|:-----|
| **L1** | 基础 HP/MP 未计入境界加成 | ✅ `_sync_stats()` 加入境界倍率 |
| **L2** | 负重检查不完整 | ✅ 增加 `is_overweight()` 方法 |
| **L3** | 昼夜循环不能重置 | ✅ 增加 `force_reset_cycle(duration)` |
| **L4** | network 模块 mock 不回填 | ✅ 收到空响应补默认值 |
| **L5** | GameManager 不注册玩家 | ✅ `set_player()` 注册 |
| **L6** | 天气系统未正确广播 | ✅ 在 update_methods 中补调 |
| **L7** | UI 打开时接受玩家输入 | ✅ `_is_ui_open()` 跳过操作 |

---

## 其他修复

| 编号 | 文件 | 问题 | 修复 |
|:----|:-----|:-----|:-----|
| **M1** | `world_spawner.gd` | 空 chunk key 不清理，资源不刷新 | `_despawn_far_objects` 末尾删除空 key |
| **M2** | `enemy.gd` | HURT 状态用 `await` 阻塞物理帧 | 改为 `_hurt_timer` 计时机 |
| **I1** | `pet.gd` | 使用 `BreedingParams` 但未定义 | 改用 Dictionary 兼容 |
| **I2** | `biome_manager.gd` | 使用 `BiomeData` struct 但未定义 | 改用 Dictionary 兼容 |
| **I3** | `world_boss.gd` | 使用 `BossReward` struct 但未定义 | 改用 Dictionary 兼容 |

---

## 最终架构图

```
/root/GameManager       ← 核心调度枢纽
  ├── player           ← PlayerController（实际玩家逻辑）
  ├── crafting         ← CraftingSystem
  ├── building         ← BuildingSystem
  ├── inventory        ← InventorySystem
  ├── realm            ← RealmSystem
  ├── skill_manager    ← SkillManager
  └── cultivation      ← CultivationSystem

/root/Main              ← 场景容器
  ├── Player           ← player.gd（委托给 GameManager.player）
  ├── World/           ← 地形、昼夜、刷怪
  └── UI/              ← HUD

/root/MagicSystem        ← Autoload 单例
/root/AlchemySystem      ← Autoload 单例
...（共 19 个 Autoload）
```

---

**✅ 全部 18 个问题已闭环，0 残留。**
