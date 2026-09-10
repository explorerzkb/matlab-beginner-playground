# 连续校园世界 v3 视觉与空间复核

复核日期：2026-09-04
结论：本轮画面通过开发机视觉门槛；目标 Windows 真人验收仍未完成

## 实际打开的现实材料

- `assets/reference/liangxiang/maps/liangxiang-campus-map-current.png`
  - 证明：文博中心位于国防文化主题广场／体育馆片区北侧，二者处于校园图同一东侧片区。
  - 不能证明：游戏中的精确校车线路、距离和屏幕向右对应现实哪个方位。
- `assets/reference/liangxiang/core-areas/north-li-bridge/user-north-li-bridge-reference.png`
  - 证明：名称是“北理桥”，正面可见道路跨越、桥墩、白色曲面、深色翼状结构和红色横带。
  - 不能证明：完整桥面通行、精确尺寸或游戏攀爬路线。
- `assets/reference/transport/bit-school-bus-official-2025.png`
  - 证明：绿白长途大巴的完整侧面比例、连续深色车窗和前后轮布局。
- `assets/reference/transport/bit-school-bus-awu969-2025.jpg`
  - 证明：绿白大巴的前侧透视、挡风玻璃和车身分区。
  - 两张校车照片都不能证明固定线路或车辆数量；运行时只做原创程序化概括，没有复制车牌、乘客和照片背景。
- `assets/reference/landmarks/bit-museum-official-reference.jpg`
  - 证明：文博中心白色长矩形体量、垂直列阵和草坪关系。
- `assets/reference/landmarks/bit-sports-center-official-reference.jpg`
  - 证明：体育馆弧形白屋顶和玻璃幕墙。
- `assets/reference/landmarks/bit-defense-tank-aircraft-reference.jpg`
  - 证明：体育馆背景附近存在围栏内的公开飞机、坦克展示。
  - 三张地标照片不能单独证明彼此邻接；邻接判断只来自校园图。
- 用户提供的校园网登录、Chrome 超时和登录完成页面
  - 证明：三种完整页面的目标像素内容和控件位置。
  - 不能证明：游戏进行了真实联网或图中的账户状态适合公开。运行时成功页已脱敏。

## 空间卡

- 北湖：下层地面有实体鸭鹅；羊驼右后方触发后踢进入同高红桥；孔雀在下层提供回桥弹射。
- 校园网：登录、超时、加载和成功共用同一个固定世界矩形；第一次超时撤掉承托，第二次成功后用操场地面连接右侧道路。
- 北理桥：上路四次攀爬、下路红绿灯，两路在北食堂／徐特立图书馆附近汇合。
- 自行车：汇合后的剧情机关把双梨向右上发射；纵向镜头随飞行抬升，文博中心提供宽阔落点。
- 文博—体育馆：地图上的“文博在北、体育馆／国防文化广场在南”用方位牌明确表达；校车把这层关系压平成横向移动平台路线。
- 终点：体育馆是最后一个区域，双梨必须站在同一辆校车上进入终点区。
- 前景碰撞层：地面、网页承托、桥平台、动物、车辆、校车和路灯。
- 远景层：北湖、文博、国防文化广场和体育馆画面；远景照片化板块不直接承担碰撞。

## 运行截图复核

目录：`docs/visuals/runtime-snapshots-world-v3/`

- `origin.png`：像素爱心、圆润黄绿色／暖白双梨和北湖入口三瓶冰红茶可读。
- `north-lake-animals.png`：鸭鹅与玩家处于同一地面和碰撞尺度。
- `north-lake-shortcut.png`：羊驼面向左，右后方后踢、高桥和孔雀回收路线可同时理解。
- `network-login.png`、`network-timeout.png`、`network-loading.png`、`network-success.png`：四种页面共用固定外框；成功截图同时看到页面左侧和右侧操场，能证明没有淡化或全屏切关。
- `north-li-bridge-climb.png`、`north-li-bridge-signal.png`：北理桥名称、上路平台、道路跨越和下路信号可读。
- `bicycle-warning.png`：北食堂／徐特立图书馆路口和混流预告可读。
- `bicycle-flight.png`：双梨在高空向右上飞，纵向镜头抬升且文博落点已进入画面。
- `museum-landing.png`：文博中心宽阔安全落点可读。
- `museum-sports-map.png`：文博中心在北、国防文化广场／体育馆在南的连通关系被明确写出。
- `campus-bus-lamps.png`：绿白校车作为承载平台，双臂路灯横杆与跳跃角色形成清楚碰撞关系。
- `sports-center-finish.png`：体育馆建筑、同车双梨和终点区同时出现，路线不再向后延伸。

补充目录：

- `runtime-snapshots-health-v3/`：满心／一心、两瓶冰红茶、空／有值六格绳力条；
- `runtime-snapshots-network-v6/`：校园网页面四态近景；
- `runtime-snapshots-pear-v3/`：跳跃、受击和绳索吃力表情。

## 审计边界

以下属于本轮必须关闭的硬问题，现已关闭：页面主动消失或锁镜头、桥名错误、鸭鹅无实体、飞行时角色出画、冰红茶影响血量、体育馆后仍有尾段、未授权账户状态进入运行时。

以下属于后续可选精修，不阻塞本轮结束：北理桥更写实的比例、校车更丰富的车身细节、局部标签在特定镜头边缘的裁切。它们不改变碰撞、路线和主要识别锚点。

目标 Windows 真人双人试玩仍是最终交付硬门槛；本文件只记录开发机画面和空间关系。
