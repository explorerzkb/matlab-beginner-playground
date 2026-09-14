# 下一台设备零上下文接手

更新日期：2026-09-15

这份文件是新电脑 `git pull` 后的第一入口。当前唯一交付分支是 `main`，远端是 `origin`（`https://github.com/explorerzkb/matlab-beginner-playground.git`）。以拉取后的 `origin/main` 为准，不恢复旧开发分支，不读取 `archive/`，也不要使用旧 `dist/` 判断源码状态。

## 先做什么

1. 在项目根目录执行 `git pull --ff-only origin main`，确认 `git status --short --branch` 没有未说明的改动。
2. 依次阅读本文件、`docs/current-project-state.md`、`docs/game-spec-v1.md`、`docs/implementation-plan.md`。
3. MATLAB 当前文件夹切到项目根目录，先运行 `checkPoseEnvironment`，再运行 `startGame`。
4. `startGame` 是唯一游戏入口：默认先进入体感；任何依赖、摄像头、模型、后台进程或启动超时错误都会自动释放体感资源并进入键盘。运行中按 K 也可切到键盘；C 重校准。

如果只想排除体感环境，显式运行：

```matlab
startGame('InputMode','keyboard')
```

## 真正目标设备

- 荣耀 MagicBook Pro 14 2025，第 2 代 Core Ultra 9；对应官方配置为 Intel Core Ultra 9 285H，16 核 16 线程。
- 最终性能与真人结论只能来自这台目标机。当前仓库中的 Windows 数字来自另一台开发机，只能证明回归和相对优化。
- 体感模型固定使用 CPU 上的 MATLAB 原生 TFLite/XNNPACK，不依赖 Intel Arc 核显或 NPU，因此不按品牌、核心数或 GPU 改动作阈值。
- 性能复测要记录是否插电，以及荣耀电脑管家／Fn+P 使用“智能”还是“高能”模式；不要把高能模式结果当作默认电池表现。
- 默认取 MATLAB 枚举到的第一个摄像头，优先 640×480；不支持时自动协商最近的低延迟分辨率。多摄像头可用 `startGame('PoseCamera',2)` 或摄像头名称指定。

## 环境依赖

已验证开发环境为 MATLAB R2025b，运行体感还需要：

- Deep Learning Toolbox；
- Deep Learning Toolbox Interface for TensorFlow Lite；
- MATLAB Support Package for USB Webcams；
- Parallel Computing Toolbox；
- Image Processing Toolbox。

模型已随仓库保存为 `assets/game/models/movenet-single-lightning.tflite`，SHA-256 为 `0491b130b2dd622d71a180936e957212341daca78e9f6a04e0d9c2045eff2ecb`，不需要 Python、下载、账号或网络。Windows 高精度等待库在 `assets/game/runtime/windows/MatlabHiTiming.dll`；DLL 缺失或不能加载时会退回 JVM 可移植等待。macOS 不加载 DLL，体感失败也会进入键盘。

## 已完成且不得回退的行为

- 默认体感、自动键盘降级、K 随时切换和 C 重校准已经接通。
- 同步初始化错误、异步工作进程错误、取消和启动超时均会清理本任务创建的体感会话；不会删除用户原有并行池。
- 摄像头可按名称或索引选择，并自动协商设备可用分辨率。
- 体感显示目标 30 Hz、物理 60 Hz；背景纹理步长普通场景 6、校园终段 3。角色、碰撞、模型输入和物理没有降级。
- 预处理使用无抗锯齿双线性缩放；校准预览跨进程传输上限 15 Hz；等待路径不再用会隐式绘图的 `pause`。
- 运行资源集中在 `assets/game/`，包括正式图片、模型、许可证和 Windows DLL。
- 姿态日志只保存数字指标、相机名称和协商分辨率，不保存摄像头图像。

## 已验证与仍未验证

2026-09-15 开发机最终回归已通过：MATLAB Code Analyzer 零问题、全部冒烟机制、连续序章、四条键盘完整路线，以及“默认体感预览 → K 切键盘 → 游戏坐标恢复 → 退出后摄像头可重新打开”。这不是两人真人动作证据。

开发机旧键盘 40 FPS 强制绘制门仍失败，五段为 35.7／57.2／38.4／41.4／29.0 FPS，失败不能删除或改写为通过。最终体感纹理档在无相机脚本玩家短测为 28.27／30.00／29.70／30.00／27.50 FPS，物理约 59 步／秒。并发 MATLAB 压力短测只证明相对改善，不证明目标机持续 30 FPS。

目标机仍必须完成：

1. `checkPoseEnvironment`，保存 Windows、MATLAB、支持包、摄像头名称和错误信息；
2. 直接 `startGame`，确认默认体感启动、实际协商分辨率、K 降级和退出后摄像头释放；
3. 两人固定左右站位完成校准、逐人左右倾斜和试跳，检查误触、漏检、离姿暂停、C 重校准和长时间抬臂疲劳；
4. 运行 `addpath('tests'); runPoseRenderCheck(true,1:5,30)`，记录五场景 30 秒的绘制、物理、长帧和软件采集至绘制延迟；
5. 用 `runWindowsPlaytest` 完成键盘的三档缩放、至少三局、两条路线和两套 P2 键位，再运行 `summarizeWindowsValidation`。

软件延迟终点是 `drawnow` 完成，不包含摄像头曝光／内部缓存及显示器真正呈现；不能把它表述为完整动作端到端延迟。固定站位身份绑定不支持两人交叉换位。只看上半身时，高幅踮脚与上半身轨迹相似的真跳无法严格区分。

## 自动检查入口

```matlab
addpath('tests')
runSmokeTests
runAcceptanceChecks
```

最终开发机摘要在 `docs/validation/unified-entry-final/latest-run.txt`；体感性能和历史失败证据在 `docs/validation/pose-control/`。新结果必须追加保存，不能覆盖或删除失败样本。

## Git 忽略项及迁移边界

以下内容被 `.gitignore` 明确排除，这是有意设计，不是遗漏：

- `.DS_Store`：系统元数据；
- `assets/reference/private/`：含个人信息的用户参考图，只能留在原设备，不得入库或打包；
- `dist/`：可重建发布包，运行 `python tools/build_validation_bundle.py` 生成；
- `windows-validation-results/`：目标机真人整局和设备相关日志，应在目标机重新生成；
- `pose-validation-results/`：本机体感会话数字遥测，应在目标机重新生成；
- `docs/validation/pose-control/keyboard-baseline/generated/`：可重复生成的诊断截图，不是正式游戏美术。

交接时应提交这些本地结果的可复核结论和必要的精选证据，不提交私有图片、所有原始机器遥测或可重建压缩包。本次开发机忽略区有 6 份 `pose-*.mat`：其中两份较新样本确认 `HD Camera / 640x480`，均没有有效双人绑定；这条结论已写入版本库，原始 MAT 留在开发机。当前 `dist/matlabHi-windows-validation.zip` 也是本机可重建副本，不会随 pull 出现。

## 提交纪律

- 小步提交，每个独立功能或文档更正单独提交；只暂存明确文件。
- 提交作者邮箱必须是 `explorerzkb@gmail.com`。
- 完成后推送 `main`，并确认 `git status --short --branch` 显示本地与 `origin/main` 同步。
