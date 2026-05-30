# 光板谜题关卡编辑与新建指南

这份文档只覆盖当前工程里已经接好的光路滑块谜题系统。现在的谜题关卡不是写在房间脚本里，而是存成 `LightPuzzleData` 资源：

```text
resources/puzzles/light_board/*.tres
```

编辑谜题时，优先改这些 `.tres` 资源。只有当你要改 UI、拖拽规则、光线求解规则、或者世界里的交互物件时，才需要改脚本或场景。

## 当前文件分工

| 你想做什么 | 改哪里 |
| --- | --- |
| 修改已有谜题的布局、光源、出口、棋子 | `resources/puzzles/light_board/*.tres` |
| 新建一个谜题关卡 | 新建或复制一个 `LightPuzzleData` `.tres` |
| 单独运行谜题进行测试 | 复制 `scenes/gameplay/puzzles/puzzle_01.tscn` 这类测试场景 |
| 把谜题放进房间里让玩家按交互键打开 | 在房间场景里实例化 `scenes/gameplay/puzzles/light_board/light_puzzle_prop.tscn` |
| 改谜题弹窗 UI | `scenes/gameplay/puzzles/light_board/light_puzzle_board.tscn` 和 `light_puzzle_board.gd` |
| 改棋盘绘制、光线、光源、出口显示 | `scenes/gameplay/puzzles/light_board/light_board_surface.gd` |
| 改棋子显示和拖拽输入 | `scenes/gameplay/puzzles/light_board/light_piece_view.gd` |
| 改光线求解规则 | `scripts/puzzles/light_board/LightBeamSolver.gd` |
| 解谜后触发剧情、开门、给道具 | 监听 `EventBus.puzzle_light_solved(puzzle_id)` |

当前已有 3 个谜题资源：

| 资源 | 测试场景 | 谜题 ID |
| --- | --- | --- |
| `resources/puzzles/light_board/red_foldback.tres` | `scenes/gameplay/puzzles/puzzle_01.tscn` | `red_foldback` |
| `resources/puzzles/light_board/blue_prism_z.tres` | `scenes/gameplay/puzzles/puzzle_02.tscn` | `blue_prism_z` |
| `resources/puzzles/light_board/green_dual_filter_chain.tres` | `scenes/gameplay/puzzles/puzzle_03.tscn` | `green_dual_filter_chain` |

## 运行时结构

光板谜题由三层组成：

1. `LightPuzzleData` 资源保存关卡数据。
2. `LightPuzzleBoard` 弹出棋盘 UI，读取 `LightPuzzleData`，生成可拖拽棋子，并实时调用求解器。
3. `LightPuzzleProp` 是房间里的可交互物件。玩家靠近后按交互键，它会实例化并打开 `LightPuzzleBoard`。

相关脚本：

```text
scripts/puzzles/light_board/LightPuzzleConstants.gd
scripts/puzzles/light_board/LightPieceData.gd
scripts/puzzles/light_board/LightPiecePlacement.gd
scripts/puzzles/light_board/LightPortData.gd
scripts/puzzles/light_board/LightPuzzleData.gd
scripts/puzzles/light_board/LightBeamSolver.gd
scenes/gameplay/puzzles/light_board/light_puzzle_board.gd
scenes/gameplay/puzzles/light_board/light_board_surface.gd
scenes/gameplay/puzzles/light_board/light_piece_view.gd
scenes/gameplay/puzzles/light_board/light_puzzle_prop.gd
```

完成谜题时会发出两个信号：

```gdscript
LightPuzzleBoard.puzzle_solved(puzzle_id)
EventBus.puzzle_light_solved(puzzle_id)
```

跨房间、剧情、门、道具等系统建议监听 `EventBus.puzzle_light_solved`。

## 坐标规则

棋盘坐标使用 `Vector2i(x, y)`，从左上角开始，`x` 向右增加，`y` 向下增加。默认棋盘是 5x5：

```text
x: 0 1 2 3 4
y
0  . . . . .
1  . . . . .
2  . . . . .
3  . . . . .
4  . . . . .
```

`board_size = Vector2i(5, 5)` 时，合法格子是 `x = 0..4`、`y = 0..4`。

光源和出口也放在格子上：

| 位置 | 设置方式 |
| --- | --- |
| 左边缘射入第 1 行 | `cell = Vector2i(0, 1)`，`direction = E` |
| 右边缘射出第 2 行 | `cell = Vector2i(4, 2)`，`direction = E` |
| 上边缘射出第 4 列 | `cell = Vector2i(4, 0)`，`direction = N` |
| 下边缘射出第 4 列 | `cell = Vector2i(4, 4)`，`direction = S` |
| 左上角斜向射入 | `cell = Vector2i(0, 0)`，`direction = SE` |
| 右下角斜向射出 | `cell = Vector2i(4, 4)`，`direction = SE` |

