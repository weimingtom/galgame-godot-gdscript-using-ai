# Godot Galgame Engine

一个简单的 Godot 4.x 视觉小说/Galgame 引擎，使用 JSON 作为脚本格式。

## 项目结构

```
project.godot          # Godot 项目文件
scenes/
  main.tscn           # 主游戏场景
scripts/
  game.gd             # 主游戏控制器
  dialogue_manager.gd # 对话管理器（打字机效果、自动播放）
  script_parser.gd    # JSON 剧本解析器
resources/
  demo_script.json    # 示例剧本
assets/               # 资源文件夹（需自行添加）
  bg/                 # 背景图片
  characters/         # 角色立绘
  bgm/                # 背景音乐
  sfx/                # 音效
```

## 使用方法

1. 用 Godot 4.x 打开项目
2. 将图片资源放入 `assets/` 对应文件夹
3. 修改 `resources/demo_script.json` 或创建新剧本
4. 运行场景 `scenes/main.tscn`

## 键盘操作

| 按键 | 功能 |
|------|------|
| 空格 / 鼠标左键 | 继续对话 / 完成打字 |
| ESC / Enter | 跳过当前打字 |
| A | 切换自动播放 |
| S | 快速保存 |
| L | 快速读取 |

## JSON 剧本格式

### 基本结构

```json
{
  "title": "剧本标题",
  "author": "作者",
  "version": "1.0",
  "scenes": [
    {
      "id": "scene_1",
      "lines": [
        // 剧本行...
      ],
      "next_scene": "scene_2"  // 可选：场景结束后自动跳转
    }
  ]
}
```

### 行类型

#### 1. 对话 (dialogue)

```json
{
  "type": "dialogue",
  "speaker": "角色名",
  "text": "对话内容",
  "background": "res://assets/bg/school.png",  // 可选：切换背景
  "character": "res://assets/characters/hero.png",  // 可选：显示角色
  "position": "center",  // 可选：left / center / right
  "expression": "smile",  // 可选：表情后缀
  "hide_character": "left",  // 可选：隐藏指定位置角色（或 "all"）
  "effect": "fade_in"  // 可选：视觉效果
}
```

#### 2. 旁白 (narration)

```json
{
  "type": "narration",
  "text": "旁白内容",
  "background": "res://assets/bg/black.png"
}
```

#### 3. 分支选项 (choice)

```json
{
  "type": "choice",
  "options": [
    {
      "text": "选项1",
      "target": "scene_a",  // 跳转目标场景
      "condition": {        // 可选：条件判断
        "variable": "friendship",
        "operator": ">=",
        "value": 10
      },
      "effects": [          // 可选：执行效果
        {
          "type": "set_variable",
          "name": "friendship",
          "value": 5
        }
      ]
    }
  ]
}
```

#### 4. 场景切换 (scene_change)

```json
{
  "type": "scene_change",
  "target": "next_scene_id"
}
```

#### 5. 背景音乐 (bgm)

```json
{
  "type": "bgm",
  "path": "res://assets/bgm/ost1.ogg",
  "action": "play"  // play / stop
}
```

#### 6. 音效 (sfx)

```json
{
  "type": "sfx",
  "path": "res://assets/sfx/door.ogg"
}
```

#### 7. 等待 (wait)

```json
{
  "type": "wait",
  "duration": 2.0
}
```

### 视觉效果 (effect)

- `fade_in` - 淡入
- `fade_out` - 淡出
- `shake` - 震动
- `flash` - 闪白

### 角色位置 (position)

- `left` - 左侧
- `center` - 中央（默认）
- `right` - 右侧

### 表情系统

在 `character` 路径中使用表情参数时，引擎会自动替换文件名：

```json
"character": "res://assets/characters/hero.png",
"expression": "smile"
// 实际加载: res://assets/characters/hero_smile.png
```

## 扩展建议

1. **存档系统**：当前实现了基础存档/读档，可扩展为多槽位存档UI
2. **历史记录**：添加对话历史回看功能
3. **设置菜单**：音量、文字速度、全屏等选项
4. **角色动画**：使用 Godot AnimationPlayer 实现更多立绘动画
5. **立绘过渡**：添加淡入淡出、滑动等切换效果
6. **文本样式**：支持富文本标签（颜色、大小等）
7. **条件系统**：扩展更复杂的变量和条件判断

## 示例剧本说明

`resources/demo_script.json` 包含一个完整的示例故事：
- 转学第一天遇到女主角
- 两个分支选项（友好/冷淡）
- 四个不同结局（好感/普通/遗憾）

可直接运行查看效果（需准备对应资源图片，或使用占位图片测试）。
