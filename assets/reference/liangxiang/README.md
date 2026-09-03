# 良乡校区核心参考素材库

更新日期：2026-09-03

本目录已经从广泛采集库收缩为游戏关卡设计参考库。它的直接使用者是后续负责设计、编码和完成整款游戏的 Codex，不是 MATLAB 运行时，也不是被要求从素材开始自行写代码的学生。素材按“Codex 接下来要设计的区域”组织，不再按网页来源堆放；北湖及周边绿化、校车和体育馆—国防文化广场占主要比例。

## 从哪里开始

1. [`INDEX.md`](INDEX.md)：Codex 的强制入口，给出区域优先级、首选原图、提取目标、禁用推断和缺口。
2. [`previews/`](previews/)：四张带文件名的联系表，先看图再打开原文件。
3. [`catalog.csv`](catalog.csv)：逐文件路径、用途、体积和 SHA-256，只用于检索与完整性审计。
4. [`source-manifest.md`](source-manifest.md)：保留下来的素材来自哪里，以及能否直接复用。
5. [`spatial-structure.md`](spatial-structure.md)与 [`spatial-topology.csv`](spatial-topology.csv)：地点相邻关系和不能随意拼接的空间约束。

## 目录结构

```text
liangxiang/
├── core-areas/
│   ├── north-lake-greenery/          北湖、红白桥、亭廊、湖岸、荷花和季节
│   ├── shuttle-bus/                  校车外观、站点与公开视频封面
│   ├── gymnasium-defense-square/     体育馆及国防文化广场同框关系
│   ├── museum-center/                文博中心外观方案
│   ├── sports-field/                 南操场视觉线索
│   └── student-service-center/       学生服务中心识别标志
├── maps/                             校方平面图、学生地图和文萃楼群图
├── derived/                          本项目整理的空间结构图
└── previews/                         只用于快速浏览的联系表
```

## Codex 使用原则

Codex 先读 `INDEX.md` 选择区域和首选原图，再用 `spatial-structure.md` 检查空间关系，最后根据 `source-manifest.md` 判断素材只能参考还是可能复用。`catalog.csv` 解决“文件是否存在、在哪里、有没有变化”，不替代设计判断。

联系表和视频封面只用于检索，不应被游戏当作正式背景。正式美术应依据多张参考重新绘制，并把游戏运行时资产放进将来独立建立的 `assets/game/`，避免研究素材进入发布包。MATLAB 最终只加载 `assets/game/`，没有必要读取这套研究索引。

## 使用边界

- 公开可浏览不等于可以自由复制。除非来源清单明确写有开放许可，照片默认只作内部研究。
- 校园地图用于确认分区和相邻关系，不用于精确测距。
- 单张照片只能证明外观，不能单独证明路线。
- 有学生正脸的照片不能直接进入游戏发布版本。
- 素材库没有照片的核心区域不得用不明建筑冒充；缺口见 [`INDEX.md`](INDEX.md)。
