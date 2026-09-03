# 良乡校园新增视觉锚点参考

更新日期：2026-09-04

本目录保存最终美术阶段的真实校园参考，仍然是设计研究输入，不是运行时资产。它们用于确认建筑与展示物的外观，不能独立证明建筑与其他场景的邻接、出入口、道路连接或玩家空间。

| 文件 | 参考来源 | 能证明 | 不能证明 |
| --- | --- | --- | --- |
| `bit-museum-official-reference.jpg` | 北京理工大学官方文章 `https://www.bit.edu.cn/xww/lgxb21/cd4f1cc05c764a8887501248a2f7febe.htm` | 文博馆主体的白色石材、长矩形体量、垂直列阵与草坪 | 与北湖、文体中心或游戏道路的直接相邻关系 |
| `bit-museum-official-article-reference.jpg` | 同上 | 另一篇官方页面中的文博馆外观核验 | 入口落点和玩家通路 |
| `bit-museum-interior-reference.png` | 同上 | 参观与展览性质 | 代表性展品的完整或永久陈列位置 |
| `bit-sports-center-official-reference.jpg` | 北京理工大学官方图库 `https://bit.edu.cn/tkpt/xwy/a169670.htm` | 良乡文化体育中心的双曲面屋顶、白色主体与玻璃幕墙 | 其他建筑的相对位置 |
| `bit-defense-tank-aircraft-reference.jpg` | 北京房山／北京日报 2026-03-25 `https://xinwen.bjd.com.cn/content/s69c3aee4d5dedd6a22f5af99.html` | 公开展示区中可见飞机、坦克与围栏、建筑背景的基本关系 | 设备型号、永久数量与游戏路线的核验 |

使用边界：

- 文博馆与文化体育中心必须作为不同校园锚点；未经地图或照片核验，不能把它们拼成一条现实的连续走廊。
- 坦克与飞机只作为校园公共教育展示，不做战斗、枪口、烟火或枪战美术。
- 生成式背景只能从上述图片核验外观，生成物不能反过来作为校园事实证据。
- 运行时资源必须单独保存到 `assets/game/`，并在 `docs/visuals/` 记录生成/重绘过程和审核结果。
