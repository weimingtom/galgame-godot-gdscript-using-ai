# Galgame Demo — 项目总结

基于 **Godot 4** 的视觉小说（Galgame）框架，包含完整示例剧情，可直接导入运行。

## 项目结构

```
work_godot_galgame/
├── project.godot
├── default_bus_layout.tres   # Music / SFX 音频总线
├── scenes/
│   ├── main_menu.tscn
│   ├── game.tscn
│   └── ui/
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd     # 存档、剧情标记
│   │   ├── story_loader.gd   # 剧情与章节清单
│   │   └── audio_manager.gd  # BGM / 音效
│   ├── game.gd
│   ├── background_layer.gd
│   ├── character_layer.gd
│   ├── dialogue_box.gd
│   └── choice_panel.gd
├── data/
│   ├── chapters.json         # 章节清单与解锁条件
│   ├── chapter1.json
│   └── chapter2.json
└── assets/
    ├── characters/           # 立绘 SVG（按 角色/表情.svg）
    ├── backgrounds/          # 背景 SVG
    ├── audio/bgm/            # 背景音乐 WAV
    ├── audio/se/             # 音效
    └── theme/
```

## 已实现功能

| 功能 | 说明 |
|------|------|
| 对话系统 | 打字机效果，点击/空格/Enter 继续 |
| 立绘图片 | 按 `assets/characters/{id}/{expression}.svg` 自动加载，支持表情切换 |
| 背景图片 | `bg` 节点支持 `image` 字段，与 `color` 叠加使用 |
| BGM 系统 | 淡入淡出、循环播放、章节默认 BGM、暂停菜单静音 |
| 音效 | 选项确认等场景可播放 `se` 节点 |
| 多章节 | `chapters.json` 管理章节，第一章结束后自动进入第二章 |
| 分支选项 | 多选项跳转不同剧情 |
| 剧情标记 | `set_flag` / `if_flag` 控制分支与章节解锁 |
| 存档 | 菜单内保存，标题画面可继续 |

## 如何运行

1. 安装 [Godot 4.3+](https://godotengine.org/)
2. 打开 Godot → **导入** → 选择 `project.godot`
3. 按 **F5** 运行

### 操作说明

- **左键 / 空格 / Enter**：推进对话
- **Ctrl 或点击**：跳过打字动画
- **右上角「菜单」**：存档、返回标题

## 立绘资源约定

将立绘放入 `assets/characters/{角色id}/{表情}.svg`（也支持 png、webp 等 Godot 可导入格式）。

```
assets/characters/
├── linxue/
│   ├── default.svg
│   └── shy.svg
└── chenyu/
    └── default.svg
```

剧情中引用：

```json
{ "type": "show", "id": "linxue", "name": "林雪", "slot": "center", "expression": "default" }
{ "type": "expression", "id": "linxue", "expression": "shy" }
{ "type": "dialogue", "speaker": "林雪", "text": "……", "active": "linxue", "expression": "shy" }
```

也可显式指定路径：`"image": "res://assets/characters/linxue/shy.svg"`

## BGM / 音效

章节 JSON 顶部可设默认 BGM：

```json
{
  "id": "chapter1",
  "title": "第一章",
  "bgm": "res://assets/audio/bgm/spring.wav",
  "bgm_volume": -10
}
```

剧情节点：

```json
{ "type": "bgm", "path": "res://assets/audio/bgm/spring.wav", "fade": 1.5, "volume": -10 }
{ "type": "bgm_stop", "fade": 1.0 }
{ "type": "se", "path": "res://assets/audio/se/click.wav", "volume": -8 }
```

替换 `assets/audio/bgm/` 下的 WAV 文件即可；推荐使用 OGG 以减小体积（路径改为 `.ogg` 即可）。

## 多章节切换

`data/chapters.json` 定义章节顺序与解锁条件：

```json
{
  "chapters": [
    { "id": "chapter1", "title": "第一章", "order": 1 },
    { "id": "chapter2", "title": "第二章", "order": 2, "requires": "chapter1_clear" }
  ]
}
```

剧情中切换章节：

```json
{ "type": "chapter", "id": "chapter2", "fade_bgm": 1.0 }
```

新增章节：创建 `data/chapter3.json` 并在 `chapters.json` 中注册即可。

## 剧情脚本格式（完整节点）

```json
{ "type": "bg", "color": "#2d4a6e", "image": "res://assets/backgrounds/corridor.svg" }
{ "type": "show", "id": "linxue", "name": "林雪", "slot": "center", "expression": "default" }
{ "type": "dialogue", "speaker": "林雪", "text": "你好！", "active": "linxue" }
{ "type": "choice", "options": [{ "text": "选项A", "goto": 10, "set_flag": { "key": true } }] }
{ "type": "if_flag", "flag": "romantic", "then": 20, "else": 22 }
{ "type": "jump", "index": 10 }
{ "type": "set_flag", "flags": { "chapter1_clear": true } }
{ "type": "hide", "id": "chenyu" }
{ "type": "chapter", "id": "chapter2" }
{ "type": "end", "title": "完", "text": "感谢游玩" }
```

## 核心脚本

| 文件 | 职责 |
|------|------|
| `scripts/autoload/audio_manager.gd` | BGM 淡入淡出、循环、音效播放 |
| `scripts/autoload/game_state.gd` | 全局状态、存档读写、剧情标记 |
| `scripts/autoload/story_loader.gd` | 加载剧情 JSON 与章节清单 |
| `scripts/background_layer.gd` | 背景色 + 背景图切换 |
| `scripts/character_layer.gd` | 立绘站位、表情、高亮 |
| `scripts/game.gd` | 剧情节点解释器 |

## 后续可扩展

- 将 SVG 占位立绘替换为正式 PNG 立绘
- 使用 OGG 格式 BGM 并添加语音（Voice）总线
- CG 全屏展示节点
- 多档位存档与回想（Gallery）模式
