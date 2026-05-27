# 项目结构梳理 — shards-of-me

> 浮浮酱整理喵～ 基于当前 `merge-features` 分支快照，对照 Godot 4.4 项目最佳实践给出结构图、问题清单与改进建议。

## 一、项目定位

- **类型**：Godot 4.4 制作的 2D 视觉小说 / 解谜游戏（第一人称剧情向）
- **模板来源**：[crystal-bit/godot-game-template](https://github.com/crystal-bit/godot-game-template)（带来 `GGT` 单例与 `GGT_DebugShortcuts`）
- **关键插件**：`dialogic`（剧情/存档）、`phantom_camera`（运镜）、`ggt-core`（场景过渡）
- **主入口**：`res://scenes/menu/menu.tscn`

## 二、目录总览

```text
godot-shards-of-me/
├── project.godot                  # 主配置 + 11 个 autoload + Dialogic 配置
├── readme.md                      # 几乎空白，仅模板说明
├── default_bus_layout.tres        # 音频总线（Master/SFX/Music），位于根目录
├── export_presets.cfg / release.sh
│
├── addons/                        # 第三方插件（dialogic / ggt-core / ggt-debug-shortcuts / phantom_camera）
│
├── scripts/                       # 全部为 autoload 单例（扁平，无子目录）
│   ├── EventBus.gd                # 全局事件总线
│   ├── DataManager.gd             # autoload 名 "Data"，class_name DataManager
│   ├── ChapterManager.gd          # autoload 名 "Chapter"，class_name ChapterManager
│   ├── GameManager.gd             # autoload 名 "GameManager"
│   ├── AudioManager.gd            # autoload 名 "Audio"
│   ├── ClueManager.gd             # autoload 名 "ClueManager"
│   └── ItemData.gd                # autoload 名 "ItemData"（其实是静态工具类）
│
├── scenes/
│   ├── testfield.tscn             # 测试场景，散落在 scenes 顶层
│   ├── menu/                      # 主菜单 + 版本号脚本
│   ├── gameplay/
│   │   ├── start.tscn(.gd)        # 起始 Room，硬编码 next_scene
│   │   ├── room/room_template.*   # Room 基类（class_name Room）
│   │   ├── player/player.*        # PlayerCharacter
│   │   ├── npc/npc.tscn
│   │   └── chapters/chapter0/     # 章节场景 + 两份 cutscene_director（旧/新）
│   ├── props/                     # Prop 基类 / door / item_template / prop_desk / collider
│   └── ui/                        # ui_layer / pause-layer / inventory / clue_book
│                                  # / item_layer / password_lock / screen_crack / key_hint
│
├── resources/                     # 数据/主题
│   ├── chapters.json              # 章节定义（被 ChapterManager 加载）
│   ├── items.json                 # 物品定义（被 ItemData 加载）
│   ├── floor_tile.tres
│   └── theme/theme-main.tres
│
├── dialogs/                       # Dialogic 资源（部分）
│   ├── chapter0.dtl(.uid)
│   ├── ouyang_ye.dch / ye_li.dch
│   ├── style.tres                 # Dialogic 样式
│   └── test.dtl4141366604.tmp     # 编辑器临时文件，已入版本库
│
├── assets/
│   ├── audios/                    # BGM*.wav + mirror_shattered.mp3
│   ├── fonts/                     # open-sans + 纳米点宋.ttf
│   ├── tilesets/left_walls.tres   # TileSet 资源
│   └── images/
│       ├── backgrounds/           # 当前背景图 + 「旧资产/」+「参考.png」
│       ├── items/                 # key/paper/desk/crack 等
│       ├── sprites/               # icon + chara_0~99 + 「baka/」目录
│       ├── standing/              # 立绘 + 一份 li.dch（错位！）
│       ├── tilesets/              # 与上面 assets/tilesets/ 重名
│       │   └── wall_tile_01.png.import   # ⚠ 缺源 png
│       └── ui/                    # Dia_background + clue_book / mirror_shattered / password_lock
│
├── docs/                          # 接口文档-DataManager与ChapterManager.md
├── .doc/                          # 策划资料（被 .gitignore，本地保留）
├── .github/  .vscode/  .claude/   # 开发环境配置
└── builds/                        # 构建输出（gitignore）
```

## 三、各模块职责速查

| 目录 | 职责 | 入口/约定 |
|---|---|---|
| `scripts/*Manager.gd` | 全局单例，互相通过 `EventBus` 解耦 | autoload 顺序：GGT → EventBus → Data → Chapter → GameManager → Dialogic → ItemData → ClueManager → Audio |
| `scenes/gameplay/room/` | `Room` 基类，封装相机稳定、bgm 播放、跨场景切换 | 章节场景 `extends Room` |
| `scenes/props/` | `Prop` 基类（互动），`door` / `item_template` 继承 | 通过 `handle_interact()` 多态 |
| `scenes/ui/` | UI 层，监听 EventBus 信号 | `ui_layer.tscn` 是主容器，包含 pause/item 子层 |
| `resources/chapters.json` | 章节定义（id → name/data/next.expression） | `ChapterManager.next(flag,a,b)` 三元辅助 |
| `resources/items.json` | 物品库（id → name/type/texture/description） | `ItemData.get_item_info(id)` |
| 持久化 | 节点加入 `Persist` 组并实现 `save_data/load_data` | 数据写入 Dialogic `process` slot |

## 四、问题清单

### 🔴 高优先级（影响正确性 / 维护性）

1. **autoload 命名风格混乱**
   - 文件名 `DataManager.gd` / `ChapterManager.gd` / `AudioManager.gd` 注册为 `Data` / `Chapter` / `Audio`（去 Manager 后缀）
   - 而 `GameManager` / `ClueManager` / `ItemData` / `EventBus` 保留全名
   - `class_name DataManager` 与节点名 `Data` 同时存在，新人易误写 `DataManager.load_persistent_data()`
   - **后果**：`Persist` 协议以 `node.name` 为 key（见 [DataManager](scripts/DataManager.gd:53)），改名会让旧存档失效

2. **文档与实现不一致（API 漂移）**
   - `docs/接口文档-DataManager与ChapterManager.md` 称 `EventBus.enter_chapter`，实际信号名是 [`chapter_enter`](scripts/EventBus.gd:33)
   - 文档称 `GameManager._ready()` 会先 `await Data.load_persistent_data()`，实际 [GameManager](scripts/GameManager.gd:14) 只调用了 `Chapter.load_chapter_data(...)`，加载存档动作放在 [`menu.gd`](scenes/menu/menu.gd:97) 的"开始游戏"按钮里
   - **后果**：按文档接入新章节会读到错误信号，bug 难定位

3. **EventBus 死信号 / 命名规范自相矛盾**
   - [EventBus.gd](scripts/EventBus.gd:23) 中 `storage_load_data` / `storage_save_data` / `storage_clear_data` 全工程零调用（grep 仅命中定义自身）
   - 注释开宗明义"主语_谓语形式"，但 `chapter_enter` / `clue_add_item` / `slot_add_item` 是「主语_动词」，与 `enter_chapter`、`add_clue` 之类自然语序冲突
   - 文件首行用 `"""..."""` 字符串字面量当 docstring，不是 GDScript 的 `##` 文档注释（会被求值后丢弃，浪费微小性能）

4. **测试场景与版本库残留物**
   - `scenes/testfield.tscn` 散落在 `scenes/` 顶层（其它都按子目录分类）
   - `dialogs/test.dtl4141366604.tmp`（Dialogic 编辑器临时文件）被 git 跟踪
   - `assets/images/backgrounds/旧资产/`（中文目录 + 旧资产）整体保留
   - `assets/images/backgrounds/参考.png` / `assets/images/tilesets/这个对不齐.png` 是工作记号文件
   - `assets/images/tilesets/wall_tile_01.png.import` 没有对应源 png（孤儿 import）
   - **建议**：测试/参考资源单独放 `tests/` 或 `_scratch/`，并加入 `.gitignore`

5. **Dialogic 资源摆放不一致**
   - `project.godot` 的 `dch_directory` 把 `li` 角色指向 `res://assets/images/standing/li.dch`
   - 而 `ouyang_ye` / `ye_li` 的 `.dch` 在 `res://dialogs/`
   - 立绘（图片）和角色定义（dch）混在同一目录，违背"按资产类型分目录"原则
   - **建议**：所有 `.dch` / `.dtl` / `style.tres` 集中到 `dialogs/`，立绘留在 `assets/images/standing/`

### 🟡 中优先级（耦合 / 可读性）

6. **`Room.change_scene` 与 `Prop._physics_process` 双重消费"互动"键**
   - [room_template.gd:15](scenes/gameplay/room/room_template.gd) 在 `_physics_process` 检测 `Input.is_action_pressed("互动")` 切场景
   - [prop_template.gd:26](scenes/props/prop_template.gd) 同样在 `_physics_process` 监听同一动作触发互动
   - 当玩家在门口同时是 Door（Prop）+ Door 触发器（Room.can_change_scene），按 E 会被双系统同时响应
   - 切场景时副作用 `Chapter.san -= 10` 硬编码，违背单一职责

7. **`ChapterManager` 在每帧轮询 debug 输入 + hard-code 节点路径**
   - [ChapterManager.gd:27-33](scripts/ChapterManager.gd) 在 `_physics_process` 检测 `chapter_debug_next_chapter`，每按一次就 instantiate 一个 password_lock 并查找 `Gameplay/UILayer`
   - 单例耦合到具体场景树路径（`get_tree().get_root().get_node("Gameplay").get_node("UILayer")`），调试快捷键也不应在生产单例里
   - **建议**：抽到 `ggt-debug-shortcuts` 风格的独立 debug autoload，或仅在 `OS.has_feature("debug")` 时启用

8. **章节场景中两份 cutscene_director 演化重叠**
   - `chapter0_cutscene_director.gd`（旧）：`set_physics_process(false)` + `await timer`，简陋
   - `chapter0_classroom_cutscene_director.gd`（新）：tween + node 查找 + `_clamp_camera_center`，结构良好
   - 旧版仍被 `chapter0.tscn` 引用，并行存在易误用
   - **建议**：以新版为模板抽出 `cutscene_director_base.gd` 基类，旧版迁移或删除

9. **`scripts/` 平铺，单例职责模糊**
   - 所有 7 个 autoload 全部平摊在 `scripts/` 下，无子目录，未来扩到 15+ 个会失控
   - `ItemData.gd` 名为 Data 实为静态工具（`static var content`），与"Manager"语义不同
   - **建议**：分子目录 `scripts/managers/` / `scripts/data/` / `scripts/events/`；或按 Godot 习惯命名 `globals/`、`autoload/`

10. **资源目录二义性**
    - `assets/tilesets/`（存 .tres TileSet）vs `assets/images/tilesets/`（存源 png）—— 命名重复，import 关系不直观
    - `dialogs/style.tres` 与 `resources/theme/theme-main.tres` 同为样式资源，分散在两处
    - `default_bus_layout.tres` 留在根目录而不是 `resources/audio/`
    - **建议**：约定 `assets/` 只放原始资产（png/wav/ttf），`resources/` 放 .tres/.tscn 派生资源；`tilesets/` 子分类用 `_atlas` / `_tres` 后缀消歧

### 🟢 低优先级（命名 / 文档）

11. **占位符命名遗留**
    - `assets/images/sprites/baka/`（"傻瓜"，明显是占位符）
    - `chara_0.png` ~ `chara_99.png` 命名无语义（推测是 SAN 值阶段的角色头像）
    - dialogic variables 里 `chapter0.test_str = "baka"`

12. **`readme.md` 接近空白**
    - 仅 3 行，"待补充" — 缺少新人 onboarding 说明、目录索引、调试快捷键速查
    - `docs/` 仅有 1 篇接口文档，按 [CLAUDE.md/CCG 工作流] 应有模块级 README/DESIGN

13. **`.doc/` 被 gitignore 但属团队资产**
    - 策划案 PDF / xmind / xlsx 仅存在于本地，新成员拉仓库后看不到
    - **建议**：要么改用 git-lfs 入库，要么在 README 标注获取入口

14. **`Inventory` 持久化 key 风险**
    - [inventory.gd:7](scenes/ui/inventory/inventory.gd) 调用 `add_to_group("Persist")`，存档 key = `node.name`（默认 `GridContainer` 或 `Inventory`）
    - 节点在 ui_layer 子树里，重命名/重构 ui 树会立即丢失旧存档
    - **建议**：要么把 `Inventory` 改为 autoload，要么显式在脚本里给 `name = "Inventory"` 兜底

15. **未使用的参数 / 注释代码**
    - `room_template.gd._physics_process(delta)` 的 `delta` 未用
    - `item_template.gd` 顶部 `_ready()` 整段注释未删
    - `menu.gd` 末尾 `_start_breathing_animation` 整段注释未删

## 五、改进建议（按 ROI 排序）

| # | 行动 | 收益 | 成本 |
|---|---|---|---|
| 1 | 同步 `docs/接口文档` 与代码（信号名、加载时序）或反过来对齐 | 防止后续 bug | 低 |
| 2 | 删除 EventBus 三个 `storage_*` 死信号 | 减少认知负担 | 低 |
| 3 | 把 `chapter_debug_next_chapter` 从 `ChapterManager._physics_process` 移到 debug autoload | 解耦核心单例 | 低 |
| 4 | 立绘与 dch 分离（dch 全部移入 `dialogs/`） | 资源职责清晰 | 中（需改 project.godot） |
| 5 | 清理 `assets/images/backgrounds/旧资产/`、`参考.png`、孤儿 import、`.tmp` 文件 | 减小仓库 + 视觉噪音 | 低 |
| 6 | 抽 `cutscene_director_base.gd`，统一新旧两份 director | 后续章节复用 | 中 |
| 7 | 给 `Persist` 组节点显式 `name=` 或迁移成 autoload | 防存档兼容性灾难 | 中 |
| 8 | 完善 `readme.md` + 在 `docs/` 加 ARCHITECTURE.md 索引 | 新人上手速度 | 中 |
| 9 | 拆分 `scripts/` 子目录（managers/data/events） | 长期可维护 | 中 |
| 10 | 重命名占位符资产（baka → 正式角色名）、整理 `chara_*.png` 命名 | 美术资产可读 | 中 |

## 六、推荐目标结构（参考）

```text
godot-shards-of-me/
├── scripts/
│   ├── globals/           # autoload：EventBus / GameManager
│   ├── managers/          # Data / Chapter / Audio / Clue
│   ├── data/              # ItemData（静态工具）
│   └── debug/             # debug 快捷键、cheat 单例
├── scenes/
│   ├── menu/
│   ├── gameplay/{player,npc,room,chapters/}
│   ├── props/
│   └── ui/{hud,pause,inventory,clue_book,password_lock,...}
├── resources/
│   ├── audio/default_bus_layout.tres
│   ├── theme/theme-main.tres
│   ├── tilesets/*.tres
│   ├── chapters.json
│   └── items.json
├── dialogs/                # 仅 .dch / .dtl / style.tres
├── assets/
│   ├── audios/
│   ├── fonts/
│   └── images/{backgrounds,sprites,standing,items,ui,tilesets_src}
├── tests/                  # testfield.tscn 等纯测试场景
└── docs/
    ├── ARCHITECTURE.md
    ├── ONBOARDING.md
    └── 接口文档-DataManager与ChapterManager.md
```

---

_浮浮酱小结_：项目骨架（autoload + EventBus + Persist 协议 + Room/Prop 基类）设计思路是清晰的喵～ 主要痛点集中在 **命名一致性、文档与代码漂移、临时资产堆积、单例职责泄漏** 四块。优先把第一档 5 个高优先问题解决掉，整个工程的可维护性会上一个台阶 (๑•̀ㅂ•́)✧
