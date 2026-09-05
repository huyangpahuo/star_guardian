# Star Guardian（星际守护者）

一款用 LÖVE (Love2D) + Lua 编写的复古太空射击游戏。波次制战斗、四款可切换战机、程序化合成音频（无音频文件）、三语界面（英/简中/日）、成就与生涯统计持久化。

![玩法](https://img.shields.io/badge/engine-L%C3%96VE_11.5-blue) ![平台](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-lightgrey)

## 玩法

- 击落来袭敌机获得分数，达成每回目标分数进入下一回（第 6 回起为无尽模式）
- 击杀有概率掉落道具：回血 / 加速 / 速射
- 分数同时驱动难度与等级；4 款战机各有速度/火力/血量与专属弹型技能
- 8 个成就（首杀、百杀、满分、无伤过回……），解锁状态跨局保存

## 操作

| 按键 | 功能 |
|------|------|
| A / D 或 ← / → | 左右移动 |
| 空格 或 鼠标左键 | 射击 |
| P | 暂停 |
| Esc | 局内呼出"返回主菜单"确认（主界面无效） |
| F1 | 调试面板 |
| F11 | 全屏切换 |

触屏设备（Android / iOS）自动显示虚拟按键，支持多指同时操作。

## 运行

安装 [LÖVE 11.5](https://love2d.org/) 后：

```bash
love /path/to/star_guardian
# Windows 示例
D:\Love2D\LOVE\love.exe D:\Starguardian\star_guardian
```

## 冒烟测试

自动遍历全部界面并模拟真实点击与一局脚本化对战：

```bash
SG_SMOKE=1 love .   # 窗口在屏幕外运行，退出码 0 且输出 SMOKE_OK 即通过
```

详见 [MODULES.md](MODULES.md) 第七节。

## 项目结构

```
main.lua / conf.lua      入口与配置
src/core/                框架层（路由、输入、音频、存档、UI 控件…）
src/game/                玩法层（世界、实体、回合、成就、战机）
src/scenes/              界面层（每个界面一个场景模块）
localization/            三语语言包
resources/               字体与 CRT 着色器
```

各模块详细职责见 [MODULES.md](MODULES.md)。

## 存档

`savegame.lua`（人类可读的 Lua 表），Windows 下位于 `%APPDATA%/LOVE/star_guardian/`。保存：语言、战机、最高分、音量、全屏偏好、生涯统计、成就解锁。

## 许可

见 [LICENSE](LICENSE)。

## 作者

胡杨怕火