出口的判断发生在光线即将离开棋盘时。也就是说，出口的 `cell` 是光线离开棋盘前所在的最后一个格子，`direction` 是离开棋盘的方向。

## 方向规则

方向来自 `LightPuzzleConstants.Direction`：

| Inspector 显示 | 向量 | 说明 |
| --- | --- | --- |
| `E` | `(1, 0)` | 向右 |
| `SE` | `(1, 1)` | 右下 |
| `S` | `(0, 1)` | 向下 |
| `SW` | `(-1, 1)` | 左下 |
| `W` | `(-1, 0)` | 向左 |
| `NW` | `(-1, -1)` | 左上 |
| `N` | `(0, -1)` | 向上 |
| `NE` | `(1, -1)` | 右上 |

棱镜旋转是离散 45 度：

```text
+45: E -> SE -> S -> SW -> W -> NW -> N -> NE -> E
-45: E -> NE -> N -> NW -> W -> SW -> S -> SE -> E
```

## 颜色规则

颜色是 RGB 位掩码：

| 颜色 | 值 | 说明 |
| --- | --- | --- |
| Red | `1` | 红 |
| Green | `2` | 绿 |
| Blue | `4` | 蓝 |
| Yellow | `3` | 红 + 绿 |
| Cyan | `6` | 绿 + 蓝 |
| Magenta | `5` | 红 + 蓝 |
| White | `7` | 红 + 绿 + 蓝 |

在 Godot Inspector 里，颜色字段会显示成 `Red`、`Green`、`Blue` 三个勾选项。白光就是三个都勾选。

出口的 `requires_exact_color` 很重要：

| 值 | 行为 |
| --- | --- |
| `true` | 光线颜色必须和 `color_mask` 完全相同 |
| `false` | 光线只要包含 `color_mask` 要求的颜色即可 |

例子：出口要求红色。

- `requires_exact_color = true` 时，只有红光能通过，白光不算。
- `requires_exact_color = false` 时，红光、黄光、品红光、白光都能通过，因为它们都包含红色通道。

## 棋子规则

棋子类型来自 `LightPieceData.piece_type`：

