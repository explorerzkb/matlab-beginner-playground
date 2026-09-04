# 视觉工作区

这里保存当前规格下的目标效果图、生成提示词、MATLAB 程序化截图和检查记录。它们是设计或开发机验证证据，不会被游戏运行时读取，也不替代目标 Windows 真人验收。

视觉任务必须先执行 [`../visual-spatial-sop.md`](../visual-spatial-sop.md)。现实校园场景不能只读参考索引：执行者还必须实际打开索引点名的地图、拓扑和照片，并在检查记录中写明每份材料证明了什么。

当前材料：

- `target-gameplay-north-lake-v1.png`：第一关目标视觉预演 v1；
- `target-gameplay-north-lake-v1-prompt.md`：生成该图所用的提示词与证据边界；
- `target-gameplay-north-lake-v1-review.md`：按现行 SOP 对 v1 的复核结论。
- `target-gameplay-north-lake-v2-brief.md`：已修正空间证据链和无腿梨方向的下一版制作简报；
- `campus-network-login-source-review.md`：真实登录页截图的目视结果和运行时使用边界。
- `tropical-iced-tea-source-review.md`：用户指定冰红茶图片的目视结果、哈希、唯一视觉源约束与发布边界。
- `campus-network-fifth-round-review.md`：公告框入口、自动填表、按钮平台、掉线遮罩与可达性复核。
- `lexue-interaction-source-review.md`：两张私有乐学参考图的像素框、脱敏和使用边界；原图不在 Git 中。
- `continuous-world-round3-review.md`：第三轮车流、动物、页面布局与十张运行帧的当前复核。
- `runtime-snapshots-round3/`：MATLAB R2025b 导出的十张第三轮机制截图。
- `final-art-asset-notes.md`：最终手绘背景、官方校徽与现实参考的用途和空间边界。
- `final-visual-acceptance.md`：最终视觉阶段的逐项目视、工程验证和未完成边界。
- `runtime-snapshots-final/`：当前 MATLAB R2025b 直接导出的 12 张世界、3 张表情和 2 张界面证据。
- `continuous-world-round2-review.md` 与 `runtime-snapshots-round2/`：被后续真人试玩部分推翻的第二轮历史证据，不得作为当前验收结论。
- `runtime-scene-implementation-review.md`：四关程序绘制场景所用证据、真假分层和逐项复核；
- `runtime-snapshots/`：MATLAB R2025b 直接导出的四关 16:9 与第二关 3:2 验收截图。

只有同时拥有设计说明和复核记录、且所有硬性失败项已经关闭的版本，才可以标为“通过空间检查”。最终截图证明当前代码已经在开发机 MATLAB 中实现，但仍不等于通过 Windows 实机与真人双人验收。
