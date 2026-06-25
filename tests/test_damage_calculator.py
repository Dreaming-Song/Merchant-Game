"""
🧪 DamageCalculator 逻辑单元测试
用 Python 实现 GDScript 逻辑确保数值正确
"""

import pytest
import math
import random

# ==================== 常量（与 GDScript 保持一致） ====================
ELEMENT_COUNTER = {
    "金": "木", "木": "土", "土": "水",
    "水": "火", "火": "金",
}
COUNTER_MULTIPLIER = 1.5
RESIST_MULTIPLIER = 0.67


def calculate_damage(
    attacker_stats: dict,
    defender_stats: dict,
    skill_data: dict,
    extra_modifiers: dict = None,
    force_rand: float = None,
    force_variance: float = None,
):
    """Python 版伤害计算（与 GDScript 逻辑一致）"""
    extra_modifiers = extra_modifiers or {}

    # 1. 基础攻击力
    base_attack = int(attacker_stats.get("attack", 10))
    damage_mult = float(skill_data.get("damage_mult", 1.0))
    raw_damage = base_attack * damage_mult

    # 2. 技能额外伤害加成
    skill_bonus = float(skill_data.get("damage_bonus", 0.0))
    raw_damage += skill_bonus

    # 3. 防御减免
    defense = float(defender_stats.get("defense", 0))
    defense_reduction = defense / (defense + 100.0)
    raw_damage *= (1.0 - defense_reduction)

    # 4. 常驻减伤
    damage_reduction = float(defender_stats.get("damage_reduction", 0.0))
    raw_damage *= (1.0 - damage_reduction)

    # 5. 五行克制
    attacker_element = str(skill_data.get("element", ""))
    defender_element = str(defender_stats.get("element", ""))
    element_mult = 1.0
    element_detail = ""

    if attacker_element and defender_element:
        if ELEMENT_COUNTER.get(attacker_element) == defender_element:
            element_mult = COUNTER_MULTIPLIER
            element_detail = "克制"
        elif ELEMENT_COUNTER.get(defender_element) == attacker_element:
            element_mult = RESIST_MULTIPLIER
            element_detail = "被克"

    raw_damage *= element_mult

    # 6. 元素伤害加成
    element_damage_bonus = float(attacker_stats.get("element_damage_bonus", 0.0))
    raw_damage *= (1.0 + element_damage_bonus)

    # 7. 暴击判定
    crit_rate = float(attacker_stats.get("crit_rate", 0.0))
    crit_damage = float(attacker_stats.get("crit_damage", 1.5))
    is_crit = False

    if skill_data.get("effects", {}).get("crit_guarantee", False):
        is_crit = True
    elif force_rand is not None and force_rand < crit_rate:
        is_crit = True
    elif force_rand is None and random.random() < crit_rate:
        is_crit = True

    if is_crit:
        raw_damage *= crit_damage

    # 8. 随机波动 ±10%
    if force_variance is not None:
        variance = force_variance
    else:
        variance = random.uniform(0.9, 1.1)
    raw_damage *= variance

    # 9. 最低保底
    final_damage = max(int(raw_damage), 1)

    # 10. 额外修饰
    for key, val in extra_modifiers.items():
        if key == "damage_bonus_pct":
            final_damage = int(final_damage * (1.0 + val))
        elif key == "flat_damage":
            final_damage += val

    return {
        "damage": final_damage,
        "is_crit": is_crit,
        "element": attacker_element,
        "element_mult": element_mult,
        "element_detail": element_detail,
        "defense_reduction": defense_reduction,
        "raw_before_variance": raw_damage,
    }


def calculate_healing(
    healer_stats: dict,
    target_stats: dict,
    skill_data: dict,
    force_variance: float = None,
):
    base_attack = float(healer_stats.get("attack", 10))
    heal_mult = float(skill_data.get("effects", {}).get("heal_mult", 1.0))
    heal_bonus = float(healer_stats.get("heal_bonus", 0.0))
    heal_amount = base_attack * heal_mult * (1.0 + heal_bonus)
    incoming_heal_bonus = float(target_stats.get("incoming_heal_bonus", 0.0))
    heal_amount *= (1.0 + incoming_heal_bonus)
    if force_variance is not None:
        variance = force_variance
    else:
        variance = random.uniform(0.95, 1.05)
    return max(int(heal_amount * variance), 1)


def calculate_shield(caster_stats: dict, skill_data: dict):
    base_attack = float(caster_stats.get("attack", 10))
    shield_mult = float(skill_data.get("effects", {}).get("shield_mult", 1.0))
    return max(int(base_attack * shield_mult), 1)


def roll_status_effect(base_prob: float, defender_stats: dict, force_rand: float = None):
    status_resist = float(defender_stats.get("status_resist", 0.0))
    effective_prob = base_prob * (1.0 - status_resist)
    if force_rand is not None:
        return force_rand < effective_prob
    return random.random() < effective_prob


# ═══════════════════════════════════════════
# 🧪 测试用例
# ═══════════════════════════════════════════

