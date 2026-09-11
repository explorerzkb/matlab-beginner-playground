function data = poseTelemetry(data, action, now, value)
%POSETELEMETRY Bounded numeric aggregates; never stores camera images.
if isempty(data)
    metric=struct('count',0,'sum',0,'max',0,'over150ms',0);
    scene=struct('seconds',0,'frames',0,'steps',0,'lastRender',NaN, ...
        'longFrames50ms',0,'maxFrameSeconds',0,'capturePhysics',metric, ...
        'captureRender',metric);
    data=struct('scene',repmat(scene,1,5),'sceneIndex',1, ...
        'firstCapture',NaN,'lastCapture',NaN,'packets',0,'validUpdates',[0 0], ...
        'boundUpdates',[0 0], ...
        'inferenceCalls',0,'lastPhysicsId',0,'lastRenderId',0, ...
        'pendingCapture',NaN,'pendingId',0,'captureConsumer',metric);
end
index=data.sceneIndex;
switch action
    case 'packet'
        packet=value.packet;
        if isnan(data.firstCapture), data.firstCapture=packet.captureTime; end
        data.lastCapture=packet.captureTime;
        data.packets=data.packets+1;
        if strcmp(value.cfg.candidate,'single'), calls=2; else, calls=1; end
        data.inferenceCalls=data.inferenceCalls+calls;
        for i=1:min(2,size(packet.points,3))
            f=poseFeatures(packet.points(:,:,i),packet.imageSize,value.cfg);
            data.validUpdates(i)=data.validUpdates(i)+double(f.valid);
        end
        data.captureConsumer=sample(data.captureConsumer,now-packet.captureTime);
    case 'bound'
        for i=1:2
            p=value.player(i);
            if p.valid && p.lastTime==now
                data.boundUpdates(i)=data.boundUpdates(i)+1;
            end
        end
    case 'scene'
        newIndex=1+sum(value.centre>=[54 102 138 187]);
        if newIndex~=index || ~value.active
            data.scene(index).lastRender=NaN;
            data.pendingId=0; data.pendingCapture=NaN;
        end
        data.sceneIndex=newIndex;
        if value.active
            data.scene(newIndex).seconds=data.scene(newIndex).seconds+value.elapsed;
        end
    case 'physics'
        data.scene(index).steps=data.scene(index).steps+1;
        if isempty(value) || value.requestId<=data.lastPhysicsId, return; end
        data.lastPhysicsId=value.requestId;
        data.pendingCapture=value.captureTime; data.pendingId=value.requestId;
        data.scene(index).capturePhysics=sample(data.scene(index).capturePhysics, ...
            now-value.captureTime);
    case 'render'
        s=data.scene(index); s.frames=s.frames+1;
        if isfinite(s.lastRender)
            delta=now-s.lastRender;
            s.longFrames50ms=s.longFrames50ms+double(delta>.05);
            s.maxFrameSeconds=max(s.maxFrameSeconds,delta);
        end
        s.lastRender=now;
        if data.pendingId>data.lastRenderId
            s.captureRender=sample(s.captureRender,now-data.pendingCapture);
            data.lastRenderId=data.pendingId;
        end
        data.scene(index)=s;
    case 'flush'
        data.pendingId=0; data.pendingCapture=NaN;
        for i=1:5, data.scene(i).lastRender=NaN; end
end
end

function metric=sample(metric,value)
if ~isfinite(value) || value<0, return; end
metric.count=metric.count+1;
metric.sum=metric.sum+value;
metric.max=max(metric.max,value);
metric.over150ms=metric.over150ms+double(value>.15);
end