| 类型 | 行为 |
| --- | --- |
| `Mirror Slash` | `/` 镜面反射 |
| `Mirror Backslash` | `\` 镜面反射 |
| `Prism +45` | 光线方向顺时针转 45 度 |
| `Prism -45` | 光线方向逆时针转 45 度 |
| `Filter Red` | 只保留红色通道 |
| `Filter Green` | 只保留绿色通道 |
| `Filter Blue` | 只保留蓝色通道 |
| `Filter Yellow` | 只保留红 + 绿 |
| `Filter Cyan` | 只保留绿 + 蓝 |
| `Filter Magenta` | 只保留红 + 蓝 |
| `Glass Block` | 占格，阻挡棋子移动，但光线穿过 |
| `Opaque Block` | 占格，阻挡棋子移动，并吸收光线 |

光线进入一个格子后，会先和这个格子里的棋子交互，再向下一个格子移动。也就是说，如果光源格子上有棋子，光线一开始就会受到这个棋子的影响。

## `LightPuzzleData` 字段

打开任意 `resources/puzzles/light_board/*.tres`，Inspector 里会看到这些字段：

| 字段 | 作用 |
| --- | --- |
| `puzzle_id` | 谜题唯一 ID。解谜事件会把这个字符串发出去 |
| `title` | 弹窗顶部显示的标题 |
| `board_size` | 棋盘尺寸，例如 `Vector2i(5, 5)` |
| `sources` | 光源数组，每个元素是 `LightPortData` |
| `exits` | 出口数组，每个元素是 `LightPortData` |
| `placements` | 棋子数组，每个元素是 `LightPiecePlacement` |
| `max_beam_steps` | 光线最大追踪步数，用来防止无限循环 |
| `solved_event_name` | 当前代码还没有使用这个字段 |
| `designer_notes` | 给关卡设计者看的备注 |

当前解谜条件不是看棋子是否放到 `solution_position`，而是看所有出口是否都被正确颜色、正确方向的光线击中。`solution_position` 只是设计备注字段，当前求解器没有使用它。

## `LightPortData` 字段

`sources` 和 `exits` 里的每个元素都是 `LightPortData`：

| 字段 | 作用 |
| --- | --- |
| `port_id` | 端口 ID。建议唯一，例如 `source_left_y1`、`exit_bottom_x4` |
| `kind` | `Source` 或 `Exit` |
| `cell` | 所在格子 |
| `direction` | 光源发射方向，或出口要求的离开方向 |
| `color_mask` | 光源颜色，或出口要求颜色 |
| `requires_exact_color` | 出口是否要求颜色完全一致 |

光源一般设置 `kind = Source`。出口一般设置 `kind = Exit`。

## `LightPiecePlacement` 字段

`placements` 里的每个元素都是一个棋子摆放：

| 字段 | 作用 |
| --- | --- |
| `placement_id` | 摆放 ID。建议唯一 |
| `piece` | 这个摆放使用的 `LightPieceData` |
| `grid_position` | 初始左上角格子 |
| `locked` | 这个摆放是否锁定 |
| `allowed_cells` | 允许移动到的左上角格子。空数组表示不额外限制 |
| `solution_position` | 设计备注。当前不参与判定 |

`allowed_cells` 限制的是棋子的左上角锚点，不是棋子覆盖的每一个格子。如果以后做 2x1 或 2x2 棋子，要按左上角来填。

## `LightPieceData` 字段

每个摆放里的 `piece` 是 `LightPieceData`：

| 字段 | 作用 |
| --- | --- |
| `piece_id` | 棋子 ID。建议唯一 |
| `display_name` | 显示名，当前主要给设计者看 |
| `piece_type` | 棋子的光学类型 |
| `size` | 棋子尺寸，当前已有资源都是 `Vector2i(1, 1)` |
| `move_axis` | 移动限制：`Both`、`Horizontal`、`Vertical`、`Locked` |
| `is_draggable` | 是否可以拖动 |
| `filter_mask` | 自定义滤镜颜色。内置颜色滤镜通常会被 `piece_type` 覆盖 |
| `asset_key` | 当前显示代码还没有使用这个字段 |

棋子能不能移动由三个条件共同决定：

```text
piece.is_draggable == true
placement.locked == false
piece.move_axis != Locked
```

如果你想做固定障碍，推荐：

```text
piece_type = Glass Block 或 Opaque Block
is_draggable = false
move_axis = Locked
placement.locked = true
```

## 修改已有谜题

用 Godot 编辑器修改最稳：

1. 打开 `resources/puzzles/light_board/`。
2. 双击要修改的 `.tres`，例如 `red_foldback.tres`。
3. 在 Inspector 里修改 `title`、`board_size`、`sources`、`exits`、`placements`。
4. 修改完保存资源。
5. 打开对应测试场景，例如 `scenes/gameplay/puzzles/puzzle_01.tscn`。
6. 运行当前场景，检查谜题是否能解、重置是否正常、关闭是否正常。

添加光源或出口：

1. 展开 `sources` 或 `exits` 数组。
2. 增加数组 Size。
3. 给新元素创建 `LightPortData`。
4. 设置 `port_id`、`kind`、`cell`、`direction`、`color_mask`。
5. 出口记得设置 `requires_exact_color`。

添加棋子：

1. 展开 `placements` 数组。
2. 增加数组 Size。
3. 给新元素创建 `LightPiecePlacement`。
4. 在 `piece` 字段里创建或复制一个 `LightPieceData`。
5. 设置棋子的 `piece_type`、`size`、`move_axis`、`is_draggable`。
6. 设置摆放的 `grid_position`、`locked`、`allowed_cells`。
7. 如果只是给自己记答案，可以填 `solution_position`，但不要依赖它触发完成。

删除棋子时，只从 `placements` 数组里移除对应摆放即可。若多个摆放共用同一个 `LightPieceData` 子资源，删除一个摆放不会自动删除其他摆放。

## 新建谜题资源

推荐做法是从 Godot 编辑器中新建资源：

1. 在 FileSystem 面板进入 `resources/puzzles/light_board/`。
2. 右键选择 **New Resource...**。
3. 类型选择 `LightPuzzleData`。
4. 保存为小写下划线文件名，例如 `white_corner_route.tres`。
5. 设置 `puzzle_id`，建议和文件名一致，例如 `white_corner_route`。
6. 设置 `title`。
7. 设置 `board_size`，先用 `Vector2i(5, 5)` 最省心。
8. 添加至少一个 `Source`。
9. 添加至少一个 `Exit`。
10. 添加棋子和障碍。
11. 保存资源。

也可以复制已有资源再改，但最好在 Godot 编辑器里复制，不要直接在系统文件管理器里复制 `.tres`。直接复制可能带来重复 UID 或旧资源引用问题。

## 设计一个新谜题

建议按这个顺序设计：

1. 先画答案路径。

   从光源格子开始，按方向一步步走，确定光线需要在哪些格子转向、过滤、穿过障碍、离开棋盘。

2. 放出口。

   出口必须放在光线离开棋盘前的最后一个格子上，方向必须和离开方向一致。

3. 放关键光学棋子。

   先只放答案路径上必须用到的镜子、棱镜、滤镜。

4. 放固定障碍。

   用 `Glass Block` 限制移动空间，但不影响光线。用 `Opaque Block` 同时阻挡移动和吸收光线。

5. 决定初始布局。

   把关键棋子从答案位置挪开，形成需要玩家移动的状态。

6. 限制移动。

   用 `move_axis` 控制棋子只能横向或纵向移动。用 `allowed_cells` 做更强的路径限制。

7. 测试是否可解。

   运行测试场景，手动拖到答案。只要出口全部命中，状态会显示 `Solved`。

8. 测试是否误解。

   拖动几个非答案布局，确认不会意外 `Solved`。如果太容易误解，用障碍、颜色要求、方向要求或 `allowed_cells` 收紧。

## 新建独立测试场景

独立测试场景适合只测谜题，不进入完整游戏流程。

1. 复制 `scenes/gameplay/puzzles/puzzle_01.tscn`。
2. 命名为 `puzzle_04.tscn` 或和谜题 ID 对应的名字。
3. 打开新场景。
4. 选中根节点，也就是 `LightPuzzleBoard` 实例。
5. 把 `puzzle_data` 改成新建的 `.tres`。
6. 保持 `open_on_ready = true`。
7. 保持 `pause_world_while_open = false`。
8. 运行当前场景。

这类测试场景本质上只是直接实例化 `light_puzzle_board.tscn`，并在 `_ready()` 时自动打开。

## 把谜题放进房间

要让玩家在房间里靠近物件并按交互键打开谜题：

1. 打开目标房间或章节场景。
2. 实例化 `scenes/gameplay/puzzles/light_board/light_puzzle_prop.tscn`。
3. 把它放到房间里合适的位置。
4. 在 Inspector 里给 `puzzle_data` 指定你的 `.tres`。
5. 按需要设置 `disable_after_solved`。
6. 运行房间场景，靠近物件后按交互键测试。

`LightPuzzleProp` 会在玩家交互时：

1. 检查自己有没有 `puzzle_data`。
2. 实例化 `light_puzzle_board.tscn`。
3. 把棋盘加到 `get_tree().current_scene`。
4. 打开谜题。
5. 解谜后把自己标记为已解。
6. 如果 `disable_after_solved = true`，之后不再允许交互，并隐藏提示。

当前工程的交互动作在 Project Settings 的 Input Map 里绑定到 `E` 键。脚本里动作名显示成乱码，是编码显示问题；在编辑器里以现有交互动作名为准。

## 解谜后触发剧情或机关

全局信号定义在 `scripts/EventBus.gd`：

```gdscript
signal puzzle_light_solved(puzzle_id: String)
```

在需要响应谜题完成的脚本中监听：

```gdscript
func _ready() -> void:
	EventBus.puzzle_light_solved.connect(_on_puzzle_light_solved)


func _on_puzzle_light_solved(puzzle_id: String) -> void:
	if puzzle_id != "red_foldback":
		return

	# 在这里开门、播放剧情、给线索、切章节等。
```

注意：

- 用 `puzzle_id` 区分不同谜题。
- `solved_event_name` 当前没有被代码读取。
- `LightPuzzleBoard` 每次打开或重置都会把内部已发送标记清掉，所以单独测试场景里重置后再次解开可能再次发信号。
- 房间物件如果 `disable_after_solved = true`，第一次解开后就不会再打开。

## 棋盘 UI 设置

`light_puzzle_board.tscn` 的根节点 `LightPuzzleBoard` 有这些导出字段：

| 字段 | 作用 |
| --- | --- |
| `puzzle_data` | 要打开的谜题资源 |
| `cell_size` | 单格像素尺寸，默认 `88.0` |
| `pause_world_while_open` | 打开谜题时是否暂停世界 |
| `open_on_ready` | 场景 ready 时是否自动打开谜题 |

独立测试场景通常设置：

```text
pause_world_while_open = false
open_on_ready = true
```

房间交互物件打开的谜题通常由 `LightPuzzleProp` 调用 `open_puzzle()`，不需要 `open_on_ready`。

`BoardSurface` 上还有几个美术对齐字段：

| 字段 | 作用 |
| --- | --- |
| `board_panel_cell_px` | `board_panel.png` 原图中单格的像素尺度 |
| `board_panel_border_px` | `board_panel.png` 原图中边框宽度 |
| `port_icon_size` | 光源和出口图标尺寸 |

如果换了 `board_panel.png`，但格子和边框对不上，先调这两个 `board_panel_*` 字段。

## 美术资源位置

当前代码读取的图片目录是：

```text
assets/images/puzzle/
```

不是 `assets/images/puzzles/light_board/`。

棋子贴图由 `light_piece_view.gd` 根据 `piece_type` 直接映射到文件名。`asset_key` 当前没有参与贴图选择。

当前会读取的主要文件：

| 文件 | 用途 |
| --- | --- |
| `board_panel.png` | 棋盘底图 |
| `piece_mirror_slash.png` | `/` 镜子 |
| `piece_mirror_backslash.png` | `\` 镜子 |
| `piece_prism_plus_45.png` | +45 棱镜 |
| `piece_prism_minus_45.png` | -45 棱镜 |
| `piece_filter_red.png` | 红滤镜 |
| `piece_filter_green.png` | 绿滤镜 |
| `piece_filter_blue.png` | 蓝滤镜 |
| `piece_filter_yellow.png` | 黄滤镜 |
| `piece_glass_block.png` | 透明障碍 |
| `piece_opaque_block.png` | 不透明障碍 |
| `piece_hover_glow.png` | 选中高亮 |
| `light_source_white.png` | 白光源 |
| `exit_red.png` | 红出口 |
| `exit_green.png` | 绿出口 |
| `exit_blue.png` | 蓝出口 |
| `solved_flash.png` | 解开后的闪光覆盖层 |
| `world_prop_light_board_idle.png` | 房间里的未解谜题物件 |
| `world_prop_light_board_solved.png` | 房间里的已解谜题物件，目前场景还没有自动切换到它 |

当前 `Filter Cyan` 会复用蓝滤镜贴图，`Filter Magenta` 会复用红滤镜贴图。黄、青、品红出口也会回退到已有红/蓝出口贴图。如果你要做专用贴图，需要改 `light_piece_view.gd` 的 `_get_texture_for_piece()` 和 `light_board_surface.gd` 的 `_get_exit_texture()`。

## 检查清单

保存并测试前，逐项检查：

- `puzzle_id` 唯一，并且和你监听事件时使用的字符串一致。
- 至少有一个 `Source`。
- 至少有一个 `Exit`。没有出口时，求解器不会判定完成。
- 光源和出口的 `cell` 在棋盘范围内。
- 出口位于边缘格子，且 `direction` 指向棋盘外。
- 每个棋子的 `grid_position` 在棋盘范围内。
- 棋子 `grid_position + size` 没有超出棋盘。
- 初始棋子没有互相重叠。
- 固定障碍设置了 `locked = true`、`is_draggable = false` 或 `move_axis = Locked`。
- 如果设置了 `allowed_cells`，数组里包含棋子的初始位置和可解位置。
- `move_axis` 没有限制到无法移动到答案。
- 所有出口颜色和 `requires_exact_color` 符合设计。
- `max_beam_steps` 足够长。默认 `64` 对 5x5 棋盘通常足够。
- 独立测试场景可以打开、拖拽、重置、关闭。
- 解开后 `EventBus.puzzle_light_solved` 能被目标剧情或机关收到。

## 常见问题

### 明明棋子到了答案位置，却没有显示 Solved

当前系统不看 `solution_position`。只有光线以正确颜色、正确方向打中所有出口，才算完成。

检查：

- 出口 `cell` 是否是离开棋盘前的最后一格。
- 出口 `direction` 是否是离开棋盘方向。
- 出口颜色是否设置过严。
- 滤镜是否把颜色通道过滤掉了。
- 光线是否被 `Opaque Block` 吸收。

### 棋子拖不动

检查：

- `piece.is_draggable` 是否为 `true`。
- `placement.locked` 是否为 `false`。
- `piece.move_axis` 是否不是 `Locked`。
- `allowed_cells` 是否把目标格子排除了。
- 前方是否有其他棋子或障碍挡住。

### 光线直接穿过障碍

`Glass Block` 只阻挡棋子移动，不阻挡光线。要吸收光线，用 `Opaque Block`。

### 出口颜色看起来不对

当前只准备了红、绿、蓝出口贴图。黄、青、品红会回退到红或蓝贴图，但求解颜色仍然按 `color_mask` 判断。

### 新增贴图没有显示

当前棋子贴图不是通过 `asset_key` 找的，而是代码按 `piece_type` 映射。新增贴图后，需要改 `light_piece_view.gd`。
