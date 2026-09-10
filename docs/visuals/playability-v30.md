# v30 实玩调整与空间卡

状态：最终开发 Mac 验收通过，Windows 真人未验收；旧 dist 未更新。

本轮实际打开：用户三张游戏截图，以及 assets/reference/liangxiang/maps/liangxiang-campus-map-current.png、derived/campus-structure-working-map.png、assets/reference/bit-campus-network-login-2026.png、liangxiang/core-areas/north-li-bridge/user-north-li-bridge-reference.png；landmarks 中 bit-museum-official-reference.jpg、bit-sports-center-official-reference.jpg、bit-defense-tank-aircraft-reference.jpg；transport 中两张校车照片；现有 last-bus-handscroll-v27.png。

地图支持北区—道路—南区拓扑，不证明横版距离。桥照片支持桥墩落地、跨越纵向道路和翼状上部，不证明游戏跳跃高度。建筑照片支持文博长立面、体育馆挑檐、展品尺度；校车照片支持绿白分区、长车身及轮位，不证明发车间隔。路线、喝茶跳桥、车流密度、保护时间和终点都是玩法设置。

空间卡：原北湖和网页不改位置。北理桥仍两端接路、桥墩接地；桥下纵向交通，横向步行。撤销攀爬，桥面高度必须在普通跳跃顶点之上、喝茶顶点之下。路口左端现有茶瓶可拾取，下路不依赖茶。自行车在地面实际接触后弹飞，不把倒计时结束当空中撞击；落地点仍与食堂隔开。校园长卷两栋楼保持原位置、同一组平行方向与地平线，去除所有树，保留草坪、原道路和展品，终点右移。前景校车沿唯一柏油路行驶，背景不可碰撞。

背景编辑用内置 imagegen：precise-object-edit，编辑目标为 v27 长卷；删除所有树和树影，补回建筑／草坪，保留建筑位置、比例、挑檐、展品和路缘；自然蓝天薄云，无油画纹理。用户追加要求：天空始终有云，包括高空飞行，云连续移动、不能随切景突变。

资源记录：内置 imagegen 编辑产生 `last-bus-handscroll-v30.png`（源输出 exec-b5a3da7e-a4f3-4873-902f-825066b4b86c.png）；同一参考派生 `campus-continuation-v30.png`（exec-ab77a604-5920-4c3b-8551-26307c30e030.png），要求仅空旷草坪、原高度路缘、底部单条柏油路、自然薄云，无树无建筑；另派生 `cloud-sky-v30.png`（exec-99d68187-8216-4b59-b79a-996ad8959673.png），要求纯自然蓝天、各区域都有薄云，无地平线、无油画纹理、边缘颜色一致。三张均实际打开。所有源输出位于本次 generated_images/01a08a8d-ab87-7521-97e8-f4bce16f06c0/，运行资源位于 assets/game/images/backgrounds/。

运行时云图仅采样一次，并镜像平铺为一个静态图像对象，覆盖全部世界宽度与飞行高度，不逐帧新建云。校园延伸图在长卷后层，右缘小幅透明渐变。目视 road-scroll-right.png：原空蓝竖边已消失，路缘连续，去树后飞机、坦克和火炮可见；不宣称被树遮住的每件展品都得到测绘还原。自然薄云替换第一版几何圆块云，未改桥梁参考结构。

最终复核：实际打开 flight-070（上升、惊恐）、flight-220（高空）、flight-550（落地、无食堂）、road-scroll-right、road、scene-119 及云纹理平滑后的 flight.png。天空在这些视点都有云；900 帧测试确认世界变换不更换、纵向镜头和缩放无突变，飞行表情始终惊恐。云层支持 bilinear 的 MATLAB 版本启用平滑显示，旧版本保留原图显示。桥墩／近栏杆、北湖近栏杆及两端大 LED 像素对比通过。四条逻辑输入路线及五秒静止复活通过，见 logic-review.txt；独立复查修复了车流复位时同车道深度重叠，以及飞行落地重排校车产生跳变的问题。

完整验收见 acceptance/latest-run.txt：Code Analyzer 零问题、全部冒烟、21 组落地、五种车尾起跳、900 帧镜头及四条输入路线通过。960×540 强制五段最低 48.4 FPS，定速五段最低 40.8 FPS。前一次北湖定速 35.9 未达标，失败日志另存 first-full-performance-failure.txt；未查明波动原因，不宣称稳定 50 FPS，也不把日志中的 Windows 合成夹具 PASS 当作真实 Windows 验收。画质优化未下调原有门槛。
