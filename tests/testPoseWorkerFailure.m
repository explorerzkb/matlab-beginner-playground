function testPoseWorkerFailure()
%TESTPOSEWORKERFAILURE Real process cancellation releases input and camera.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig(); cfg.modelPath=fullfile(root,'assets','game','models','movenet-single-lightning.tflite');
s=startPoseSession(cfg);
guard=onCleanup(@() stopPoseSession(s)); clock=tic;
while s.packets<3 && toc(clock)<60
    s=pollPoseSession(s,poseClock());
    assert(isempty(s.error),'%s',s.error); pause(.01);
end
assert(s.packets>=3,'Camera worker did not become ready');
cancel(s.future);
clock=tic;
while isempty(s.error) && toc(clock)<10
    s=pollPoseSession(s,poseClock()); pause(.01);
end
assert(~isempty(s.error),'Cancelled worker was not detected');
fig=figure('Visible','off'); figGuard=onCleanup(@() delete(fig));
setappdata(fig,'poseSession',s); setappdata(fig,'inputMode','pose');
input=readFigurePose(fig,poseClock(),true,true);
assert(input.safetyPause && ~any([input.player.jump input.player.left input.player.right]));
input=readInputSnapshot(fig,inputConfig());
assert(input.safetyPause && ~isappdata(fig,'poseSession'));
assert(~isempty(getappdata(fig,'poseError')));
clear figGuard guard;
camera=webcam(cfg.cameraIndex); snapshot(camera); clear camera;
fprintf('WORKER CANCELLATION / SAFE RELEASE / CAMERA REOPEN PASSED\n');
end
