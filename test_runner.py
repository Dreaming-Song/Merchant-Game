#!/usr/bin/env python3
"""
🔧 Merchant Game 自动化测试套件
每次运行会：
  1. 扫描所有 .gd 文件找常见 bug 模式
  2. 检查之前修复的文件是否完好
  3. 检查 tscn 节点类型匹配
  4. 写入测试日志到 test_logs/
用法: python3 test_runner.py
"""

import os, re, sys, json, datetime

BASE = os.path.join(os.path.dirname(__file__), "client")
LOG_DIR = os.path.join(os.path.dirname(__file__), "test_logs")
os.makedirs(LOG_DIR, exist_ok=True)

# ===== 检查的关键修复内容 =====
FIXED_FILES = {
    "hud.gd":              ["_update_hp_mp", "_update_spell_cooldowns", "_update_pet_info",
                             "_init_spell_slots", "_update_hunger", "_on_target_changed"],
    "chat_panel.gd":       ["fit_content", "_setup_signals"],
    "soul_forge_panel.gd": ["execute_button", "enchant_spinbox", "source_tabs"],
    "biome_manager.gd":    ["ambient_color", "sky_tint"],
    "minimap_hud.gd":      ["set_border_width_all"],
    "pet_panel.gd":        ["show_percentage"],
    "cultivation_aura.gd": ["material_override"],
    "skill_manager.gd":    ["mp_regen"],
    "world_boss.gd":       ["spawn_position"],
    "terrain_manager.gd":  ["ocean_level"],
}

# ===== 真正危险的模式（减少误报）=====
# 每条: (regex, 描述, 严重级别)
# 级别: "error"=❌, "warn"=⚠️
BUG_PATTERNS = [
    # 运算符优先级地狱 —— 真 bug
    (r"\bor\s+[\"']\s*==\s*[\"']", "error", "🔴 运算符优先级 bug: `or \"\" == xxx` 应该用括号"),
    
    # 废弃属性直接赋值
    (r"\.fit_content_height\b", "error", "🔴 废弃属性 fit_content_height（应改用 fit_content）"),
    (r"\.show_percentage\b", "error", "🔴 废弃属性 show_percentage"),
    (r"\.border_width_all\b\s*=", "error", "🔴 StyleBoxFlat 不能用 = 赋值 border_width_all"),
    
    # MeshInstance3D 用了 `material =` 而不是 `material_override =`
    # 只抓函数体内直接 material = 的模式
    (r"\.material\s*=", "warn", "🟡 检查是否 MeshInstance3D（应改用 .material_override =）"),
    
    # 危险的 await/free 模式
    (r"\.queue_free\(\)\s*\n\s*\.free\(\)", "error", "🔴 queue_free 后调用 free — 节点可能已被释放"),
    (r"await\s+.*\n\s*\.queue_free", "warn", "🟡 await 后 queue_free — 确保连接已断开"),
]


class TestResult:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.warnings = 0
        self.details = []
        self.categories = {"通过": [], "错误": [], "警告": []}

    def ok(self, msg):
        self.passed += 1
        self.details.append(f"  ✅ {msg}")
        self.categories["通过"].append(msg)

    def fail(self, msg):
        self.failed += 1
        self.details.append(f"  ❌ {msg}")
        self.categories["错误"].append(msg)

    def warn(self, msg):
        self.warnings += 1
        self.details.append(f"  ⚠️  {msg}")
        self.categories["警告"].append(msg)


def get_all_gd_files():
    """获取所有 gd 文件路径"""
    files = []
    for root, dirs, fnames in os.walk(BASE):
        for f in fnames:
            if f.endswith(".gd"):
                files.append(os.path.join(root, f))
    return files


def scan_for_bug_patterns(files, result):
    """逐文件扫描已知 bug 模式"""
    found_any = False
    for fp in sorted(files):
        with open(fp, "r", encoding="utf-8") as f:
            lines = f.readlines()
        rel = os.path.relpath(fp, BASE)
        for i, line in enumerate(lines, 1):
            for pattern, level, desc in BUG_PATTERNS:
                if re.search(pattern, line):
                    found_any = True
                    msg = f"{desc} → {rel}:{i} → `{line.strip()[:70]}`"
                    if level == "error":
                        result.fail(msg)
                    else:
                        result.warn(msg)
    if not found_any:
        result.ok("无已知 bug 模式")


