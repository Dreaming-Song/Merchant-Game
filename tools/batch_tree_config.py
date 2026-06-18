#!/usr/bin/env python3
"""
树木物理参数批量配置工具 - Phase 1
用于一键生成/更新 Godot 场景中所有树木的物理参数

用法:
    python batch_tree_config.py --config trees_config.json --output ../client/scenes/world/trees.tscn

说明:
    读取 JSON 配置文件，生成对应树木实例的 Godot .tscn 文件
    方便批量调整物理参数，不用逐个手动改
"""

import json
import sys
import os
from typing import List, Dict

TREE_TEMPLATE = """[gd_scene load_steps=2 format=3 uid="uid://{uid}"]

[ext_resource type="PackedScene" uid="uid://{tree_uid}" path="res://assets/models/{model_path}" id="1_trees"]

[node name="Tree{index}" type="RigidBody3D"]
scripts = {{"": Resource("res://scripts/world/tree_interaction.gd")}}
transform = Transform3D({transform})
tree_name = "{name}"
health = {health}
wood_drop_count = {drop_count}
fall_impulse_strength = {impulse}

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("1")

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
mesh = SubResource("2")
"""


def generate_tree_scene(trees: List[Dict], output_path: str) -> None:
    """根据配置生成树木场景文件"""
    lines = [
        "[gd_scene load_steps=2 format=3]",
        "",
        "[sub_resource type="CylinderShape3D" id=1]",
        "radius = 0.3",
        "height = 2.0",
        "",
        "[sub_resource type="CylinderMesh" id=2]",
        "top_radius = 0.3",
        "bottom_radius = 0.3",
        "height = 2.0",
        "",
    ]

    for i, tree in enumerate(trees):
        transform = f"{tree.get('pos_x', 0)}, {tree.get('pos_y', 0)}, {tree.get('pos_z', 0)}"
        lines.append(
            f'[node name="Tree_{i}" type="RigidBody3D"]\n'
            f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {transform})\n'
            f'tree_name = "{tree.get("name", "竹")}"\n'
            f'health = {tree.get("health", 3)}\n'
            f'wood_drop_count = {tree.get("drop_count", 2)}\n'
            f'fall_impulse_strength = {tree.get("impulse", 5.0)}\n'
            f'script = ExtResource("1_trees")\n'
        )

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"✅ 已生成 {len(trees)} 棵树 → {output_path}")


def load_config(config_path: str) -> List[Dict]:
    """加载树木配置 JSON"""
    with open(config_path, "r", encoding="utf-8") as f:
        return json.load(f)


def create_sample_config(output_path: str) -> None:
    """生成示例配置文件"""
    sample = [
        {"name": "竹", "pos_x": 10, "pos_y": 0, "pos_z": 5, "health": 2, "drop_count": 3, "impulse": 4.0},
        {"name": "竹", "pos_x": 12, "pos_y": 0, "pos_z": 3, "health": 2, "drop_count": 3, "impulse": 4.0},
        {"name": "桃树", "pos_x": -5, "pos_y": 0, "pos_z": 8, "health": 4, "drop_count": 5, "impulse": 6.0},
        {"name": "松树", "pos_x": -8, "pos_y": 0, "pos_z": -3, "health": 5, "drop_count": 4, "impulse": 7.0},
        {"name": "松树", "pos_x": -10, "pos_y": 0, "pos_z": -5, "health": 5, "drop_count": 4, "impulse": 7.0},
    ]
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(sample, f, ensure_ascii=False, indent=2)
    print(f"✅ 示例配置已生成 → {output_path}")
    print("  修改后运行: python batch_tree_config.py --config trees_config.json --output trees.tscn")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="树木物理参数批量配置工具")
    parser.add_argument("--config", help="树木配置 JSON 文件路径")
    parser.add_argument("--output", default="../client/scenes/world/trees.tscn", help="输出 .tscn 文件路径")
    parser.add_argument("--sample", help="生成示例配置文件路径", default="")

    args = parser.parse_args()

    if args.sample:
        create_sample_config(args.sample)
    elif args.config:
        config = load_config(args.config)
        generate_tree_scene(config, args.output)
    else:
        print("请指定 --config 或 --sample")
        sys.exit(1)
