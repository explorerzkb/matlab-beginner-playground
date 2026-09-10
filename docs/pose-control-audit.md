# 体感需求完成核对

2026-09-11。按本次用户原始范围核对，不以已实现部分重新定义完成。用户不配合现实动作，因此不请求其操作，也不把合成数据、公开单人图或相机空景当作双人验收。

| 原要求 | 当前证据 | 判定 |
| --- | --- | --- |
| 指定基线、独立 worktree／分支，保留已有工作 | Git worktree 为 `E:/matlabHi-pose-control`／`codex/pose-control`，起点 `207a0129c11c2e393230d0aeb524ce3bd292baf4`；原基线工作树保留 | 已实现 |
| 邮箱逐提交核对，不推送、不合 main | 本任务提交作者 `explorerzkb@gmail.com`；没有推送／合并操作 | 已执行 |
| 当前规格／状态／计划维护，不依赖 archive、旧 dist 或补做美术 | 当前三份文档、Windows 说明及验证索引；旧图片自动覆盖已恢复 | 已执行 |
| Windows、CPU/GPU、内存、MATLAB、工具箱与相机盘点 | 验证目录的 environment MAT、camera-probe、真实模型和启动日志；R2025b 原生运行 | 已执行，安装状态随外部重装可能变化 |
| 原键盘先跑，再独立小样，再接入 | keyboard-baseline、model-comparison、pipeline-checks、integration／live-startup 日志；提交顺序可核对 | 已执行；旧性能失败保留 |
| 两种 MoveNet 的具体版本／原生兼容性比较 | 模型 README 的来源及 SHA；SinglePose 与固定尺寸 MultiPose 实际预测，公共图坐标断言与耗时 | 兼容性／静态耗时已验证；真实两人质量未验证 |
| 依赖写清，未经同意不转 Python | Windows 说明：Deep Learning、TFLite 接口／库、Webcams、Parallel Computing、Image Processing；无 Python 推理、无额外 MEX | 已实现 |
| 镜像站位、固定身份、水平 2–3 秒与左右试跳检查 | runPoseCalibration、stepPoseController；真实 UI 预览／退出、合成校准和中断重计时测试 | UI／逻辑已验证；真人成功校准缺证据 |
| 两肘法线方向，左右不反、三级输入、摩擦保留 | poseFeatures 的解剖左右约定；testPoseController、testPoseSampling；物理配置未改 | 合成验证通过 |
| 平滑、中立区、进入退出阈值 | stepPoseController；跨过中立区但缺少中间采样的反例修复与回归 | 已验证逻辑；舒适阈值未验证 |
| 双髋／双踝上移、速度、置信度、一次起跳与落地重置 | 较低脚踝参考；单脚落地拒绝、单人／同时／交替／倾斜跳合成测试 | 已实现并合成验证 |
| 区分真实抬手、侧倾、蹲起、踮脚、小跳 | 合成抬手／蹲起／固定脚踝踮脚不触发；MoveNet 17 点没有脚跟／脚尖接触状态 | 真人误触／漏检率未知，不能判通过 |
| 真人落地与游戏着地独立，不排队空中起跳 | consumePoseInput 的序号／时间／TTL；testPoseGameInput 实际调用 stepPhysics 后落地不自动跳 | 已验证逻辑 |
| 裁剪、缩放、补边统一还原固定相机坐标 | preparePoseImage、restorePoseCoordinates；非对称补边逆变换与公共图断言 | 已验证；首版固定半幅 ROI，无动态裁剪 |
| 识别不阻塞正常主循环、不堆积画面 | Processes 独立工作进程、最多一请求、零等待 poll；真实相机 pipeline-checks | 已验证；启动／致命错误清理有进程等待 |
| 短丢点释放、持续丢失／放臂全局暂停、身份不确定重新确认 | stepPoseController、consumePoseInput、resetPoseSession；身份锁定不能被普通暂停绕过 | 合成验证通过；跨人换位不支持 |
| 放臂规则只作为待试玩默认 | 当前状态与 Windows 说明明确标为未真人验证 | 已按要求标注 |
| 序章／暂停／复活／结算不积存事件 | 生命周期 epoch、cursor 清理；新一轮校准试跳不能复用旧序号；testPoseGameInput | 逻辑／部分真实窗口流程已验证 |
| K 键盘模式、C 校准、其他行为键盘调试，输入优先级 | readInputSnapshot、runGame；live-mode-switch-2、testInputMappings | 已验证；无声音识别 |
| 异常／退出释放相机与本任务资源 | fatal-worker-cleanup、live-startup、live-mode-switch-2 的相机重开 | 真实资源流程通过；未制造物理拔线 |
| 显示 30 FPS、物理 60 Hz，五场景长帧 | 最新完整物理＋相机夹具 29.48／29.99／30.00／30.00／29.27 FPS，59.33–59.79 物理步／秒；最大帧间隔约 60 ms | 已测量，持续稳定目标未完全证明 |
| 相机／每人姿态／显示率独立报告 | poseTelemetry／savePoseTelemetry；区域率与绑定玩家率分开，单人推理总次数单列 | 已实现计时；没有有效两人站位时不报告有效双人率 |
| 争取约 150 ms 端到端，并判断手感 | 软件采集调用至 drawnow 均值 104–118 ms、各场景最大 148–214 ms | 曝光、内部缓存、屏幕呈现和真人动作起点未知；未达完整验收 |
| Code Analyzer 和现有逻辑回归 | sampling-checks、final-regression；新增路线输入适配后另跑 journey-adapter-regression | 以对应日志为准，不以测试名推断覆盖 |
| 窄平台、车尾和整局体感路线 | runPoseJourneyCheck：10／12 Hz 合成关节、83 ms 交付延迟、0.5 秒跳跃轨迹、原控制核心和实际物理；只提前规划起跳后上／下路均通过 | 合成整路通过；10 Hz 有起跳未分类，真人／图像识别／手感仍未通过 |
| 可启动版本、Windows 命令、实际依赖、限制交付 | docs/pose-control-windows.md；实际窗口启动及切换已执行 | 实验版可启动；完整双人验收未完成 |

## 下一步边界

整路夹具仍是自动策略：它使用完整游戏状态提前规划，并非图像推理或真人决策。最初直接策略在北湖失败，整体提前预测在登录重试停滞；只对起跳提前规划后，12 Hz 上／下路为 59.68／72.05 秒，10 Hz 为 72.38／72.05 秒。10 Hz 上路两人分别 23／24 次模拟身体起跳，仅分类并消费 22／23 次；下路 18／18 次中分类并消费 17／18 次。差异仍需区分落地重新允许时机、生命周期清理或识别判据，不得称为零漏检。地图、碰撞、绳子、剧情、道具和着地规则没有为迁就夹具而放宽。

完整完成仍缺两人实际站位／动作和整局手感，以及可关联物理动作起点、曝光和显示的延迟证据。公开视频或合成骨架至多补充识别测试，不能证明这台相机布置下的身份可靠性、疲劳或车尾时机。当前不标记任务完成。
