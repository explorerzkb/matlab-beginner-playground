# 绳系双梨：良乡校园协作记

一个面向 MATLAB 初学者的本地双人二维平台游戏。两位玩家共用一把键盘，控制两只能力相同、由普通绳连接的小梨，从 MATLAB 坐标轴进入一张连续校园地图，经过北湖、校园网页面、南北交通和乐学任务，最终共同到达 Lucy 河。

当前北湖第四轮和校园网第五轮本机返工已经完成：地图不会在区域之间黑屏、显示关卡卡或重建角色；破防值、冰红茶、绳、检查点和路线选择贯穿全局。车流通行、北湖长度、羊驼捷径、页面原位布局和校园网物理路线均已有直接测试；目标 Windows 真人验收仍未完成。

## 启动

在 MATLAB 中把当前文件夹切换到项目根目录，然后运行：

```matlab
startGame
```

Windows 11 也可以双击 `startGame.bat`。它会优先使用系统 `PATH` 中的 MATLAB；如果找不到，则尝试标准的 `C:\Program Files\MATLAB\R2025b\bin\matlab.exe`。

## 操作

- 玩家一：`A / D / W`；
- 玩家二：方向键；若键盘组合冲突，可改用 `J / L / I`；
- 全局道具：长按 `Space` 约 0.35 秒饮用一瓶共享的热带风味冰红茶；
- `Esc` 暂停，按住 `R` 0.8 秒回到最近检查点，`Q` 退出。

冰红茶最多携带两瓶，会让当前破防值减 2，并给予约六秒的小幅跑跳强化和环境抗击退。它不会倒扣已经发生的共同复活次数。

低性能模式可运行：

```matlab
startGame('LowPowerMode', true)
```

## 当前流程

```text
MATLAB 坐标轴
  → 北湖：四只鹅、四只鸭与可落上红桥的羊驼喷嚏捷径
  → 校园网：红桥跳公告框、经过用户名自动填表、双梨即刻登录、自助服务出口与随机掉线彩蛋
  → 南北交通：喷泉／北理桥上层路线，或红绿灯／车辆／候灯人群下层路线
  → 乐学：原位六格倒计时、共同开始选课、原位我的课程存档、分批通知任务
  → Lucy 河：清空当前破防并结算连续轨迹
```

游戏不会读取真实校园账号、发起选课或校园网请求，也不依赖 Symbolic Math Toolbox。

## 自动检查

```matlab
addpath('tests')
runCodeChecks
runSmokeTests
runPerformanceCheck
```

`runSmokeTests` 覆盖输入、碰撞、普通绳、连续区域、破防与冰红茶、校园网完整跳跃路线和掉线恢复、全部校园机关、两条交通路线、安全复活、十分钟等价物理步进，以及不可见窗口的创建与清理。`runPerformanceCheck` 在乐学任务全开的连续世界重场景进行 1280×720 强制绘制。

2026-09-04 的开发机最新结果为：MATLAB R2025b Code Analyzer 0 问题、统一冒烟测试通过；校园网第五轮后的单次重场景结果为 20.2 FPS @ 1280×720，通过 20 FPS 低配门槛但没有余量，此前同机五次基线为 20.7—34.9 FPS。它们是 Mac 代码级证据，不替代目标 Windows 电脑上的多键冲突、125%／150% 缩放、连续三局和真人可玩性验收。

## 当前有效入口

按以下顺序阅读，不要从历史区恢复旧需求：

1. [`docs/current-project-state.md`](docs/current-project-state.md)：当前阶段、验证证据和待办；
2. [`docs/game-spec-v1.md`](docs/game-spec-v1.md)：文件名因兼容保留，内容是当前连续世界 v2 规格；
3. [`docs/implementation-plan.md`](docs/implementation-plan.md)：代码结构、开发顺序和阶段门；
4. [`docs/visual-spatial-sop.md`](docs/visual-spatial-sop.md)：画面、场景与空间证据规则；
5. [`assets/reference/README.md`](assets/reference/README.md)：允许使用的设计参考及其边界。

第三轮十张机制截图和“不等于最终美术”的逐项结论见 [`docs/visuals/continuous-world-round3-review.md`](docs/visuals/continuous-world-round3-review.md)。第二轮复核只保留为被真人试玩推翻前的历史证据。项目协作规则见 [`AGENTS.md`](AGENTS.md)，Git 与发布规则见 [`VERSIONING.md`](VERSIONING.md)。

## 项目结构

```text
startGame.m              MATLAB 内的唯一启动入口
startGame.bat            Windows 双击启动入口
config/                  键位、物理、道具、画面和性能配置
levels/continuousCampusWorld.m
                         当前唯一运行世界的数据
src/                     主循环、输入、物理、机关、碰撞和渲染
assets/game/             游戏运行时实际加载的资源
assets/reference/        只供设计研究，不得由运行时代码读取
tests/                   直接机制测试、统一检查、性能和截图工具
docs/                    当前规格、计划、视觉证据和状态
archive/                 默认禁止读取的不可变历史快照
```

当前开发分支为 `codex/gameplay-round-2`，已推送并跟踪同名远端分支。GitHub 提交接口确认作者归属账号 `explorerzkb`，提交邮箱为项目固定的 `explorerzkb@gmail.com`。
