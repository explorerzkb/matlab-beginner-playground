function flushFigurePose(fig,recalibrate)
%FLUSHFIGUREPOSE Drop pending events/packets on pause, prologue or respawn.
if ~isgraphics(fig) || ~isappdata(fig,'poseSession'), return; end
session=getappdata(fig,'poseSession');
session=resetPoseSession(session,recalibrate);
setappdata(fig,'poseSession',session);
end