class TestDamageCalculator:

    def test_basic_damage_no_crit(self):
        """基础伤害·无暴击（固定波动 1.0）"""
        result = calculate_damage(
            {"attack": 100},
            {"defense": 0, "damage_reduction": 0},
            {"damage_mult": 1.0},
            force_variance=1.0,
        )
        # 100 * 1.0 * (1-0) * (1-0) * 1.0 * 1.0 * 1.0 = 100
        assert result["damage"] == 100
        assert not result["is_crit"]
        assert result["element_detail"] == ""

    def test_defense_reduction(self):
        """防御减伤效果"""
        result = calculate_damage(
            {"attack": 100},
            {"defense": 100},  # 100/(100+100)=50%减伤
            {"damage_mult": 1.0},
            force_variance=1.0,
        )
        # 100 * 0.5 = 50
        assert result["damage"] == 50
        assert abs(result["defense_reduction"] - 0.5) < 0.001

    def test_element_counter(self):
        """五行克制·金克木"""
        result = calculate_damage(
            {"attack": 100},
            {"defense": 0, "damage_reduction": 0, "element": "木"},
            {"damage_mult": 1.0, "element": "金"},
            force_variance=1.0,
        )
        # 100 * 1.5 = 150
        assert result["damage"] == 150
        assert result["element_mult"] == 1.5
        assert result["element_detail"] == "克制"

    def test_element_resisted(self):
        """五行被克·火被水克"""
        result = calculate_damage(
            {"attack": 100},
            {"defense": 0, "damage_reduction": 0, "element": "水"},
            {"damage_mult": 1.0, "element": "火"},
            force_variance=1.0,
        )
        # 100 * 0.67 ≈ 67
        assert result["damage"] == 67  # floor(100 * 0.67) = 67
        assert abs(result["element_mult"] - 0.67) < 0.01
        assert result["element_detail"] == "被克"

    def test_critical_hit(self):
        """暴击伤害"""
        result = calculate_damage(
            {"attack": 100, "crit_rate": 1.0, "crit_damage": 2.0},
            {"defense": 0, "damage_reduction": 0},
            {"damage_mult": 1.0},
            force_rand=0.0,  # 保证暴击
            force_variance=1.0,
        )
        # 100 * 2.0 = 200
        assert result["damage"] == 200
        assert result["is_crit"]

    def test_crit_guarantee(self):
        """技能必定暴击"""
        result = calculate_damage(
            {"attack": 100, "crit_rate": 0.0},
            {"defense": 0, "damage_reduction": 0},
            {"damage_mult": 1.0, "effects": {"crit_guarantee": True}},
            force_variance=1.0,
        )
        assert result["is_crit"]
        assert result["damage"] == 150  # 100 * 1.5 (默认暴伤)

    def test_minimum_damage(self):
        """保底伤害至少1"""
        result = calculate_damage(
            {"attack": 1},
            {"defense": 9999},
            {"damage_mult": 0.1},
            force_variance=0.9,
        )
        assert result["damage"] >= 1

    def test_extra_modifiers(self):
        """额外伤害加成"""
        result = calculate_damage(
            {"attack": 100},
            {"defense": 0, "damage_reduction": 0},
            {"damage_mult": 1.0},
            extra_modifiers={"damage_bonus_pct": 0.2, "flat_damage": 50},
            force_variance=1.0,
        )
        # (100 * 1.2) + 50 = 170
        assert result["damage"] == 170

    def test_element_damage_bonus(self):
        """元素伤害加成"""
        result = calculate_damage(
            {"attack": 100, "element_damage_bonus": 0.3},
            {"defense": 0, "damage_reduction": 0},
            {"damage_mult": 1.0, "element": "火"},
            force_variance=1.0,
        )
        # 100 * 1.3 = 130
        assert result["damage"] == 130

    def test_healing(self):
        """治疗量计算"""
        heal = calculate_healing(
            {"attack": 100, "heal_bonus": 0.2},
            {"incoming_heal_bonus": 0.1},
            {"effects": {"heal_mult": 1.5}},
            force_variance=1.0,
        )
        # 100 * 1.5 * 1.2 * 1.1 = 198
        assert heal == 198

    def test_shield(self):
        """护盾量计算"""
        shield = calculate_shield(
            {"attack": 100},
            {"effects": {"shield_mult": 2.0}},
        )
        assert shield == 200

    def test_status_effect(self):
        """状态命中率（考虑抗性）"""
        hit = roll_status_effect(
            base_prob=0.8,
            defender_stats={"status_resist": 0.5},
            force_rand=0.3,
        )
        # effective = 0.8 * (1-0.5) = 0.4, force_rand=0.3 < 0.4 → 命中
        assert hit is True

        miss = roll_status_effect(
            base_prob=0.8,
            defender_stats={"status_resist": 0.5},
            force_rand=0.5,
        )
        # effective = 0.4, force_rand=0.5 >= 0.4 → 未命中
        assert miss is False

    def test_element_relation_desc(self):
        """元素克制关系描述（纯字符串逻辑）"""
        # 直接在 GDScript 里测试；Python 侧验证克制表
        assert ELEMENT_COUNTER["金"] == "木"
        assert ELEMENT_COUNTER["木"] == "土"
        assert ELEMENT_COUNTER["水"] == "火"
        assert ELEMENT_COUNTER["火"] == "金"
        assert ELEMENT_COUNTER["土"] == "水"
        # 五行循环闭环
        assert all(k in ELEMENT_COUNTER for k in ["金", "木", "水", "火", "土"])
