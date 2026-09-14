function testPosePerformanceProfile()
%TESTPOSEPERFORMANCEPROFILE Pose spends texture detail to protect frame pacing.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=gameConfig(root); cfg.pose=poseConfig();
cfg.input.mode='pose'; cfg=configureInputPerformance(cfg);
assert(cfg.render.targetHz==30);
assert(cfg.render.backgroundTextureStride==6);
assert(cfg.render.campusHandscrollTextureStride==2);

cfg=gameConfig(root); cfg.pose=poseConfig(); cfg.input.mode='keyboard';
cfg=configureInputPerformance(cfg);
assert(cfg.render.targetHz==50 && cfg.render.campusHandscrollTextureStride==1);
fprintf('POSE PERFORMANCE PROFILE PASSED: 30 Hz with reduced background cost\n');
end
