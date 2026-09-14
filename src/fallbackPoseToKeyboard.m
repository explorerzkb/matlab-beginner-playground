function fallbackPoseToKeyboard(fig, reason)
%FALLBACKPOSETOKEYBOARD Release failed pose resources and keep playing.
if ~isgraphics(fig), return; end
stopFigurePose(fig);
setappdata(fig,'inputMode','keyboard');
setappdata(fig,'pressedKeys',{});
setappdata(fig,'pendingKeyPresses',{});
setappdata(fig,'poseError',char(string(reason)));
warning('matlabHi:PoseFallback', ...
    '体感不可用，已自动切换到键盘：%s',char(string(reason)));
end
