# 第一关目标视觉预演 v1 复核

复核日期：2026-09-03
状态：保留为探索证据，**未通过空间检查**

## 实际打开的材料

- `assets/reference/liangxiang/maps/north-lake-current-crop.png`：证明北湖、红桥入口和周边道路的大致关系；不能证明精确比例；
- `assets/reference/liangxiang/derived/north-lake-working-topology.png`：证明红桥从西侧进入湖区，并提示另一端是否连岸尚未确认；
- `assets/reference/liangxiang/core-areas/north-lake-greenery/2025-campus-update-03-north-lake-aerial.jpeg`：证明红桥至少一端与岸边相接，能观察其折线走向；
- `assets/reference/liangxiang/core-areas/north-lake-greenery/12-north-lake-red-bridge.jpg`：证明桥面、栏杆、水面和桥下立柱关系；照片裁切不能证明两端完整路线；
- `assets/reference/liangxiang/core-areas/north-lake-greenery/15-graduates-tree-lined-road.jpg`：提供校园道路、树列和人物尺度；
- `assets/reference/liangxiang/core-areas/north-lake-greenery/2025-12-12-jingyuan-geese-ducks-ice.jpg`：证明北湖动物语境，不证明动物固定位置。

## 当前图做对的部分

- 北湖水面、红色折线桥、鹅群和中文 HUD 让第一关比通用校园图更容易识别；
- 前景草土地块和短缺口基本能读出横版平台玩法；
- 两名角色颜色、胸前形状和绳的关系清楚；
- 远景校园、湖面和前景平台有初步层次。

## 未通过项

1. 红桥的岸端和桥下支撑不够明确，容易看成浮在水上的装饰；下一版至少表现一个可信的岸端、坡道／台阶或桥墩系统，并保持其为远景；
2. 画面没有清楚说明真实湖岸与虚构前景坑洞的分层关系，下一版要用景深、色值和连续岸线把两者分开；
3. 角色仍有腿和顶部叶芽，不符合最新冻结方向；下一版改为无腿、无叶的完整梨形身体；
4. 梨的轮廓和表面更接近通用吉祥物，下一版增加克制的果皮颗粒、柔和体积和更可爱的表情变化；
5. 提示词最初只引用三张外观照片，没有把地图、拓扑和航拍作为强制空间证据，这正是桥梁落点容易被忽略的原因。

## 下一版必须满足

- 实际引用地图、拓扑、航拍、红桥近景和尺度照片；
- 红桥至少一个岸端及主要支撑逻辑可见；
- 红桥明确处于不可碰撞远景，前景平台不冒充真实北湖地貌；
- 两只梨无腿、无叶、同体型，以挤压、倾斜、弹跳和表情表达运动；
- 通过 [`../visual-spatial-sop.md`](../visual-spatial-sop.md) 全部硬性检查后再标记为 v2 候选。
