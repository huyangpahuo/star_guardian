# Star Guardian 模块说明书

本文档介绍游戏的模块划分、各模块职责，以及做常见改动时应该动哪里。

## 一、项目结构总览

```
star_guardian/
├── main.lua               # LÖVE 入口：把引擎回调转发给 src/core/app.lua
├── conf.lua               # 窗口/引擎配置（LÖVE 启动前读取）
├── src/
│   ├── core/              # 框架层：与应用无关的通用系统
│   │   ├── app.lua        #   组合根：创建所有服务、接线、全局热键
│   │   ├── router.lua     #   场景路由（栈式：gotoScene / push / pop）
│   │   ├── session.lua    #   单局进度（分数/等级/回合）
│   │   ├── input.lua      #   输入归一化（键盘/鼠标/多点触控）
│   │   ├── audio.lua      #   程序化音效与音乐（纯代码合成，无音频文件）
│   │   ├── assets.lua     #   字体懒加载与缓存（含 CJK 回退链）
│   │   ├── i18n.lua       #   多语言查找（en / zh_CN / ja）
│   │   ├── save.lua       #   存档：设置 + 生涯统计 + 成就解锁
│   │   ├── theme.lua      #   配色 + 屏幕自适应布局度量
│   │   ├── widgets.lua    #   即时模式 UI 控件（绘制与命中同源）
│   │   ├── utils.lua      #   数学/几何/表工具（纯函数）
│   │   ├── json.lua       #   JSON 编解码（仅 MCP 桥使用）
│   │   ├── mcp_bridge.lua #   可选 TCP 桥（MCP_PORT 环境变量开启）
│   │   └── smoke.lua      #   冒烟测试驱动（SG_SMOKE 环境变量开启）
│   ├── game/              # 玩法层：游戏规则与实体
│   │   ├── world.lua      #   世界编排：持有实体状态、生成、碰撞、难度
│   │   ├── ships.lua      #   战机目录（纯数据 + 选择状态）
│   │   ├── rounds.lua     #   回合（波次）配置与推进判定
│   │   ├── achievements.lua # 成就定义、计数器、解锁弹窗
│   │   ├── runflow.lua    #   开局/死亡的生命周期（结算入档）
│   │   └── entities/      #   实体库（无状态函数库，操作数组）
│   │       ├── player.lua   #   玩家战机实体 + 通用战机渲染器
│   │       ├── bullets.lua  #   子弹（按战机技能生成弹型）
│   │       ├── enemies.lua  #   敌机（侦察/战机/重甲/疾行）
│   │       ├── powerups.lua #   道具（回血/加速/速射）
│   │       ├── particles.lua#   粒子爆炸
│   │       └── stars.lua    #   星空背景
│   └── scenes/            # 场景层：每个界面一个文件
│       ├── menu.lua             # 主菜单（左按钮/右介绍布局）
│       ├── ship_select.lua      # 选择战机（独立界面）
│       ├── settings.lua         # 设置（音量滑条，独立界面）
│       ├── language.lua         # 语言选择（独立界面）
│       ├── playing.lua          # 对局（推进世界、消费事件、HUD）
│       ├── paused.lua           # 暂停（覆盖层）
│       ├── round_transition.lua # 过关结算（覆盖层）
│       ├── gameover.lua         # 游戏结束
│       ├── exit_prompt.lua      # 退出确认（覆盖层，仅局内 ESC 呼出）
│       └── debug.lua            # 调试面板（F1 覆盖层）
├── localization/          # 语言包（en.lua / zh_CN.lua / ja.lua）
└── resources/             # 字体与 CRT 着色器
```

## 二、入口与配置

### main.lua
唯一的 LÖVE 回调入口，本身不含游戏逻辑：

- `love.load` → `app.init()`：创建全部服务并进入主菜单
- `love.update` / `love.draw`：带 xpcall 包装转发给 app（任何 Lua 错误都会落到存档目录的 `error_log.txt`，冒烟模式则直接退出）
- 鼠标与触摸统一转换成 pointer 事件（`app.pointerpressed/moved/released`）；触摸额外喂给虚拟按钮
- `love.resize` → 尺寸更新后调用 `app.redrawNow()`，**拖拽窗口边缘时界面实时缩放**（LÖVE 默认在拖拽期间不刷新窗口，只拉伸旧帧）
- `love.errorhandler`：错误兜底记录 + 冒烟模式自动退出

### conf.lua
`identity`（存档目录名）、窗口（900×650 起，最小 640×480，可缩放）、vsync、highdpi、禁用未用模块。设了 `SG_SMOKE` 环境变量时：存档切到独立目录 `star_guardian_smoke`、窗口放到屏幕外（不干扰桌面）。

## 三、core 层（框架层）

