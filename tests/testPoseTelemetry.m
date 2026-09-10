function testPoseTelemetry()
%TESTPOSETELEMETRY Distinct camera/pose/render counts and no stale latency reuse.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig();
packet=struct('captureTime',10,'requestId',1,'points',nan(17,3,2),'imageSize',[480 640 3]);
t=poseTelemetry([],'packet',10.08,struct('packet',packet,'cfg',cfg));
assert(t.packets==1 && t.inferenceCalls==2 && all(t.validUpdates==0));
t=poseTelemetry(t,'scene',10.08,struct('centre',26,'active',true,'elapsed',.1));
t=poseTelemetry(t,'physics',10.09,packet);
t=poseTelemetry(t,'physics',10.10,packet);
t=poseTelemetry(t,'render',10.12,[]);
t=poseTelemetry(t,'render',10.18,[]);
assert(t.scene(1).steps==2 && t.scene(1).frames==2);
assert(t.scene(1).capturePhysics.count==1 && t.scene(1).captureRender.count==1);
assert(abs(t.scene(1).captureRender.sum-.12)<1e-8 && t.scene(1).longFrames50ms==1);
packet.requestId=2; packet.captureTime=10.19;
t=poseTelemetry(t,'physics',10.20,packet);
t=poseTelemetry(t,'flush',10.21,[]);
t=poseTelemetry(t,'render',20,[]);
assert(t.scene(1).captureRender.count==1 && t.scene(1).longFrames50ms==1);
t=poseTelemetry(t,'scene',20,struct('centre',122,'active',false,'elapsed',10));
assert(t.scene(3).seconds==0 && t.sceneIndex==3);
packet.requestId=3; packet.captureTime=20;
t=poseTelemetry(t,'physics',20.1,packet);
t=poseTelemetry(t,'scene',25,struct('centre',154,'active',true,'elapsed',.02));
t=poseTelemetry(t,'render',25.1,[]);
assert(t.scene(4).captureRender.count==0,'Scene transition reused an old sample');
fprintf('POSE TELEMETRY PASSED: separate rates, unique packet latency, pause flush\n');
end
