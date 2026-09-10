# v27 平视长卷与连续飞行

2026-09-10，已进入运行时，开发 Mac 检查通过；目标 Windows 尚未复测。

空间卡：相机在两楼西侧朝东，横向沿南北道路移动；入口在文博中心一端，沿完整立面经过另一端、两楼间的窄东西水泥路，再到体育馆。两楼共享正东南西北轴，不各自旋转。无岸线或桥。楼体与展品落在地基／广场上；飞机、坦克在体育馆高挑檐下。前景唯一柏油路就是角色和校车使用的道路，不再叠第二条路。背景建筑不参与碰撞；角色、公交、路灯保留横版玩法尺度。

已目视：campus-map-current.png 证明建筑相邻关系，不证明立面尺寸；orientation-research/museum-0.png 证明长柱廊、深窗、实墙端部与平屋檐，不给精确测绘尺寸；sports-west.jpg 证明高低错落的挑檐及真实地面落点，人像可作尺度参照；v26 原图与 road.png 证明俯视、双道路和草地隔断问题。此前索引指定的官方建筑及展品照片仍作形体参照。比例依照片校对，精确米数未知。

生成要求（内置 imagegen）：参考真实建筑照片重绘 3:1 平视长卷；完整文博长立面位于左侧约一半幅宽，禁止看见屋顶顶面；两栋建筑同轴，垂直线竖直、水平檐口平行；体育馆保留照片中的挑檐结构。自然浅蓝天与少量柔软云，无油画笔触。只有底部一条贯穿全幅的窄柏油路，上接两楼中间水泥支路，删除所有其他横路和斜路。地面压低，建筑和天空留出向上跟拍空间。禁止增加密集树楼或装饰性路网。

代码目标：取消飞行专属画面，全部物体保持同一世界坐标、同一角色尺寸、同一镜头平移；上升与下降均由连续跟随产生。

## 产物与目视复核

内置 imagegen 生成后再针对文博檐口作一次水平校正，正式资源为 `assets/game/images/backgrounds/last-bus-handscroll-v27.png`（2172×724）。第二次的完整追加提示词：

> Precise minor edit only. KEEP this image composition, buildings, ground position, single asphalt road, natural smooth sky and all details. Correct LEFT museum perspective: its entire long front top horizontal cornice must be exactly LEVEL left to right (currently tilts upward to the right); entire front facade is straight-on architectural orthographic elevation. Window heads aligned horizontal, vertical columns vertical, constant height and width across facade. Complete both end piers. Do not show roof top surface. Preserve museum's long wide proportions and roughly current average height. Do not change sports building's intentional asymmetrical physical cantilever roof shape. Do not add any road or object. Output same 3:1.

另一次尝试让生成器输出透明天空，检查发现文件没有 alpha，棋盘格被画进了图片；该稿未采用。正式资源不改写，运行时仅在初始化时计算连接图像顶部的天空遮罩，让同一世界天空透过；上方 42% 经目视确认为无建筑区，避免白云造成竖直残留。保留屋檐以下蓝玻璃和所有道路、建筑细节。纹理仍只采样一次，步长 1；不随帧重读或重算遮罩。

已实际打开 `eye-level-v27/road.png`、`road-scroll-right.png`、`flight-070.png`、`flight-140.png`、`flight-220.png`、`flight-270.png`。文博立面横平竖直、两端完整保存在长卷中，移动时逐段经过；高挑檐从下方看到，展品有广场落点；车轮与唯一柏油路相接。旧自行车道路的 4.6 高灰色立墙缩回同一地面，消除落地接缝的路高差。飞行序列先保留地景、自然移出，再从下方连续返回；角色、绳和 HUD 不切换投影。建筑仅为照片依据的玩法化重绘，非测绘复刻。

`testFlightCameraContinuity` 连跑 420 个真实物理步：同一场景变换对象保持不变、角色尺寸不变、镜头每步纵移小于 0.85 单位、飞行两梨不出画、成功落地且镜头回到地面。完整回归同时覆盖 21 种飞行输入／高度组合与 14 次死亡后立即绘制。

最终日志 `eye-level-v27/final-verification.txt`：Code Analyzer 零问题、完整冒烟测试通过；飞行序列强制绘制 91.2 FPS，五段强制绘制为 66.5 / 78.3 / 78.8 / 86.7 / 92.3 FPS（960×540）。其中测试日志的 Windows PASS 是人工确认汇总器的合成夹具，不是目标机实测。

按游戏 50 Hz 节奏的完整绘制：北湖 46.0、校园网 47.2、交通 48.5、自行车 49.6、校车 49.6 FPS。它与上述不限定刷新率的强制绘制能力分开记录，不能把 92.3 FPS 说成游戏实际显示帧率。
