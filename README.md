# 绳系双梨：良乡校园协作记

一个面向 MATLAB 初学者的本地双人二维平台游戏。两位玩家共用一把键盘，控制两只能力相同、由普通绳连接的小梨，在一张不中断的横向世界中穿过北理良乡校园的现实锚点与电脑页面。

当前运行时已接入连续世界重构与后续空间修复：三颗共享爱心、像素 HUD、真实冰红茶图标、光滑双梨、实体鸭鹅、羊驼后踢、孔雀弹射、固定世界坐标的校园网页面、北理桥／红绿灯双路线、自行车右上撞飞、文博中心、校车移动平台、三根路灯和体育馆终点都已接入同一套世界状态。旧破防、喷泉、乐学和 Lucy 河已从当前运行链路及对应测试中移除。

## 启动

在 MATLAB 中把当前文件夹切换到项目根目录，然后运行：

```matlab
startGame
```

Windows 11 也可以双击 `startGame.bat`。它会优先使用系统 `PATH` 中的 MATLAB；如果找不到，则尝试标准的 `C:\Program Files\MATLAB\R2025b\bin\matlab.exe`。

目标 Windows 机的验收不再需要手抄数据：双击 `validateWindows.bat`，选择当前 100% / 125% / 150% 缩放比。它会跑完整自动回归、50 Hz 完整屏幕刷新节拍、连续三轮五场景最大绘制能力，再用引导界面检查六组真实四键／五键组合。日志保存到 `windows-validation-results/`。

默认使用性能平衡档：960×540 窗口、普通背景每 6 个源像素采样一次，校园网页每 2 个源像素采样一次；角色轮廓、碰撞和 60 Hz 物理不降频。需要试用 1280×720 高画质档时运行：

```matlab
startGame('LowPowerMode', false)
```

1280×720 高画质档已在开发 Mac 连续三轮通过五场景 40 FPS 门槛，最低分别为 62.6、62.4 和 84.0 FPS。默认档仍保持 960×540，因为目标 Windows 机器尚未实测；这些 Mac 结果不是 Windows 性能保证。

## 操作

- 玩家一：`A / D / W`；
- 玩家二：方向键；若键盘组合冲突，可改用 `J / L / I`；
- 全局道具：长按 `Space` 使用一瓶共享冰红茶；
- `Esc` 暂停，按住 `R` 0.8 秒回到最近检查点，`Q` 退出。

冰红茶只强化跳跃、地面加速、空中控制和最高跑速，不回血、不减伤。共享背包最多两瓶，北湖入口放置三瓶。

## 当前连续路线

```text
MATLAB 坐标轴入口
  → 北湖实体鸭鹅／羊驼后踢／孔雀弹射
  → 综合教学楼方向的校园网实体网页
  → 登录成功后的操场
  → 北理桥／红绿灯二选一
  → 北食堂、徐特立图书馆附近汇合
  → 自行车／电动车剧情撞向右上方
  → 文博中心安全落点
  → 绿白校车经过国防文化广场并躲避三根路灯
  → 体育馆终点
```

校园地图显示文博中心位于国防文化主题广场／体育馆片区北侧。游戏在文博上车处用方位牌保留这层南北关系，再把校车游览压平成适合横版玩法的向右路线；屏幕向右不等于现实地理上的正东，也不宣称精确测绘。

## 校园网页面

校园网不是弹窗或过场，而是一张固定在世界坐标中的可站立平面：

```text
登录页
  └─ 每局第一次碰登录区 → 整页切为 Chrome 超时页
                              → 网页承托撤除 → 双梨无伤坠落复位
重试登录页
  └─ 两只梨共同站上登录区 → 0.8 秒原地加载
                              → 同一平面原位切成操场成功页
```

页面外框、世界矩形和角色坐标在切换时都不动；不淡化、不锁镜头。登录成功后角色直接沿操场向右走，网页只会因正常跟随镜头自然留在身后。

