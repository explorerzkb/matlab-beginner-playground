# Windows 体感开发证据（进行中）

2026-09-11，工作树 `E:\matlabHi-pose-control`，分支 `codex/pose-control`，基线 `207a0129c11c2e393230d0aeb524ce3bd292baf4`。

## 已执行

- Windows 11 专业版 Build 22621，i5-13500H 12 核／16 线程，31.73 GiB RAM，Intel Iris Xe 驱动 31.0.101.4032；另有虚拟显示适配器，未证明其对性能的影响。
- 系统 HD Camera PnP OK；**未打开摄像头、未测摄像头帧率**。
- 重装前 MATLAB R2025b 25.2.0.2998904 可执行，Deep Learning、Parallel Computing、MATLAB Coder、Image Processing、Computer Vision 可见；USB Webcams 未就绪，TFLite 调用报缺支持包，TFLITE_PATH 空。
- `keyboard-baseline/latest-run.txt`：原基线 Code Analyzer 零问题、全部冒烟、连续序章、四条输入旅程通过。旅程 59.95／72.30／59.97／72.28 秒。这是给定合成游戏输入，**不是两名真人玩过**。日志中 Windows 汇总 PASS 来自夹具测试。
- 强制绘制五场景：北湖 19.3、校园网／跑道 43.5、交通 33.4、自行车 39.0、校车 32.3 FPS；原 40 FPS 性能门失败。该测试图窗不可见，数字是强制绘制吞吐，不宣称可见整局显示效果。
- `keyboard-baseline/paced.txt`：定速完整绘制 4.4／19.7／13.9／15.8／15.0 FPS，失败。当时有并发 MATLAB／安装活动，需在无竞争时重测；不得擦除本轮失败或推断已查明原因。
- 独立控制核心第一轮 `testPoseController` 通过，`runCodeChecks` 零问题；这是合成关键点，不含模型识别或真人动作。之后新增单人丢点处理、模型适配和摄像头小样，**这些后续改动因用户重装 MATLAB 尚未重跑**。
- 标准旧测试自动生成的截图放在 `keyboard-baseline/generated/`，原先受测试覆盖的 `docs/visuals/` 文件已恢复为基线；没有改游戏资产或补制美术。新截图尚未做人工视觉验收。

## 安装中断和续测

用户授权补齐 MATLAB 原生依赖后，从 MathWorks 下载并核验了签名有效的 MPM。官方 R2025b 产品标识为 `MATLAB_Support_Package_for_USB_Webcams` 和 `Deep_Learning_Toolbox_Interface_for_TensorFlow_Lite`。MPM 进入安装但没有完成回执；收到“正在重新安装 MATLAB”后停止本任务两个 MPM 进程，未继续触碰安装。安装后状态未知，必须重测。

MathWorks 文档说明，MATLAB 解释执行需要 Deep Learning Toolbox、接口支持包及 TFLite 运行库；生成代码另外需要 MATLAB Coder。当前 `loadTFLiteModel` 文档要求 TFLite 2.15.0 与 Windows DLL 路径。R2026a 引入的 `loadLiteRTModel` 是另一套接口，不能把新文档直接视为 R2025b 已装能力。

来源：

- [MathWorks 原生 MoveNet 示例](https://www.mathworks.com/help/deeplearning/ug/tflite-human-pose-estimation.html)
- [TFLite 依赖与库版本](https://www.mathworks.com/help/deeplearning/ug/prerequisites-for-deep-learning-with-tensorflow-lite-models.html)
- [USB Webcams 安装](https://www.mathworks.com/help/supportpkg/usbwebcams/ug/installing-the-webcams-support-package.html)
- [MPM 支持包安装](https://www.mathworks.com/help/install/ug/matlab-package-manager.html)

## 小样命令（重装后运行，尚未验收）

MATLAB 命令窗口：

```matlab
cd('E:/matlabHi-pose-control')
checkPoseEnvironment
addpath('tests')
testPoseController
runCodeChecks
runPosePrototype('E:/matlabHi/dependencies/movenet-single/3.tflite','single',60)
```

现有键盘游戏仍用 `startGame`。体感**尚未接入** `startGame`，不能声称已交付可玩体感版本。小样先后执行两次单人推理，并且只在独立窗口运行；不证明后台可用，不作为游戏主循环实现。初版固定半幅区域、等比例补边、统一原始相机坐标和镜像预览。暂不做动态裁剪，避免尚未验证的裁剪变化制造跳跃。

每条小样记录保存采集调用开始／结束、两次推理返回时间、状态就绪时间；不保存相机图片。报告采集调用完成率和每人有效关键点更新率。它们不是摄像头硬件曝光 FPS；小样总推理次数为单人模式帧数乘 2，多人模式为帧数。帧龄包含采集与顺序推理，但不包含曝光起点，不能冒称完整端到端响应。

## 真人配合（等待软件自动检查通过后再进行）

两人并排面对固定摄像头，各在镜像左右半区，全身、外展肘、脚踝都入画，头顶留起跳余量；不交叉换位。胸前两手靠拢、肘向外水平保持 2.5 秒，倒计时后先玩家一分别“自己的右肘降低、左肘降低、水平”，再玩家二重复，逐项核对小样方向；随后单人／同时／交替原地轻跳和倾斜中跳。需另记录抬手、蹲起、踮脚、遮挡和放臂的误触／漏检，不能只观察漂亮的骨架图。

站立高度冻结、角度迟滞、身份距离门槛和放臂暂停是待试玩初值。仅用髋踝关键点未必可靠区分全部踮脚动作；须真人统计验证。模型推理兼容性、摄像头缓存帧龄、后台进程通信、游戏生命周期与 30 FPS 五场景验收仍未完成。
