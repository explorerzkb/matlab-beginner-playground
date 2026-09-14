function report = runPosePipelineCheck(modelPath, samplePath, useCamera)
%RUNPOSEPIPELINECHECK Actual process pipeline, bounded queue and cleanup.
if nargin<3, useCamera=false; end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig(); cfg.modelPath=modelPath;
fixture=[];
if ~useCamera
    source=imread(samplePath); fixture=[source source];
end
session=startPoseSession(cfg,fixture);
guard=onCleanup(@() stopPoseSession(session));
clock=tic; durations=[]; packets=0; samples=[];
while toc(clock)<60 && packets<100
    t=tic; session=pollPoseSession(session,poseClock()); durations(end+1)=toc(t); %#ok<AGROW>
    assert(isempty(session.error),'matlabHi:PipelineError','%s',session.error);
    if session.packets>packets
        p=session.lastPacket; packets=session.packets;
        samples(end+1,:)=[p.captureTime p.acquiredTime p.readyTime poseClock()]; %#ok<AGROW>
    end
    assert(session.results.QueueLength<=1,'Frame results accumulated');
    pause(0.005);
end
assert(packets>=20,'Not enough real worker results');
report=struct('useCamera',useCamera,'packets',packets,'samples',samples, ...
    'pollMedianMs',1000*median(durations),'pollMaxMs',1000*max(durations));
report.updateHz=(packets-1)/(samples(end,1)-samples(1,1));
report.captureToConsumerMedianMs=1000*median(samples(:,4)-samples(:,1));
fprintf('PROCESS PIPELINE: %.2f paired updates/s, %.1f ms capture-call-to-consumer; poll %.3f median / %.3f max ms\n', ...
    report.updateHz,report.captureToConsumerMedianMs,report.pollMedianMs,report.pollMaxMs);
save(fullfile(root,'docs','validation','pose-control',sprintf('pipeline-camera-%d.mat',useCamera)),'report');
clear guard;
if useCamera
    camera=webcam(cfg.cameraIndex); snapshot(camera); clear camera;
    fprintf('CAMERA REOPEN AFTER WORKER SHUTDOWN PASSED\n');
end
fprintf('BOUNDED QUEUE AND CLEANUP PASSED; not exposure-to-screen latency.\n');
end
