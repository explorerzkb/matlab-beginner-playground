function cfg = poseConfig()
%POSECONFIG Experimental thresholds, in seconds/degrees/body-scale units.
% All thresholds require two-person playtesting; none are measured accuracy.
cfg.renderHz = 30;
cfg.confidence = 0.35;
cfg.calibrationSeconds = 2.5;
cfg.calibrationAngleRange = 6;
cfg.calibrationPositionRange = 0.04;
cfg.enterDegrees = 12;
cfg.exitDegrees = 6;
cfg.smoothingSeconds = 0.08;
cfg.staleSeconds = 0.18;
cfg.lossPauseSeconds = 0.60;
cfg.recoverySeconds = 1.0;
cfg.countdownSeconds = 3;
cfg.eventTTL = 0.15;
cfg.jumpHipRise = 0.045;
cfg.jumpAnkleRise = 0.035;
cfg.jumpVelocity = 0.25;
cfg.landTolerance = 0.035;
cfg.standSeconds = 0.30;
cfg.identityMaxShift = 0.22;
cfg.identityMargin = 0.08;
cfg.minimumSeparation = 0.18;
cfg.maxScaleRatio = 1.35;
cfg.cameraIndex = 1;
cfg.modelThreads = 2;
cfg.workerTimeout = 2.0;
cfg.requestHz = 30;
cfg.modelPath = '';
cfg.candidate = 'single';
end
