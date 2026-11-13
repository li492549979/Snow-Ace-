# Snow Ace — Midjourney 提示词（像素风 / 战国之刃风格）

> 主题默认 = **日式神怪封建空战**（贴合《战国之刃 Sengoku Blade》）。想换主题（科幻 / 冬季雪国 / 蒸汽朋克等），把每条提示里的主题词替换即可，参数不变。

## ⚠️ 使用前必读
1. **MJ 不输出真透明 PNG**：所有精灵提示都要求 `flat solid dark background`。生成后到 Aseprite / Photoshop 里**用魔术棒抠掉纯色背景**再存 PNG。
2. **MJ 像素画需要清理**：MJ 常带抗锯齿、多余细节、比例漂移。把输出当**高质量草稿**，进 Aseprite 收敛像素、统一色板、裁到目标画布。
3. **动画帧（精灵表）MJ 不稳定**：帧数/对齐常不对。建议先生成单帧定形象，动画帧手动补；或用 MJ 出的表作参考重画。
4. **比例参数 `--ar`** 只是把长宽比弄接近，最终精确尺寸（如 32×20）在编辑器里**缩放/裁剪**到位。
5. 复制每条提示（含末尾参数）直接粘进 MJ 即可。版本参数写的是 `--v 6.1`，可改用你账号的最新版；想要更"动漫/日式"可用 `--niji 6`。

## 通用风格后缀（每条已内含，无需手动加）
`16-bit pixel art, arcade shoot-em-up sprite, Sengoku Blade aesthetic, detailed pixel shading, crisp clean pixels, side view, isolated on a flat solid dark background`

---

## 🚀 玩家与子弹

### 玩家·飞天巫女 (32×20, 朝右)
```
pixel art sprite of a flying miko shrine maiden character, young girl in white kimono jacket and red hakama trousers soaring through the air to the right, long flowing sleeves and sacred ribbons trailing behind, glowing spiritual energy aura, holding a paper charm ofuda, side view, 16-bit pixel art, arcade shoot-em-up sprite, Sengoku Blade aesthetic, detailed pixel shading, crisp clean pixels, isolated on a flat solid dark background --no text, watermark, signature, border --ar 8:5 --v 6.1
```

### 玩家弹·符咒 (16×4, 朝右)
```
pixel art sprite of a flying ofuda paper charm projectile, small sacred talisman strip with a red seal trailing spiritual energy, facing right, 16-bit arcade shmup, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 4:1 --v 6.1
```

### 敌弹 (12×4)
```
pixel art sprite of a glowing red demon-fire bullet, small round orb with flame trail, 16-bit arcade shmup, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 3:1 --v 6.1
```

### 激光段·灵力光柱 (128×32, 水平可平铺)
```
pixel art horizontal beam of sacred spiritual light, divine kagura light beam, white and gold bright core with soft holy glow, seamlessly tileable left-to-right, 16-bit shmup, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 4:1 --v 6.1
```

---

## 👾 敌人（全部朝左，侧视）

### Basic 兵 (32×20)
```
pixel art sprite of a demonic flying enemy, red oni-like creature riding a wooden flying contraption, facing left, side view, 16-bit arcade shmup, Sengoku Blade style, detailed pixel shading, crisp pixels, isolated on a flat solid dark background --no text, watermark, border --ar 8:5 --v 6.1
```

### Dive 俯冲兵 (32×16)
```
pixel art sprite of a diving enemy, orange winged demon swooping downward, facing left, side view, 16-bit arcade shmup, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 2:1 --v 6.1
```

### Sniper 狙击兵 (36×20)
```
pixel art sprite of a floating sniper turret creature, dark crimson body with one glowing eye and a long cannon, facing left, side view, 16-bit arcade shmup, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 9:5 --v 6.1
```

### Rush 冲撞兵 (24×14, 小而快)
```
pixel art sprite of a small fast charging enemy, yellow spiked ram creature, aggressive pose, facing left, side view, 16-bit arcade shmup, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 12:7 --v 6.1
```

### Formation 编队兵 (28×16)
```
pixel art sprite of a green insectoid flying enemy, beetle-like with translucent wings, facing left, side view, 16-bit arcade shmup, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 7:4 --v 6.1
```

### RingShooter 环形射手 (32×20)
```
pixel art sprite of a green floating turret enemy, rotating ring cannon with glowing core, facing left, side view, 16-bit arcade shmup, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 8:5 --v 6.1
```

### Spread 散射兵 (32×20)
```
pixel art sprite of an orange armored gunner pod, multiple spread barrels, facing left, side view, 16-bit arcade shmup, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 8:5 --v 6.1
```

