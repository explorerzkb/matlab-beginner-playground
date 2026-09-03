# 视觉工作区

这里保存当前规格下的目标效果图、生成提示词和检查记录。它们是设计证据，不是 MATLAB 实机截图，也不会被游戏运行时读取。

视觉任务必须先执行 [`../visual-spatial-sop.md`](../visual-spatial-sop.md)。现实校园场景不能只读参考索引：执行者还必须实际打开索引点名的地图、拓扑和照片，并在检查记录中写明每份材料证明了什么。

当前材料：

- `target-gameplay-north-lake-v1.png`：第一关目标视觉预演 v1；
- `target-gameplay-north-lake-v1-prompt.md`：生成该图所用的提示词与证据边界；
- `target-gameplay-north-lake-v1-review.md`：按现行 SOP 对 v1 的复核结论。
- `target-gameplay-north-lake-v2-brief.md`：已修正空间证据链和无腿梨方向的下一版制作简报；
- `campus-network-login-source-review.md`：真实登录页截图的目视结果和运行时使用边界。
- `runtime-scene-implementation-review.md`：四关程序绘制场景所用证据、真假分层和逐项复核；
- `runtime-snapshots/`：MATLAB R2025b 直接导出的四关 16:9 与第二关 3:2 验收截图。

只有同时拥有设计说明和复核记录、且所有硬性失败项已经关闭的版本，才可以标为“通过空间检查”。通过空间检查仍不等于已经在 MATLAB 中实现或通过 Windows 实机验证。