| 模块 | 职责 | 关键点 |
|------|------|--------|
| `app.lua` | 组合根 | 创建 ctx（所有服务挂在这上面，场景随处可见的 `ctx.xxx`）；全局热键 F1（调试）/F11（全屏，**延迟到下一帧执行**，避免在事件泵内切换窗口模式导致 Windows 死锁）；应用 IME 关闭（修复中文输入法吞字母键）；画布惰性重建+立即释放（修复 resize 显存堆积） |
| `router.lua` | 场景路由 | 栈式管理：`gotoScene`（整栈替换，硬切换）、`push`/`pop`（覆盖层）。绘制自底向上遍历整栈（覆盖层画在父界面之上）；**update 与输入事件只发给栈顶**（覆盖层打开时游戏自动冻结） |
| `session.lua` | 单局状态 | score / level / roundNum / kills / damageTaken。等级 = 分数/500 + 1 |
| `input.lua` | 输入归一化 | 每帧轮询合成 `actions`（A/D 与 ←/→ 等价、空格与鼠标左键等价）；多点触控映射虚拟按钮（每根手指独立）；`pauseRequested` 边沿触发供触屏暂停 |
| `audio.lua` | 程序化音频 | 全部音效/音乐由数学函数合成（`makeSoundData`）。一次性音源播放完立即 `release()`，并发硬上限 24（防长时游玩资源堆积）。音量三层：master / sfx / music |
| `assets.lua` | 字体 | 按（字号×语言）**懒加载**并缓存，CJK 有完整回退链；语言切换时 `setLanguage` 指向对应字体。曾因启动预载 36 个字体实例占 400MB+，现按需加载 |
| `i18n.lua` | 多语言 | `t(key)` 查找，缺失回退英语；`onLangChange` 通知字体层切换 |
| `save.lua` | 存档 | 可读的 Lua 脚本 `savegame.lua`，缺省值深度合并（旧档/坏档安全回退）。`recordRun` 在每局死亡时累加生涯统计并更新最高分 |
| `theme.lua` | 主题 | 配色常量 + `metrics(w,h)`：所有界面坐标由它推导，禁止写死像素 |
| `widgets.lua` | UI 控件 | 即时模式：`button/slider/statBar/backdrop/centerText`。**绘制的同时把命中区登记进本帧 layout 表**，点击判定 `hitTest` 用同一张表——控件点哪里永远和看到的一致 |
| `mcp_bridge.lua` | 调试桥 | 仅当设置 `MCP_PORT` 时启用；端口被占用等情况只降级不崩溃。支持 ping / list_objects / get_object / get_state / run_lua |
| `smoke.lua` | 冒烟测试 | `SG_SMOKE=1`：自动走一遍所有界面并模拟真实点击，写 `smoke_result.txt`；`=2`：惰性心跳模式 |

## 四、game 层（玩法层）

- **`world.lua` 世界编排**：唯一持有实体状态的地方。`update(dt, session, actions)` 推进一切并**返回事件列表**（shoot / hit / kill / powerup / player_hit / died），对局场景据此播音效、加分、查成就——模拟与表现完全解耦。难度 = 1 + 分数/1000，同时影响生成频率与敌机速度。
- **`ships.lua` 战机目录**：4 款战机纯数据（血量/速度/射速/伤害/弹速/技能）。技能：none / double（双发）/ heavy（重击）/ penetrate（穿透 3 个）。
- **`rounds.lua` 回合配置**：6 个回合的目标分数、敌机权重（有序数组保证随机确定）、生成间隔、速度倍率。第 6 回合 targetScore 为 math.huge（无尽）。
- **`achievements.lua` 成就**：8 个成就，`check(data)` 喂入本局事件，返回本帧新解锁列表；解锁状态持久化到存档。
- **`runflow.lua` 生命周期**：`start`（重置会话/世界/成就并进入对局）、`finish`（结算入档、爆炸、进 gameover）。主菜单"开始游戏"与 gameover"再来一局"共用。
- **`entities/*` 实体库**：全部是操作普通 table 数组的无状态函数（spawn/update/draw）。碰撞判定（AABB）统一用 `utils.checkCollision`，在 world 中完成。`entities/player.lua` 的 `draw` 同时服务游戏内实体与菜单预览（`preview` 造一次性实体，**不污染真实世界状态**——旧版菜单预览会临时改写玩家实体，属于已修复的历史问题）。

## 五、scenes 层（场景层）

每个场景是一个普通 table，按需实现：`enter` / `update` / `draw` / `keypressed` / `pointerpressed` / `pointerreleased` / `pointermoved` / `exit`。第一个参数都是 ctx。

