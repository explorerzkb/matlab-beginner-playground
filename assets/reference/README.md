# 当前连续世界参考素材

这里保存仍会影响当前连续校园世界的研究输入。MATLAB 运行时不得读取本目录；正式图像和音频必须经过提炼后放入 `assets/game/`。

## 当前保留内容

- [`bit-campus-network-login-2026.png`](bit-campus-network-login-2026.png)：固定世界校园网页面的真实视觉锚点；
- [`liangxiang/INDEX.md`](liangxiang/INDEX.md)：北湖、北理桥、文博—体育馆所需的地图、照片和空间边界。
- [`liangxiang/core-areas/north-li-bridge/user-north-li-bridge-reference.png`](liangxiang/core-areas/north-li-bridge/user-north-li-bridge-reference.png)：用户指定的北理桥正面道路照片，负责校正桥名和外形识别点，不证明完整路线。
- [`identity/README.md`](identity/README.md)：官方校徽与标志比例、色彩和留白规范。
- [`landmarks/README.md`](landmarks/README.md)：文博馆、良乡文化体育中心与教育展示物外观证据；这些材料不自动证明空间邻接。
- [`transport/README.md`](transport/README.md)：用户指定的两张北理工校车照片、来源、哈希、授权边界与可提炼的造型信息。

冰红茶原图直接保存在正式运行时目录 [`../game/images/items/tropical-iced-tea.jpg`](../game/images/items/tropical-iced-tea.jpg)，来源、哈希与使用边界见同目录 README；不得从本参考区或历史区另找替代图片。

## 使用规则

- 先读索引，再**实际打开并目视检查**它为当前关卡列出的文件；只读文件名、索引摘要或提示词不算使用了参考；
- 视觉任务必须执行 [`../../docs/visual-spatial-sop.md`](../../docs/visual-spatial-sop.md)，并在 `docs/visuals/` 记录打开过的路径、每份材料证明和不能证明的内容；
- 照片默认只作内部重绘参考，公开可见不等于允许复制发布；
- 单张照片只证明外观，不证明路线或邻接；
- 校园网登录页是明确例外：当前世界直接使用仓库中的真实截图，不让模型重画；进入 `assets/game/` 前和发布前分别目视检查账号、密码和个人信息；
- 不让 `startGame.m`、关卡加载器或资源扫描器访问 `assets/reference/` 或 `archive/`。

旧索引与历史方案仍封存在 `archive/snapshots/2026-09-03-preimplementation/`，默认不得读取。文博、体育馆、国防教育展示和校车只使用当前目录中已核验的参考，不从历史方案恢复空间关系。
