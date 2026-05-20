# 补充 demo_script.json 图片资源过程总结

## 需求分析

`resources/demo_script.json` 剧本中共引用 3 个图片资源：

| 资源路径 | 用途 | 出现场景 |
|---|---|---|
| `res://assets/bg/school_gate.png` | 学校门口背景 | 开场、冷淡分支 |
| `res://assets/characters/heroine1.png` | 女主角立绘 | 樱井美咲出场时 |
| `res://assets/bg/sakura.png` | 樱花背景 | 好感结局 |

## 实现方案

使用 `generate_images.py` 以纯 Python **程序化生成** PNG 图片，无需 Pillow 等外部图像库。

核心原理：通过 `zlib` + `struct` 手动构建 PNG 文件格式（IHDR 头、IDAT 压缩数据、IEND 尾）。

### 生成的 3 张图片

1. **school_gate.png** (640×360, RGB)
   - 天空（淡蓝）、草地（绿色）、道路（灰色）
   - 校门框架（木色）+ 两侧门柱（灰色）

2. **heroine1.png** (256×384, RGBA)
   - 圆形头部（肤色）、粉色头发
   - 身体与手臂（蓝色制服）、腿部（肤色）
   - 支持透明背景

3. **sakura.png** (640×360, RGB)
   - 天空渐变（上浅下深）
   - 棕色树干 + 粉色樱花树冠
   - 飘落花瓣点缀

## 执行结果

脚本运行后，3 张 PNG 已写入对应目录：

```
assets/
├── bg/
│   ├── school_gate.png
│   └── sakura.png
└── characters/
	└── heroine1.png
```

`demo_script.json` 所需图片资源全部就绪，项目可直接在 Godot 中运行。