| 场景 | 类型 | 说明 |
|------|------|------|
| `menu` | 基础 | 左侧按钮列（开始/选机/设置/语言/退出），右侧战机预览 + 翻译过的游戏介绍 + 作者署名。主界面 ESC 不弹任何确认 |
| `ship_select` | 独立界面 | ←/→ 或 A/D 浏览，属性条对比，确认即存档 |
| `settings` | 独立界面 | 三条音量滑条实时生效，关闭时统一写档（拖动中不写盘） |
| `language` | 独立界面 | 三语切换，选中即存档并同步字体 |
| `playing` | 基础 | 消费 world 事件：音效/加分/成就/回合推进；死亡走 `runflow.finish`；触屏虚拟按钮在此绘制 |
| `paused` | 覆盖层 | 继续 / 返回主菜单 |
| `round_transition` | 覆盖层 | 过关结算；期间星空/粒子继续飘（`world.updateAmbient`） |
| `gameover` | 基础 | 最终得分、新纪录、再来一局/回菜单 |
| `exit_prompt` | 覆盖层 | "返回主菜单"确认——只从局内 ESC 呼出，"否"原路返回（不打断暂停状态） |
| `debug` | 覆盖层 | F1 呼出：生涯统计、输入状态、音量/全屏/语言快捷键 |

**独立界面 vs 覆盖层**：选机/设置/语言用 `gotoScene`（整栈替换，返回即回主菜单）；暂停/过关/退出确认用 `push`（叠在上层，"否/继续"pop 后原样恢复）。

## 六、本地化与资源

- 语言包：`localization/en.lua`、`zh_CN.lua`、`ja.lua`——纯 key/value 表。**加界面文案时三个文件都要加同名字段**；作者名"胡杨怕火"按需求保持原文不翻译。
- 字体：`resources/fonts/` 下的 Noto/GoNoto 系列，`assets.loadFont` 里有跨平台回退链（Windows/macOS/Linux/Android 系统字体）。
- 着色器：`resources/shaders/post.glsl`，CRT 扫描线+暗角后处理，加载失败自动跳过（无着色器也能玩）。

## 七、冒烟测试

```bash
# Windows (Git Bash)
SG_SMOKE=1 /d/Love2D/LOVE/love.exe . 
```

流程：自动开关每个界面 → 模拟真实点击（按钮/滑条拖动/语言切换）→ 脚本化对局（移动+射击）→ 暂停/继续 → 过关 → 退出确认 → 死亡结算 → 重开 → 回菜单，最后写 `smoke_result.txt`（内容 `SMOKE_OK ...`）并自动退出。过程里程碑落盘在 `smoke_progress.txt`，Lua 层错误落盘 `smoke_error.txt` / `error_log.txt`（均在 `%APPDATA%/LOVE/star_guardian_smoke/`）。退出码 0 且有 SMOKE_OK 即通过。

## 八、常见改动指南

| 想做什么 | 改哪里 |
|----------|--------|
| 加/改界面文案 | 三个 `localization/*.lua` 加同名字段；场景里 `ctx.i18n.t("key")` |
| 加新场景 | `src/scenes/` 新文件 → `app.lua` 的 `buildScenes` 注册 → `router:gotoScene("名字")` |
| 加新敌机 | `entities/enemies.lua` 的 `TYPES` 加条目 + `draw` 加分支 → `rounds.lua` 回合权重里引用 |
| 加新成就 | `achievements.lua` 的 `DEFS` 加一条（id + 文案 key + check 函数），语言包加文案 |
| 加新道具 | `entities/powerups.lua` 的 `TYPES` + `apply` + `draw` |
| 调难度曲线 | `rounds.lua` 配置表；全局难度公式在 `world.update` |
| 加新战机 | `ships.lua` 的 `types` + `order`，语言包加 nameKey/skillKey |
| 调整视觉风格 | `core/theme.lua`（配色与布局度量）+ `resources/shaders/post.glsl` |

## 九、架构约定（改代码前必读）

1. **场景不引用彼此**，一切通过 ctx 里的服务与 `router` 跳转。
2. **坐标不许写死**：一律从 `theme.metrics(w,h)` 推导；文字排版用限宽 `printf` 防溢出。
3. **控件绘制即注册命中**：点击判定必须走 `widgets`，不要手写坐标矩形（历史上双份维护导致过点击区漂移 bug）。
4. **资源生命周期**：Canvas / 音源这类大对象不用等 GC——重建时对旧的显式 `release()`；音源受并发上限保护。
5. **窗口模式切换（全屏）只能发生在 `app.update` 里**，绝不在事件回调中直接调 `love.window.setFullscreen`（Windows 事件泵内切模式会死锁整机）。
6. **世界模拟通过事件对外通信**，playing 场景负责把事件翻译成表现层副作用（音效/成就/存档）。
