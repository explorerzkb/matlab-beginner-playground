# Codex 核心区域检索与设计索引

更新日期：2026-09-03

本文件的读者是后续负责把 MATLAB 游戏设计并实现完成的 Codex。目标不是让 MATLAB“理解校园”，也不是给学生布置从素材开始写代码的任务，而是减少 Codex 再次搜索、误认建筑和把校园照片胡乱拼接的成本。

使用参考库时，必须区分三类工作：地图和结构图回答“地点怎样连接”；原始照片回答“它长什么样”；联系表只帮助快速找到原图。正式游戏不能直接加载联系表、视频封面或整套研究照片。

## 当前覆盖

| 区域 | 本地原始素材 | 快速预览 | 当前可支撑的设计判断 |
|---|---:|---|---|
| 北湖及周边绿化 | 28 | [`north-lake-greenery.jpg`](previews/north-lake-greenery.jpg) | 强覆盖。包含湖面、红桥、白桥、亭廊、文化步道、思源榭区域、荷花、锦鲤、动物区和雨雪秋景。 |
| 校车 | 11 | [`shuttle-bus.jpg`](previews/shuttle-bus.jpg) | 强覆盖。包含校车车型、站点、跨校区语境、夜间和“末班车”视觉。视频封面不证明实际线路。 |
| 体育馆—国防文化广场 | 4 | [`buildings-services-field.jpg`](previews/buildings-services-field.jpg) | 中强覆盖。包含两个地面角度、夜景和航拍同框，可确认体育馆与装备带相邻。 |
| 文博中心 | 1 | 同上 | 仅保留一张正立面设计效果图，可提取轮廓，不能证明 2026 年建成状态。 |
| 南操场 | 1 | 同上 | 只有足球视频封面；校园网登录截图还能提供操场和看台背景，但仍缺少干净全景。 |
| 学生服务中心 | 1 | 同上 | 只保留识别标志，可用于招牌设计；缺少建筑外观。 |
| 文萃楼群 | 2 张专用地图 | [`maps.jpg`](previews/maps.jpg) | 能确认 A—M 楼和内部连接，缺少可靠的当前外观照片。 |
| 综合教学楼 | 校园地图覆盖 | [`maps.jpg`](previews/maps.jpg) | 能确认相对位置，缺少可靠的正立面、侧立面和入口照片。 |
| 东食堂、北食堂 | 校园地图覆盖 | [`maps.jpg`](previews/maps.jpg) | 能确认相对位置，缺少能够明确对应两座食堂的外观照片。 |
| 理科教学楼 | 校园地图覆盖 | [`maps.jpg`](previews/maps.jpg) | 能确认南区位置，缺少可靠外观照片。 |

## 可以直接开工的素材包

### 北湖场景

先打开以下六份，而不是把 28 张照片全部塞进上下文：

1. `maps/north-lake-current-crop.png`：确认北湖与周边组团；
2. `derived/north-lake-working-topology.png`：区分白桥、红桥、亭廊、思源榭和动物区域；
3. `core-areas/north-lake-greenery/2025-campus-update-03-north-lake-aerial.jpeg`：提取湖岸总体轮廓和植被比例；
4. `core-areas/north-lake-greenery/14-north-lake-bridge-pavilion.jpg`：提取白桥、深色亭廊、荷叶和近岸层次；
5. `core-areas/north-lake-greenery/12-north-lake-red-bridge.jpg`：提取红桥折线轮廓与水面关系；
6. `core-areas/north-lake-greenery/15-graduates-tree-lined-road.jpg`：提取适合横版移动的树列、道路宽度和学生尺度。

场景必须一屏一个主要视觉锚点。不能把白桥、红桥、亭廊、思源榭、动物区和荷花同时堆在一屏，再声称这是北湖复刻。

### 校车事件

先打开 `core-areas/shuttle-bus/2023-bit-shuttle-official-english-site.jpg` 和 `2021-shuttle-station-wikimedia.jpg` 获取车辆比例、车身标志和道路尺度，再看 `2024-06-28-rainbow-bus-BV1xJ4m1u7Jw.jpg` 与 `2025-06-30-last-shuttle-BV1ZHgfzBEbc.jpg` 理解学生熟悉的跨校区、赶车和末班车语境。其余 Bilibili 图片只是视频封面，不得当作线路或站点证据。

### 体育馆—国防文化广场

先用 `maps/culture-sports-defense-current-crop.png` 判断组团，再同时比较 `2025-campus-update-12-gym-defense-square-aerial.jpeg` 和 `2025-2026-defense-square-gym-night-student-view.webp`。前者回答总体相邻关系，后者回答学生视角下能看到什么；`2025-02-12-gymnasium.jpg` 负责体育馆外轮廓。

### 文萃、综教、食堂、理教和学生服务中心

这些区域目前不能直接进入正式美术生产。文萃只有两张楼群地图；综教、东食堂、北食堂和理教只有校园总图位置；学生服务中心只有标志。Codex 应先补齐 `下一轮只补这些缺口` 中的证据，不能为了推进任务把普通白楼、宿舍或不明活动场地改名冒充。

## Codex 调用顺序

1. 从本文件选择一个场景包，不同时打开所有区域。
2. 先看该区域的地图或结构图，确定主地标、相邻地标、入口和出口。
3. 再打开本文件列出的首选原图，提取轮廓、色彩、材质、尺度和生活气氛。
4. 用 [`spatial-structure.md`](spatial-structure.md)检查场景连接，未知关系继续标成未知。
5. 用 [`source-manifest.md`](source-manifest.md)检查来源与复用限制。
6. 制作原创、轻量的正式游戏资产并保存到 `assets/game/`；不要让 MATLAB 扫描 `assets/reference/`。

[`catalog.csv`](catalog.csv)只在需要批量检查路径、尺寸和哈希时使用。它是审计清单，不是玩法设计接口，也不是要求 MATLAB 在游戏运行时读取的数据文件。

## 禁止的省事方式

- 不因文件名含有 `campus` 就认定它属于某个核心建筑；
- 不用单张照片推断真实路线；
- 不直接把含学生正脸、网页水印或活动布景的参考图打包进游戏；
- 不把 2022 年文博中心效果图描述成已经核实的 2026 年实景；
- 不把视频封面描述成校车时刻、路线或站点的可靠证据；
- 不为了“素材都用上”而让场景重新变成校园元素陈列柜。

## 下一轮只补这些缺口

1. 综合教学楼 A/B 的可识别外观与连接关系；
2. 文萃楼群的地面入口、连廊和门牌；
3. 东食堂、北食堂各自的正立面及其与道路的关系；
4. 理科教学楼的正立面、入口和南区道路；
5. 学生服务中心建筑外观；
6. 南操场无人物遮挡的全景。

新增素材必须补充上述缺口，或者为现有核心区域提供新的结构视角；普通室内、食物、宿舍、社团活动和无法定位的校园美图不再纳入。
