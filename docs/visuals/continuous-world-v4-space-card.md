# 连续空间重构：空间卡与验证记录

日期：2026-09-09。状态：实施中，尚未通过最终验收。

## 本轮实际打开的参考

以下材料由主执行者通过 view_image 逐张打开，观察了原图像素。

- `assets/reference/liangxiang/maps/north-lake-current-crop.png`：北湖在北区西侧，教学与图书馆组团在南；不能给出精确距离。
- `assets/reference/liangxiang/derived/north-lake-working-topology.png`：红桥与白桥分离，动物区在岸边；这是工作拓扑，不是测绘。
- `assets/reference/liangxiang/core-areas/north-lake-greenery/2025-campus-update-03-north-lake-aerial.jpeg`：西岸进入的折线红桥、对岸树列、白拱桥；桥另一端完整通路仍不明确。
- 同目录 `12-north-lake-red-bridge.jpg`：桥墩在桥面下入水，双侧栏杆，人物与栏杆比例；不证明游戏高架桥的真实存在。
- 同目录 `15-graduates-tree-lined-road.jpg`：道路、树根与行人落在同一地面，树列有进深；不证明路线邻接。
- 同目录 `2025-12-12-jingyuan-geese-ducks-ice.jpg`：鹅比鸭大，岸线、树木、动物处于同一生活场景；不固定动物坐标。
- `assets/reference/liangxiang/maps/liangxiang-campus-map-current.png`：文博在文体中心／国防文化广场北侧；不能把横版路线称为现实向东。
- `assets/reference/liangxiang/derived/campus-structure-working-map.png`：校园南北分区与道路边界；不证明当前剧情章节是精确导航。
- `assets/reference/bit-campus-network-login-2026.png`：登录页面布局、控件相对位置；属于有意嵌入的超现实界面，不当作现实地形。
- `assets/reference/liangxiang/core-areas/north-li-bridge/user-north-li-bridge-reference.png`：白冠、深色翼、红横带、跨路桥面及落地桥墩；不证明攀爬路线。
- `assets/reference/landmarks/bit-museum-official-reference.jpg`：白色长方体、竖向窗列、草坪与建筑基础。
- 同目录 `bit-sports-center-official-reference.jpg`：弯曲白屋顶、玻璃幕墙、实体底座；不是悬空建筑。
- 同目录 `bit-defense-tank-aircraft-reference.jpg`：展示物在有围栏的地面展区，后方文体建筑；没有战斗语义。
- `assets/reference/transport/bit-school-bus-official-2025.png`、`bit-school-bus-awu969-2025.jpg`：大巴车身高长比例、连续深窗、白上绿下、双轴轮胎接地；当前扁长悬空平台的画法不符合参考。

## 重构骨架

入口：MATLAB 原点的地面与北湖岸边步道共用坐标。
出口：体育馆前道路与同车终点，不新增校园区域。
岸线：北湖远景水陆边界保留参考轮廓；前景路线用统一路缘、地基和明确缺口显示碰撞面，不能把画上的完整地面画成隐藏深渊。
道路：操场、路口、文博和终段使用相同地面基线；材质可换，路缘不能中断。
桥：北湖高桥为玩法虚构，桥墩落在岸边地基，桥两端接可见步道／台阶；北理桥平台和结构承重按相同坐标绘制。
校车：车轮接道路、车身高度匹配比例；车顶为可玩平台。底层道路可回收跌落玩家。终点循环应避免视野中瞬移和带走玩家。
层次：弱对比远景负责校园识别；中景岸线、建筑基础和绿化衔接；前景路缘、可碰撞桥面、角色和机关保持清楚。

真实关系仅限上述证据；弹射、高桥、网页平台、车顶跳跃均为明确游戏设计。不能把“现实一样”写成未经测绘的校园复刻。

## 初始失败项

- 已打开 v3 的北湖高桥图，x=38 两背景存在明显竖缝；高桥仅细线支撑，前景缺口被完整背景道路掩盖。
- 已打开 v3 的校车图，车身过扁且轮胎悬空，树木只用圆与线，x=218 材质突变。
- 已打开 v3 的北理桥图，平台高低不一且有断口，桥墩未落到前景地面。
- 已打开 v3 的文博图，纹理左缘硬切，前景浅蓝平台像悬空长条。

玩法基线：2026-09-09 重跑 Code Analyzer 0 问题、原有 smoke 全部通过。原有通过不覆盖完整输入旅程，新增真实循环回归中。

## 追加背景层（生成前约束）

用途：填补操场、桥后和路口的低细节空白，不改变任何碰撞、地标、道路或校园拓扑。
参考：本轮已打开的北湖林荫道照片用于树木落地关系；`assets/game/images/backgrounds/north-lake-west-painted.jpg` 已实际打开，用于笔触、绿色层次和光照风格。
生成内容：透明底的横向树列与低灌木。树根共用底线，不含建筑、道路、水面、桥、文字、动物或人物；不得新增校园事实。它仅为虚构的远景绿化连接层。
放置：图像宽高保持约 3:1，按相同世界尺度放在操场、桥后、路口与校车道路后方；角色与碰撞面均在其前方。生成后先查看 alpha、轮廓和落点，登记通过再复制到运行时目录。
