# Windows 体感验证证据

工作树 `E:\matlabHi-pose-control`，分支 `codex/pose-control`，基线 `207a0129c11c2e393230d0aeb524ce3bd292baf4`。启动与依赖见 [Windows 说明](../../pose-control-windows.md)。这是可启动的实验体感模式，尚无两名真人验收。

## 已执行（2026-09-11）

- Windows 11 Pro 22621、i5-13500H、31.73 GiB RAM、Intel Iris Xe。实际 MATLAB 绘制为 ANGLE Intel D3D11。
- 重装后 MATLAB R2025b、Deep Learning Toolbox、TFLite 接口、USB Webcams、Parallel Computing、Image Processing 可运行；HD Camera 实际采集通过。`TFLITE_PATH` 为空但现有接口运行库实际可用，无额外 MEX 或 Python 推理。
- `model-comparison.txt`：官方 SinglePose 双区域推理每对中位 41.3 ms、最大 50.5 ms；MultiPose 固定输入后中位 268.3 ms、最大 376.6 ms。公开单人图复制两份验证位置还原，不能证明两人真实遮挡质量。优先 SinglePose。
- `pipeline-checks.txt`：640×480 真实摄像头、单工作进程、至多一张请求；每人计算更新 13.47 Hz，采集调用至消费者中位 75.9 ms。不是每人 30 Hz，也不是曝光至显示延迟。`camera-probe.txt` 的 1280×720 独立采集调用率 19.33 Hz，不是硬件曝光 FPS。
- `live-startup.txt`：摄像头预览进入校准界面后自动退出，相机重新打开成功；没有执行两人校准。
- `final-regression.txt`：真实后台取消后全局暂停、输入释放、摄像头重新打开通过；Code Analyzer 零问题、完整冒烟、连续序章及四条逻辑输入路线通过（59.95／72.30／59.97／72.28 s）。日志内 Windows 汇总器的“三人次通过”是该汇总器的测试数据，不能当作真人证据。
- `telemetry-checks.txt`：合成姿态、物理步事件消费、空中不排队、身份锁定不被普通暂停绕过、分开计时、旧样本不重复消费、Code Analyzer 通过。
- `safety-and-pacing-checks.txt`：带真实摄像头推理的五场景可见绘制 29.99／30.00／29.16／30.00／29.63 FPS；该轮只推进场景机制，非完整物理负载。交通 8 个 >50 ms 长帧，最大 66.3 ms；未记全五场景稳定 30 FPS 通过。后续含完整物理计算的结果另存 `full-physics-pose-render.txt`，不覆盖本轮。

## 保留的失败与前态

最新完整物理负载对照：`full-physics-pose-render.txt` 为 29.11／22.90／28.03／30.00／29.79 FPS。`cached-physics-pose-render.txt` 在短跑等待姿态图元缓存后为 29.48／29.99／30.00／30.00／29.27 FPS，绘制坐标强制重算对照通过；最大帧间隔约 60 ms，软件采集至绘制均值 104–118 ms、最大 148–214 ms。前者校园段 2032.9 ms 含跨场景预热遗留样本，计时边界已修正并回归。两轮均没有有效两人站位，关节有效率为 0；不冒称识别或真人手感通过。

重装前 `webcamlist` 未定义、TFLite 缺支持包。官方 MPM 曾进入安装，用户重装时停止了本任务安装；这一前态后来由真实预测和采集结果更新。旧环境 MAT／日志原样保留。

`keyboard-baseline/latest-run.txt` 原键盘强制绘制 19.3／43.5／33.4／39.0／32.3 FPS，未过旧 40 FPS 门；`paced.txt` 为 4.4／19.7／13.9／15.8／15.0 FPS，存在并发安装／MATLAB 活动，不推断因果。原逻辑回归通过。

`high-resolution-timing.txt`：Windows JVM .25 ms 等待实际中位 15.599 ms；私有高精度计时器中位 .619 ms。改后初测无识别五场景 29.90／30.00／26.00／29.98／29.80 FPS，交通最大 124.5 ms。后续结果不抹去这次失败。

旧回归产生的截图只保留本机 `keyboard-baseline/generated/`，被自动测试覆盖的旧 `docs/visuals/` 图片恢复为原版本。没有补制游戏美术。

## 指标边界与待验证

控制核心测试使用合成关节，覆盖水平、左右相反倾斜、跳跃、丢点、重叠锁定、恢复、过期／单次事件及坐标逆变换。模拟抬手／蹲起／固定脚踝的踮脚不触发，不等于真人踮脚准确率。

游戏运行记录保存在 `pose-validation-results/pose-*.mat`，只含数字，不保存相机图片。相机采集调用率、每区域有效关节率、总推理调用率分开；每场景统计有效游戏时长、绘制／物理次数、长帧和采集调用至物理／drawnow 完成的延迟均值、最大值及 >150 ms 次数。硬件曝光时刻、摄像头内部缓存和显示器真正呈现时刻未知；不能把这些软件计时当作完整动作响应。

未验证：两名真人身份稳定性、同时／交替跳跃识别质量、真实误触／漏检率、持续抬臂疲劳、窄平台／车尾起跳和完整体感通关。用户不配合现实操作，故不要求其完成动作；这些项目继续明确留空。

## 官方来源

- [MoveNet MATLAB 示例](https://www.mathworks.com/help/deeplearning/ug/tflite-human-pose-estimation.html)
- [TFLite 依赖与运行库](https://www.mathworks.com/help/deeplearning/ug/prerequisites-for-deep-learning-with-tensorflow-lite-models.html)
- [USB Webcams 支持包](https://www.mathworks.com/help/supportpkg/usbwebcams/ug/installing-the-webcams-support-package.html)
- [MPM 安装](https://www.mathworks.com/help/install/ug/matlab-package-manager.html)

版本以本机实际 R2025b 调用结果为准；不能将更新版本的 LiteRT 文档直接当作已装能力。
