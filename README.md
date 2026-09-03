# MATLAB Beginner Playground

一个面向 MATLAB 初学者的双人二维平台游戏课程项目。两位玩家共用一把键盘，控制两只由普通绳连接的原创小梨，在良乡校园与数字界面交叠的关卡中合作前进。

项目已经完成首版代码与第一轮程序化校园视觉：包含五秒双人按键检测、数据点序章、四个连续关卡、普通绳物理、检查点、暂停／重置／退出、轨迹统计与 MATLAB 曲线结算，并加入可辨认的校园建筑、桥梁、道路、绿化、路灯、导视和校园生活细节。当前代码已在 macOS 的 MATLAB R2025b 通过自动化与逐关截图检查；最终美术观感、Windows 双人实机手感、键盘冲突和帧率仍由用户与目标电脑验收。

## 启动

在 MATLAB 中把当前文件夹切换到项目根目录，然后运行：

```matlab
startGame
```

Windows 11 也可以双击 `startGame.bat`。它会优先使用系统 `PATH` 中的 MATLAB；如果找不到，则尝试标准的 `C:\Program Files\MATLAB\R2025b\bin\matlab.exe`。

默认键位：玩家一使用 `A/D/W`，玩家二使用方向键；若方向键组合冲突，玩家二可改用 `J/L/I`。`Esc` 暂停，按住 `R` 0.8 秒重置本关，`Q` 退出。低性能模式可在 MATLAB 中运行 `startGame('LowPowerMode', true)`，把目标渲染率降到约 20 FPS。

## 自动检查

```matlab
addpath('tests')
runCodeChecks
runSmokeTests
```

`runSmokeTests` 会验证四关数据、碰撞、松绳／张力规则、双人机关、破防水、十分钟等价物理步进，以及不可见窗口下的四关创建与清理。它是本机代码级证据，不替代两位玩家在目标 Windows 键盘上的连续试玩。

## 当前有效入口

按以下顺序阅读即可，不要从历史文档恢复旧需求：

1. [`docs/current-project-state.md`](docs/current-project-state.md)：当前阶段、已经确认的事实和最近一步；
2. [`docs/game-spec-v1.md`](docs/game-spec-v1.md)：首版游戏的唯一产品与玩法规格；
3. [`docs/implementation-plan.md`](docs/implementation-plan.md)：代码结构、开发顺序和阶段验收；
4. 涉及画面或场景时读取 [`docs/visual-spatial-sop.md`](docs/visual-spatial-sop.md)：图片、建模和空间合理性的强制检查；
5. [`assets/reference/README.md`](assets/reference/README.md)：当前关卡允许使用的设计参考。现实场景任务还必须实际打开索引点名的图片，不能停在索引页。

项目协作规则见 [`AGENTS.md`](AGENTS.md)，Git 与发布规则见 [`VERSIONING.md`](VERSIONING.md)。

## 历史区

`archive/snapshots/2026-09-03-preimplementation/` 保存研究阶段的盲审、候选方案、创意发散、画风预览和未采用素材。它只用于追溯，不是当前需求来源。后续开发者和 Codex 默认不得读取或搜索其中内容。

## 项目结构

```text
startGame.m              MATLAB 内的唯一启动入口
startGame.bat            Windows 双击启动入口
src/                     主循环、输入、物理、碰撞和渲染
config/                  键位、画面、音量和性能档
levels/                  四个正式关卡的数据
assets/game/             游戏运行时实际加载的图像和音频
tests/                   不进入完整游戏即可运行的检查
docs/                    当前规格、计划和验证状态
archive/                 默认禁止读取的历史快照
```

`assets/reference/` 只供设计和制作正式美术时参考；MATLAB 运行时只能读取 `assets/game/`。