核心游戏完全离线，不读取真实校园账号、不保存密码、不发起校园网请求，也不打开浏览器。运行时只显示用户明确提供的学号 `1120250036`；成功页参考图中的 IP、流量、时长和余额已清除并替换为离线占位。

## 自动检查与当前边界

```matlab
addpath('tests')
runAcceptanceChecks
```

真人整局请使用带元数据和人工确认的验收入口：

```matlab
runWindowsPlaytest
```

它会记录当前缩放、计划与实际路线、玩家二键位、本局编号和两人确认；窗口标题每秒刷新实际绘制 FPS。每局结束或退出时，北湖、校园网／短跑、交通、自行车和校车五段的真实交互数据会另存一份日志。某段停留不到 2 秒会标成样本不足，不拿瞬时数字冒充稳定帧率。完成后运行 `summarizeWindowsValidation`，只有三档缩放、至少三局、两条路线、两套键位和人工确认全部齐全才显示 PASS。

2026-09-10 的开发机统一验收覆盖完整输入旅程、21 组剧情飞行、七个检查点复位、连续曲线变梨序章、五段强制逐帧能力和 50 Hz 完整屏幕刷新节拍。静态图片采样缓存让同一 MATLAB 进程第二次测试启动由 1.026 秒降到 0.793 秒，约快 22.7%。v24 又修正了校园终段被重复采样一次的画质回退，并新增显示纹理尺寸断言；最终独立解压包强制绘制最低 74.5 FPS，默认档与高画质档五段定速刷新均为 49.6 FPS。完整日志和重新生成的高画质画面在 `docs/visuals/performance-v24/`。

目标 Windows 11 的真人双人操作、多键冲突、三种显示缩放和连续三局稳定性仍未验收，因此当前不能称为最终交付版。Mac 上的确定性输入测试不等于所有玩家操作都已覆盖。

完整实现状态与视觉证据见：

- [`docs/current-project-state.md`](docs/current-project-state.md)
- [`docs/visuals/performance-v17/review.md`](docs/visuals/performance-v17/review.md)
- [`docs/visuals/performance-v17/`](docs/visuals/performance-v17/)
- [`docs/visuals/performance-v18/review.md`](docs/visuals/performance-v18/review.md)
- [`docs/visuals/performance-v19/review.md`](docs/visuals/performance-v19/review.md)
- [`docs/visuals/performance-v20/review.md`](docs/visuals/performance-v20/review.md)
- [`docs/visuals/performance-v21/review.md`](docs/visuals/performance-v21/review.md)
- [`docs/visuals/performance-v23/review.md`](docs/visuals/performance-v23/review.md)
- [`docs/visuals/performance-v24/review.md`](docs/visuals/performance-v24/review.md)

## 当前有效入口

按以下顺序阅读，不要从历史区恢复旧需求：

1. [`docs/current-project-state.md`](docs/current-project-state.md)：当前阶段、已验证证据和下一步；
2. [`docs/game-spec-v1.md`](docs/game-spec-v1.md)：文件名因兼容保留，内容是当前连续世界规格；
3. [`docs/implementation-plan.md`](docs/implementation-plan.md)：实施状态和剩余阶段门；
4. [`docs/visual-spatial-sop.md`](docs/visual-spatial-sop.md)：画面、场景与空间证据规则；
5. [`assets/reference/README.md`](assets/reference/README.md)：允许使用的设计参考及其边界。

## 项目结构

```text
startGame.m              MATLAB 内的唯一启动入口
startGame.bat            Windows 双击启动入口
validateWindows.bat      Windows 一键性能／多键验收
runWindowsValidation.m  Windows 验收主函数
runWindowsPlaytest.m    带缩放、路线、键位和人工确认的真人整局入口
summarizeWindowsValidation.m
                         Windows 三档／三局证据完整性汇总
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

当前开发分支为 `codex/gameplay-round-2`。未经用户明确要求不自动提交或推送；本仓库新提交只能使用 `explorerzkb@gmail.com`。
