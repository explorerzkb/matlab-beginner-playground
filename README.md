# MATLAB Beginner Playground

一个面向 MATLAB 初学者的双人二维平台游戏课程项目。两位玩家共用一把键盘，控制两只由普通绳连接的原创小梨，在良乡校园与数字界面交叠的关卡中合作前进。

项目已经结束创意发散，进入实现阶段。当前还没有可运行的游戏代码；首版范围、关卡和技术边界已经冻结，接下来从灰盒原型开始开发。

## 当前有效入口

按以下顺序阅读即可，不要从历史文档恢复旧需求：

1. [`docs/current-project-state.md`](docs/current-project-state.md)：当前阶段、已经确认的事实和最近一步；
2. [`docs/game-spec-v1.md`](docs/game-spec-v1.md)：首版游戏的唯一产品与玩法规格；
3. [`docs/implementation-plan.md`](docs/implementation-plan.md)：代码结构、开发顺序和阶段验收；
4. [`assets/reference/README.md`](assets/reference/README.md)：当前关卡允许使用的设计参考。

项目协作规则见 [`AGENTS.md`](AGENTS.md)，Git 与发布规则见 [`VERSIONING.md`](VERSIONING.md)。

## 历史区

`archive/snapshots/2026-09-03-preimplementation/` 保存研究阶段的盲审、候选方案、创意发散、画风预览和未采用素材。它只用于追溯，不是当前需求来源。后续开发者和 Codex 默认不得读取或搜索其中内容。

## 当前与目标结构

目前仓库只有规格、参考资料和历史存档。实现阶段将逐步形成：

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
