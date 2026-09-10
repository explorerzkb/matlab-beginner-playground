# Windows 体感启动与依赖

本轮在 `E:\matlabHi-pose-control`，分支 `codex/pose-control`；不依赖旧 dist。默认模式仍为键盘。

## 启动

MATLAB 命令窗口：

```matlab
cd('E:/matlabHi-pose-control')
startGame('InputMode','pose')
```

Windows PowerShell：

```powershell
& 'D:/MATLAB/R2025b/bin/matlab.exe' -sd 'E:/matlabHi-pose-control' -r "startGame('InputMode','pose')"
```

按 K 可切回键盘；在游戏中 K 可重新启动体感。C 重校准。Esc 暂停、长按 R 回检查点、Space 喝茶、Q 退出。体感独占左右和跳跃，键盘不与体感方向叠加。正常键盘启动仍用 `startGame`。

身份不确定时必须 C 重新校准，普通暂停或复活不能绕过；固定站位跟踪不支持两人交叉换位。退出或 K 切键盘自动保存数字性能记录至 `pose-validation-results/pose-*.mat`，不保存相机图片。

开场有镜像左右站位区：左侧绑定开局左梨，右侧绑定右梨。全身、双肘、脚踝入画，顶部留起跳余量。胸前双手靠拢、肘向外，双臂水平保持 2.5 秒；倒计时后逐人向左右倾斜并试跳，界面记录三个检查项目。需要测试时可 K 跳转键盘，但不能据此声称双人校准通过。

## 实际依赖

在本机已执行：MATLAB R2025b；Deep Learning Toolbox；Deep Learning Toolbox Interface for TensorFlow Lite 支持包；MATLAB Support Package for USB Webcams；Parallel Computing Toolbox（用于独立进程采集／推理）；Image Processing Toolbox（等比例缩放）。本机有 Intel Iris Xe，推理实际使用 CPU XNNPACK，不要求 NVIDIA GPU。

支持包安装后本机可直接调用模型，`TFLITE_PATH` 仍为空，库由现有 MATLAB／支持包提供；没有为此额外生成 MEX。不要把“本机路径无需手配”等同于“不需要 TFLite 库”。MATLAB Coder 已安装但本运行路线不需要它。

可用 `checkPoseEnvironment` 重新检查版本、支持包、相机列表。支持包从 MATLAB Add-Ons 安装，或按 MathWorks MPM 文档安装。不要重复安装整个 MATLAB 以替代缺失支持包。

Windows 11 的帧间等待另用随仓库提供的 `src/native/MatlabHiTiming.dll`，其完整 C# 源码和重建脚本在 `tools/windows/`。它只创建进程私有计时器，不改全局计时设置，不忙等。修改源码后关闭加载过该程序集的 MATLAB，再运行 `tools/windows/buildTiming.ps1` 重建；正常玩游戏不需要编译器。

模型随源码在 `assets/game/models/`，运行完全离线，无 Python、外部账号或服务。首次创建独立 MATLAB 工作进程会有启动等待。若本 MATLAB 已有线程并行池，保留该池并报告错误；可 K 使用键盘，不会擅自删除用户并行任务。

## 验证与限制

已通过：原生两种模型预测；公开单人图复制为双区域的位置断言；合成关键点动作测试；物理步事件消费与空中不排队；真实相机后台和至多一帧队列；实际校准界面启动及退出后相机重新打开。完整证据在 `docs/validation/pose-control/`，当前结论以 `docs/current-project-state.md` 为准。

本机优先双区域 SinglePose：公开对照每对中位 41.3 ms；MultiPose 固定尺寸后约 268.3 ms。真实后台每人约 13.47 Hz、采集调用至消费者中位 75.9 ms。这里没有把两次推理说成每人 30 Hz；没有把模型耗时当作端到端手感。

用户不参与真人操作，因此没有两名真人动作准确率、误触漏检率或整局疲劳验收。尤其持续抬臂、车尾上车、窄平台、真实踮脚与小跳的区分仍有未知。放臂释放、持续离姿全局暂停、稳定恢复倒计时均为待实玩默认方案。身份绑定基于固定站位与几何约束，不提供跨人换位身份识别。

显示目标为 30 FPS、物理 60 Hz。已修复 Windows JVM 等待被扩到 15.6 ms 的问题；后续仍有交通长帧失败记录，不能宣称全五场景稳定 30 FPS 已通过。记录保留每轮原始结果，后续通过不抹去失败。

完整物理负载首轮为 29.11／22.90／28.03／30.00／29.79 FPS，校园网未达目标。软件计时终点为 drawnow 完成，无法测出相机曝光／内部缓存和显示器真正呈现，不能当作完整动作响应时间。

缓存优化后的最近一轮为 29.48／29.99／30.00／30.00／29.27 FPS，最大帧间隔约 60 ms；软件采集调用至绘制均值 104–118 ms、各场景最大值 148–214 ms。这里包含完整物理计算与真实相机推理，但角色位置由脚本约束，现场无有效双人站位，不是体感通关或动作响应验收。
