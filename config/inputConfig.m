function input = inputConfig()
%INPUTCONFIG All keyboard mappings and their on-screen labels.

input.player1.left = 'a';
input.player1.right = 'd';
input.player1.jump = 'w';
input.player1.label = '玩家一：A / D 移动，W 跳跃';

input.player2.left = 'leftarrow';
input.player2.right = 'rightarrow';
input.player2.jump = 'uparrow';
input.player2.label = '玩家二：方向键移动与跳跃';

input.player2Alternate.left = 'j';
input.player2Alternate.right = 'l';
input.player2Alternate.jump = 'i';
input.player2Alternate.label = '备用：J / L 移动，I 跳跃';

input.pause = 'escape';
input.reset = 'r';
input.quit = 'q';
input.useItem = 'space';
input.useItemLabel = '全局道具：长按 Space 饮用破防水';
end
