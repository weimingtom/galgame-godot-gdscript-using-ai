# Galgame Engine 项目总结

## 项目概述

基于 Godot 4.x 的简单视觉小说/Galgame 引擎，使用 JSON 作为脚本格式。

## 文件结构

```
hello1/
├── project.godot              # Godot 4.x 项目配置
├── scenes/
│   └── main.tscn             # 主游戏场景（含UI布局）
├── scripts/
│   ├── game.gd               # 主控制器（场景管理、输入、存档）
│   ├── dialogue_manager.gd   # 打字机效果 + 自动播放
│   └── script_parser.gd      # JSON 剧本解析器
├── resources/
│   └── demo_script.json      # 完整示例剧本（含分支和3个结局）
├── README.md                 # 详细使用文档
└── summary.md                # 本文件
```

## 核心功能

- **JSON 格式剧本**：支持对话、旁白、分支选项、场景跳转、BGM、音效、等待
- **打字机效果**：逐字显示文本，支持空格/点击跳过
- **画面控制**：背景切换 + 左/中/右角色立绘 + 表情后缀系统
- **自动播放**：按 `A` 键切换，文本显示完后自动前进
- **快速存档/读档**：`S` 键保存，`L` 键读取
- **视觉效果**：淡入淡出、震动、闪白

## 操作说明

| 按键 | 功能 |
|------|------|
| 空格 / 鼠标左键 | 继续对话 / 完成打字 |
| ESC / Enter | 跳过当前打字 |
| A | 切换自动播放 |
| S | 快速保存 |
| L | 快速读取 |

## 使用方法

1. 用 Godot 4.x 打开项目
2. 在 `assets/` 文件夹放入图片资源（背景、角色立绘等）
3. 修改 `resources/demo_script.json` 或创建新剧本
4. 运行场景 `scenes/main.tscn`

## 示例剧本

`resources/demo_script.json` 包含一个完整的示例故事：
- 转学第一天遇到女主角
- 两个分支选项（友好/冷淡）
- 四个不同结局（好感/普通/遗憾/普通分支的遗憾）

可直接参考 JSON 格式编写自己的剧本。
