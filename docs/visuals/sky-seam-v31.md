# 北湖天空接缝修复

日期：2026-09-11。状态：开发 Mac 画面复核通过。

用户截图中背景上沿是一条硬边：北湖图带浅蓝天空，背后全局云图偏深蓝；旧代码只将左右边缘合成到固定浅蓝色，没有处理上沿。

本轮在 `src/drawContinuousBackground.m` 初始化时按世界坐标采样实际云图，将北湖顶部 16% 平滑衔接到云层。东西背景重叠处采样已经合成的西段，避免用固定底色覆盖相邻背景。合成后仍是不透明 RGB，不增加逐帧透明图层。插值只处理覆盖窗口，纹理采样步长未变。

## 实际打开的材料与空间卡

本轮逐份打开了 `assets/reference/liangxiang/` 下的六份必看材料：

- `maps/north-lake-current-crop.png`：北湖周边分区；不能证明游戏尺度。
- `derived/north-lake-working-topology.png`：区分红桥、白桥、动物区；不能作为测绘图。
- `core-areas/north-lake-greenery/2025-campus-update-03-north-lake-aerial.jpeg`：湖岸、水面、桥和树列关系；不能证明动物位置。
- `core-areas/north-lake-greenery/12-north-lake-red-bridge.jpg`：栏杆、桥面、支柱入水和远岸建筑；不能证明桥另一端完整通路。
- `core-areas/north-lake-greenery/15-graduates-tree-lined-road.jpg`：树列、道路与人尺度；不能证明和桥的邻接。
- `core-areas/north-lake-greenery/2025-12-12-jingyuan-geese-ducks-ice.jpg`：校园水禽与岸边环境；冬季状态不用于当前暖季画面。

另打开了用户截图、运行时 `north-lake-west-extended-v5.png` 与 `north-lake-east-painted.jpg`。入口仍承接 MATLAB 序章，出口仍接固定校园网页；湖岸、水面、远景建筑保持现有图像。前景红桥、支柱、地面与动物碰撞是游戏空间，未新增现实邻接或精确尺寸判断。本轮不移动道路、桥端、桥墩或地基。

## 画面与验证

- `sky-seam-v31/north-lake-shortcut.png`：实际打开，红桥、树列和建筑未被顶部融合遮掉。
- `sky-seam-v31/elevated-1.png`、`elevated-2.png`、`elevated-3.png`：实际逐张打开。镜头中心 x=55，y=8.5、11、17，原顶部横线已消除，云层保持世界坐标连续。这三张是固定相机检查图，HUD 地区仍沿用初始状态，不是完整真人游戏轨迹。
- Code Analyzer：零问题。
- 960×540 五段强制绘制：北湖 43.3、校园网 86.6、交通 47.0、自行车 65.0、校园 54.2 FPS，均严格大于 40。未重测定速刷新和 Windows。
- 首轮冒烟在并行交通修改期间失败：`testTrafficCars` 已读取 `roadRenderY`，该进程缓存的旧世界结构没有该字段；磁盘关卡文件已存在该字段。保留原日志；新进程完整复测已输出 `ALL MATLAB SMOKE TESTS PASSED`。其中独立飞行连续性检查记录 38.3 forced render FPS，不能把五段检查的通过外推成所有飞行负载稳定大于 40。

天空色调和云的风格仍有渐变，本轮解决的是截图中的矩形硬边。未宣称照片级统一天空或目标 Windows 已通过。
