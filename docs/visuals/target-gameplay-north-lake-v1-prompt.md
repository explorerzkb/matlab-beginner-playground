# 第一关目标运行效果图生成提示词

状态：已执行的 v1 记录，禁止原样复用。它保留了当时的生成输入，其中“短四肢、叶芽”和空间证据不足已经被现行规格撤销；下一版使用 `target-gameplay-north-lake-v2-brief.md` 与 [`../visual-spatial-sop.md`](../visual-spatial-sop.md)。

生成方式：Codex 内置 `image_gen`。

参考图：

1. `assets/reference/liangxiang/core-areas/north-lake-greenery/12-north-lake-red-bridge.jpg`
2. `assets/reference/liangxiang/core-areas/north-lake-greenery/15-graduates-tree-lined-road.jpg`
3. `assets/reference/liangxiang/core-areas/north-lake-greenery/2025-12-12-jingyuan-geese-ducks-ice.jpg`

```text
Use case: stylized-concept
Asset type: final in-game runtime screenshot for a MATLAB 2D cooperative platform game, landscape 16:9, shippable-game fidelity rather than loose concept art
Input images: Image 1 is a visual reference for the recognizable red bridge and lake relationship at Beijing Institute of Technology Liangxiang North Lake; Image 2 is a reference for the tree-lined campus road scale and greenery; Image 3 is a reference only for natural white goose shapes and the campus animal context. Repaint everything as original flat game art; do not copy any people or photograph pixels.

Primary request: show one authentic gameplay moment from Level 1, “北湖动物借道”, as it would appear inside the final MATLAB figure window. This is a side-scrolling 2D platformer for two students sharing one keyboard.
Scene/backdrop: a readable side-view lakeside path at North Lake in clear daytime, with lake water and the red zigzag bridge as the single distant landmark, a tree line and only faint simplified campus buildings far behind. The playable foreground is a compressed fictional route, not a literal campus reconstruction.
Subjects: two original pear-shaped creatures of exactly the same size and body proportions. Both have narrow tops, rounded bottoms, very short arms and legs, dot eyes, a simple mouth line, bold dark outlines, and clearly visible metal-like waist connection rings. Player 1 is warm pear-yellow/amber with a solid circular chest badge. Player 2 is lake-cyan with a solid diamond chest badge. They must look equal in ability, not male/female variants. A normal dark rope connects only the two waist rings. Show the rope nearly taut with a small natural sag: the yellow character is planted on a stable platform while the cyan character is mid-jump across a short safe gap, visibly being supported by rope tension. Ahead, a small line of three white geese steadily crosses the path as a moving boundary, not attacking.
Gameplay geometry: broad grass-and-path platforms with crisp collision edges, one short shallow fall zone, a nearby checkpoint marker behind the players, and a clear rightward exit marker that requires both players. Make all platform edges immediately readable.
MATLAB visual language: integrate a subtle pale Cartesian grid in the world, sparse axis ticks at the bottom and left, small colored data-point markers, and one thin plotted curve embedded into the terrain. These should feel like actual MATLAB graphics blended with campus comic art, not floating equations or source code.
UI: practical minimal HUD. At top left render the exact Chinese text “第一关 · 北湖动物借道”. Under it, two small control chips: “P1  A D W” in amber and “P2  ← → ↑” in cyan. At top right, small unobtrusive labels “Esc 暂停” and “R 长按重来”. No other text.
Style/medium: polished 2D flat campus-comic illustration with restrained shadows, clean dark outlines, limited solid colors, modest texture, feasible for MATLAB patch/image rendering. Screenshot-like, crisp, playful but not childish, visually closer to a finished indie game than promotional key art.
Composition/framing: orthographic side view, one-screen gameplay screenshot, characters occupy about 12 percent of frame height, enough surrounding space to understand platforms, rope, geese, checkpoint and exit. Keep the ground and gameplay readable at a glance.
Color palette: warm summer greens, lake blue-green, red bridge accent, off-white UI, amber player 1, lake-cyan player 2.
Constraints: faithfully reflect the frozen game specification; equal characters; rope connects waist rings only; no enemies, no weapons, no combat, no health bars, no coins, no inventory, no mobile controls, no dialogue box, no third player, no photorealistic humans, no MATLAB code editor, no browser UI, no real login form, no logos, no watermark.
```

## 证据边界

这是一张依据冻结规格和内部参考资料生成的目标效果图，不是 MATLAB 实机截图，也不能证明代码、碰撞、帧率或 Windows 兼容性已经实现和验证。
