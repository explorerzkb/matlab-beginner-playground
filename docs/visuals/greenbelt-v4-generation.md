# 绿化连接层生成记录

状态：已进入运行时，像素与场景截图复核通过。工具：内置 image_gen（非 CLI／API fallback）。

风格参考已实际打开：`assets/game/images/backgrounds/north-lake-west-painted.jpg`。树木接地依据和真假分层见 `continuous-world-v4-space-card.md`。本图不包含地标，只用于远景，不能作为校园空间事实。

## 完整提示词

Create one production 2D game background layer, a wide panorama at 3:1 aspect ratio, preferably 3072 by 1024, on a genuinely transparent alpha background. Use the supplied game's painted North Lake illustration ONLY as the style reference: fine hand-painted leaf texture, muted olive, sage and deep leafy greens, warm soft daylight, elegant naturalistic storybook detail with subtle ink edges. Subject: an ordinary northern Chinese campus greenbelt, a varied continuous grouping of deciduous trees and low shrubs. No buildings, roads, water, bridges, text, logos, people, animals, objects or UI. Tree trunks must visibly meet the shared horizontal ground baseline near the bottom 5 percent; show a shallow thin fringe of rooted grass and bushes, no thick soil slab. Entire tree crowns fully contained inside the image with transparent space above; all foliage and trunks fully rendered with crisp organic transparent silhouettes, no white rectangle, no fake checkerboard, no scenic sky. Tree groups taper naturally to small shrubs with transparent margins on both sides; no cut trunks at either edge. Mix a few tall slender trees and rounded dense trees, asymmetrical crown shapes and layered dappled leaf detail, avoid repeated icon trees. This is a non-colliding background connecting existing painted game scenes, so keep low contrast and generous quiet gaps between major tree groups while retaining rich painted texture. Frontal side view, essentially orthographic, all roots on a level line.

## 首图失败与定向修订

首图：`/Users/zjh/.codex/generated_images/01a081f8-7348-7191-9cc1-0e7e0d2b97b5/exec-f11e61ca-ecf1-4782-ace9-d07f94d766eb.png`，2172×724，RGB，无 alpha。实际检查发现棋盘格被画入背景，因此未复制到运行时。

第二次仍使用内置 image_gen，精确保留绿化内容，只把背景改成游戏引擎可识别的品红色底。MATLAB 加载时做色键透明显示，原始图保持不变。

修订提示词：

Edit ONLY the background of this exact game tree panorama. Preserve all tree crowns, trunks, green foliage, shrubs, grass, outlines, dimensions, positions and painted detail exactly. Replace EVERY white/gray checkerboard pixel and all translucent-looking grid remnants, including all gaps between leaves, with a completely uniform solid pure magenta chroma-key background RGB(255,0,255), hex #FF00FF. This is deliberately an OPAQUE RGB game sprite atlas designed for the MATLAB renderer to chroma-key the solid magenta. Do NOT use transparency or a transparency checkerboard. There must be NO checkerboard anywhere, no pattern, no gradients, no shadows outside the greenbelt, just solid #FF00FF behind the unchanged greenbelt. Maintain the same 3:1 panoramic canvas and the existing root baseline and full tree silhouettes. No added elements, no text.

## 第二张源图检查

源图：`/Users/zjh/.codex/generated_images/01a081f8-7348-7191-9cc1-0e7e0d2b97b5/exec-60c04714-75b1-425a-8bca-a1943951ec3e.png`。
已实际观察生成结果像素：棋盘格消失，树冠完整、树根在共同底线，没有建筑、文字、人物、水面或新增地标。细节与北湖绘制背景一致。通过作为虚构远景绿化的空间检查；品红色为引擎色键，不属于场景。已实际打开桥边、路口、文博过渡和校车段运行时截图，未见棋盘格、品红背景或明显品红边缘；树根接地，未新增碰撞障碍。此项通过不替代目标 Windows 的整体视觉验收。

选定运行时路径：`assets/game/images/backgrounds/campus-greenbelt-v4.png`。复制原图，不覆盖旧背景，也不删除生成源文件。