### MidBoss 中boss (48×32)
```
pixel art sprite of a mid-boss, large purple demon warship with sails and broadside cannons, facing left, side view, Japanese mythic shmup boss, 16-bit detailed pixel art, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark, border --ar 3:2 --v 6.1
```

### Boss 终boss (60×40)
```
pixel art sprite of a final boss, massive demonic flying fortress, oni-face warship with glowing eyes and many cannons, facing left, side view, epic Japanese mythic shmup boss, highly detailed 16-bit pixel art, Sengoku Blade style, crisp pixels, isolated on a flat solid dark background --no text, watermark, border --ar 3:2 --v 6.1
```

---

## 🎁 拾取物（5 种，每个 10×10）

> 一次生成 5 个一排（方便），或单独生成。抠背景后切成 5 个图标。
```
pixel art sprite row of five game pickups side by side: blue weapon-up crystal, pink health heart, orange bomb icon, small yellow score coin, large gold score gem, 16-bit shmup items, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 5:1 --v 6.1
```

---

## 💥 爆炸（精灵表，6–10 帧）

> MJ 精灵表不稳定，生成后需在 Aseprite 重新对齐/补帧。
```
pixel art explosion sprite sheet, horizontal sequence of frames, fiery orange and yellow blast expanding then fading to smoke, 16-bit shmup explosion animation, crisp pixels, isolated on a flat solid dark background --no text, watermark --ar 4:1 --v 6.1
```

---

## 🏞️ 背景：多层视差（每段一套，共 4 段）

每段做 **3 层**（远/中/近），都是**水平无缝可平铺**的横长图。`motion_scale` 由我配（远慢近快）。
建议尺寸 ≥ 960×270，`--ar 7:2` 接近。

**4 段主题**（对应关卡 4 个 section 的色调）：
1. **夜空雪原**（深蓝）：夜空 + 雪原 + 远山
2. **山岳寺院**（土褐）：群山 + 古寺/鸟居
3. **幽暗竹林**（墨绿）：竹林 + 神社
4. **火山魔城**（暗红）：熔岩 + 魔王城

**层级模板**（把 `{主题}` 换成上面四个之一；下面给 Section 1 的完整三例，其余段照换）：

### Section 1 — 远景（天空/远山，慢滚）
```
pixel art side-scrolling shmup background, far parallax layer, night sky over distant snowy mountains and drifting clouds, deep blue tones, seamless horizontal tile, 16-bit, Sengoku Blade aesthetic, crisp pixels, atmospheric --no text, watermark --ar 7:2 --v 6.1
```

### Section 1 — 中景（主体场景，中速）
```
pixel art side-scrolling shmup background, mid parallax layer, snowy village rooftops and wooden fences under moonlight, deep blue and white tones, seamless horizontal tile, 16-bit, Sengoku Blade aesthetic, crisp pixels --no text, watermark --ar 7:2 --v 6.1
```

### Section 1 — 近景（前景细节，快滚）
```
pixel art side-scrolling shmup background, near foreground parallax layer, dark pine branches and hanging snow drifting past, silhouetted, seamless horizontal tile, 16-bit, Sengoku Blade aesthetic, crisp pixels --no text, watermark --ar 7:2 --v 6.1
```

> Section 2/3/4：复制上面三条，把场景描述换成对应主题词即可（山岳寺院 / 幽暗竹林 / 火山魔城），色调随之改（土褐 / 墨绿 / 暗红）。

---

## 📥 生成后的处理流程
1. 抠背景（Aseprite 魔术棒选纯色 → 删除；或 remove.bg / PS）。
2. 收敛像素：统一色板、去抗锯齿、裁到目标画布（玩家 32×20、杂兵 32×20、Boss 60×40…见下表）。
3. 动画：把精灵表切成等宽帧，或手动补帧；导出横排 PNG。
4. 存 PNG 放进 `art/` 对应子目录（player / enemies / bullets / effects / pickups / background）。
5. 丢给我，我接进场景（换占位色块 → Sprite2D/AnimatedSprite2D，2× 显示，建 ParallaxBackground）。

### 目标画布速查（源像素画尺寸，2× 显示后≈现有碰撞框）
| 对象 | 源画布 | 对象 | 源画布 |
|---|---|---|---|
| 玩家(巫女) | 32×20 | RingShooter | 32×20 |
| 玩家弹 | 16×4 | Spread | 32×20 |
| 敌弹 | 12×4 | MidBoss | 48×32 |
| 激光段 | 128×32 | Boss | 60×40 |
| Basic | 32×20 | 拾取 | 10×10 |
| Dive | 32×16 | 爆炸帧 | 32×32 |
| Sniper | 36×20 | 背景层 | ≥960×270 |
| Rush | 24×14 | | |
| Formation | 28×16 | | |
