function testPoseCalibrationExit()
%TESTPOSECALIBRATIONEXIT Mirrored camera coordinates must not invert the game.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'),fullfile(root,'levels'));
cfg=gameConfig(root); cfg.pose=poseConfig();
fig=figure('Visible','off'); guard=onCleanup(@() delete(fig)); ax=axes(fig);
installInputCallbacks(fig);
setappdata(fig,'inputMode','pose'); setappdata(fig,'pressedKeys',{'k'});
ready=runPoseCalibration(fig,ax,cfg);
assert(ready && strcmp(getappdata(fig,'inputMode'),'keyboard'));
assert(strcmp(ax.YDir,'normal'),'Camera image coordinates leaked into game');
level=continuousCampusWorld(); state=createInitialState(level,cfg,[]);
state=stepLevel(state,level,cfg,0); state=renderFrame(fig,ax,state,level,cfg);
assert(state.render.initialized && strcmp(ax.YDir,'normal'));
clear guard;
fprintf('CALIBRATION EXIT PASSED: keyboard switch and upright game coordinates\n');
end
