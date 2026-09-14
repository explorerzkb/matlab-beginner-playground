function testPoseFallback()
%TESTPOSEFALLBACK Default pose attempts never strand keyboard play.
cfg=inputConfig();
assert(strcmp(cfg.mode,'pose'),'The unified entry no longer defaults to pose.');

fig=figure('Visible','off'); guard=onCleanup(@() close(fig));
installInputCallbacks(fig);
setappdata(fig,'inputMode','pose');
fallbackPoseToKeyboard(fig,'synthetic camera failure');
assert(strcmp(getappdata(fig,'inputMode'),'keyboard'));
assert(strcmp(getappdata(fig,'poseError'),'synthetic camera failure'));
input=readInputSnapshot(fig,cfg);
assert(~input.poseMode && ~input.safetyPause, ...
    'Pose failure left keyboard gameplay safety-paused.');

ax=axes(fig); original=ax.YDir;
ready=runPoseCalibration(fig,ax,struct('input',cfg,'render',struct('fontName','Arial')));
assert(ready && strcmp(ax.YDir,original), ...
    'Calibration did not return cleanly after keyboard fallback.');
fprintf('POSE FALLBACK PASSED: default pose, direct keyboard recovery\n');
end
