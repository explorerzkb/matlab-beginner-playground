function stopFigurePose(fig)
%STOPFIGUREPOSE Remove stored session before cleanup, including error paths.
if ~isgraphics(fig) || ~isappdata(fig,'poseSession'), return; end
session=getappdata(fig,'poseSession');
rmappdata(fig,'poseSession');
savePoseTelemetry(session);
stopPoseSession(session);
end
