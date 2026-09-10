# 北理桥左侧路标

日期：2026-09-11。范围：只增加游戏引导牌，不重绘校园。

已实际打开 `assets/reference/liangxiang/` 下的 `maps/liangxiang-campus-map-current.png`、`derived/campus-structure-working-map.png`、`core-areas/north-li-bridge/user-north-li-bridge-reference.png`，以及 `assets/reference/bit-campus-network-login-2026.png`。地图支持分区，拓扑仅为工作关系图；桥照片可见白色双翼、红带与落地桥墩，不能证明精确尺寸、完整桥端路线或路标；登录图支持已有操场页面外观，与路标无关。

空间卡：入口为现有跑道右端，出口为右侧桥面或地面路口。桥面保持 y6.5；桥墩、车道、碰撞均沿用。路标位于桥左侧 x110.1—116.1，立柱落到 y1 地面，纯装饰无碰撞；右上箭头指向桥左端，牌面高于角色地面站立区。这里没有岸线，路标位置和尺寸是玩法设计，不宣称现实存在。

已打开 `bridge-jump-sign/north-li-bridge-entry.png`、`north-li-bridge-climb.png` 和 `north-li-bridge-signal.png`。入口画面黄底深字清楚，箭头朝右上桥端，立柱接地，未遮挡双梨、冰红茶或行人灯；走上桥后牌子随世界镜头自然离开左侧。入口图为直接摆位的渲染检查，HUD 仍保留初始区状态，不作为完整实玩证据。Code Analyzer 零问题，`git diff --check` 通过。此次只验引导牌，未复测 Windows。


追加修订：用户要求小一点、融入环境。最终牌面为 3.8×1.35（原 6×2.15），范围 x111.2—115.0、y3.65—5.0，灰绿底与米白字，细立柱仍接 y1。已实际打开 `bridge-jump-sign/north-li-bridge-entry-small.png`，提示可读，角色、道路和信号灯均无遮挡。此图取代黄色大牌作为最终效果；跳跃和碰撞不变。


位置纠正：此前只检查字和角色遮挡，漏查了牌面跨越场景交界，不应把前次截图写成布局通过。现牌面移至 x112.5—116.3、y3.1—4.45，完整位于公路 x112 右侧及上沿 y4.7 下方，两方向均留空隙。立柱 x114.4 接地。最终截图改为 `bridge-jump-sign/north-li-bridge-entry-roadside.png`，前两版仅保留为修订证据。