def check_fix_integrity(result):
    """检查修复过的文件是否还健在"""
    gd_files = {os.path.basename(p): p for p in get_all_gd_files()}
    for fname, keywords in FIXED_FILES.items():
        if fname not in gd_files:
            result.warn(f"文件 {fname} 不存在！")
            continue
        with open(gd_files[fname], "r", encoding="utf-8") as f:
            content = f.read()
        for kw in keywords:
            if kw in content:
                result.ok(f"{fname} 含有关键内容 '{kw}'")
            else:
                result.fail(f"🔴 {fname} 缺少关键内容 '{kw}' — 修复可能被回滚！")


def check_tscn_types(result):
    """检查 tscn 节点类型"""
    tscn_files = []
    for root, dirs, fnames in os.walk(BASE):
        for f in fnames:
            if f.endswith(".tscn"):
                tscn_files.append(os.path.join(root, f))
    
    # 重点检查已知容易出错的节点
    checks = {
        "TerrainManager": "Node3D",
    }
    for fp in tscn_files:
        with open(fp, "r", encoding="utf-8") as f:
            content = f.read()
        for node_name, expected_type in checks.items():
            # 找 `name="xxx" type="yyy"`
            m = re.search(rf'name="{node_name}"\s+type="(\w+)"', content)
            if m:
                actual = m.group(1)
                if actual == expected_type:
                    result.ok(f"{os.path.basename(fp)} 中 {node_name} 类型 = {expected_type} ✅")
                else:
                    result.fail(f"🔴 {os.path.basename(fp)} 中 {node_name} 类型 = {actual}（应为 {expected_type}）")


def check_mixed_indent(result):
    """混合缩进检查"""
    for fp in get_all_gd_files():
        with open(fp, "r", encoding="utf-8") as f:
            lines = f.readlines()
        for i, line in enumerate(lines, 1):
            stripped = line.rstrip("\n")
            # 只检查非空非注释行
            if not stripped or stripped.strip().startswith("#"):
                continue
            if ("\t " in stripped or " \t" in stripped) and not stripped.startswith("#"):
                result.warn(f"混合缩进 → {os.path.relpath(fp, BASE)}:{i}")
                break  # 每个文件只报一次


def run():
    ts = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    result = TestResult()
    
    print("\n" + "="*60)
    print(f"🔧 Merchant Game 测试报告 — {ts}")
    print("="*60)
    
    gd_files = get_all_gd_files()
    print(f"\n📁 共 {len(gd_files)} 个 .gd 文件")
    
    # 1. 修复完整性
    print("\n📋 [1/4] 修复完整性检查...")
    check_fix_integrity(result)
    
    # 2. 已知 bug 模式
    print("\n🔍 [2/4] 已知 bug 模式扫描...")
    scan_for_bug_patterns(gd_files, result)
    
    # 3. tscn 节点类型
    print("\n🏗️  [3/4] tscn 节点类型检查...")
    check_tscn_types(result)
    
    # 4. 混合缩进
    print("\n📝 [4/4] 混合缩进检查...")
    check_mixed_indent(result)
    
    # 汇总
    print("\n" + "="*60)
    print(f"📊 结果: ✅ {result.passed} 通过 | ❌ {result.failed} 错误 | ⚠️  {result.warnings} 警告")
    print("="*60)

    # 如果有错误，打印详情
    if result.failed > 0:
        print(f"\n❌ 错误详情（{result.failed} 条）:")
        for d in result.details:
            if d.startswith("  ❌"):
                print(f"  {d}")
    
    # 写入日志
    log_entry = {
        "timestamp": ts,
        "passed": result.passed,
        "failed": result.failed,
        "warnings": result.warnings,
        "file_count": len(gd_files),
        "details": result.details,
    }
    logfile = os.path.join(LOG_DIR, f"test_{ts}.json")
    with open(logfile, "w", encoding="utf-8") as f:
        json.dump(log_entry, f, ensure_ascii=False, indent=2)
    
    # 追加到汇总 CSV
    summary_file = os.path.join(LOG_DIR, "_summary.csv")
    need_header = not os.path.exists(summary_file)
    with open(summary_file, "a", encoding="utf-8") as f:
        if need_header:
            f.write("timestamp,files,passed,failed,warnings\n")
        f.write(f"{ts},{len(gd_files)},{result.passed},{result.failed},{result.warnings}\n")
    
    print(f"\n📄 日志: {os.path.basename(logfile)}")
    print(f"📊 汇总: {os.path.basename(summary_file)}")
    
    return result


if __name__ == "__main__":
    run()
