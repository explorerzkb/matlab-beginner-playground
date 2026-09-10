function state = stepPoseController(state, detections, imageSize, time, cfg)
%STEPPOSECONTROLLER Calibrate, retain identities, classify tilt and jump.
% detections: 17x3xN in raw camera pixels. time is capture time, monotonic.
if ~isfinite(time) || time<=state.lastFrameTime, return; end
gap = time-state.lastFrameTime;
state.lastFrameTime = time;
if strcmp(state.phase,'recalibrate'), return; end
features = repmat(poseFeatures(nan(17,3),imageSize,cfg),1,size(detections,3));
for i=1:numel(features)
    features(i)=poseFeatures(detections(:,:,i),imageSize,cfg);
end
features=features([features.valid]);
if strcmp(state.phase,'calibrating')
    if gap>cfg.staleSeconds
        state.samples=zeros(0,11);
    end
    state=calibrate(state,features,time,cfg);
    return;
end
[features,identityOK]=matchPlayers(state,features,cfg);
good=identityOK && all([features.valid]) && all([features.controlPose]);
if ~good || gap>cfg.staleSeconds
    for i=1:2
        if identityOK && features(i).valid && features(i).controlPose && ...
                gap<=cfg.staleSeconds, continue; end
        state.player(i).valid=false;
        state.player(i).direction=0;
        state.player(i).standSince=NaN;
        state.player(i).jumpPhase='landing';
        state.player(i).eventTime=-inf;
    end
    state.stableSince=NaN;
    if isnan(state.badSince), state.badSince=time; end
    if ~identityOK || time-state.badSince>=cfg.lossPauseSeconds || ...
            ~strcmp(state.phase,'active')
        state.phase='paused';
        state.reason='站位／身份或操控姿势丢失：全局暂停';
    end
    if ~identityOK
        state.phase='recalibrate';
        state.reason='身份不确定：按 C 重新校准';
    end
    if ~identityOK || gap>cfg.staleSeconds, return; end
else
    state.badSince=NaN;
end
if good && strcmp(state.phase,'paused')
    if isnan(state.stableSince), state.stableSince=time; end
    if time-state.stableSince>=cfg.recoverySeconds
        state.phase='countdown';
        state.countdownUntil=time+cfg.countdownSeconds;
        state.reason='身份已稳定，倒计时恢复';
    end
elseif good && strcmp(state.phase,'countdown') && time>=state.countdownUntil
    state.phase='active';
    state.reason='体感控制';
end
for i=1:2
    p=state.player(i); f=features(i);
    if ~f.valid || ~f.controlPose, continue; end
    dt=time-p.lastTime;
    if ~isfinite(dt) || dt>cfg.staleSeconds
        dt=1/30; p.lastHip=f.hip; p.lastAnkle=f.ankle;
        p.jumpPhase='landing'; p.standSince=NaN;
    end
    p.valid=true;
    p.angle=p.angle+(1-exp(-dt/cfg.smoothingSeconds))*(f.angle-p.zero-p.angle);
    if p.angle>=cfg.enterDegrees, p.direction=1;
    elseif p.angle<=-cfg.enterDegrees, p.direction=-1;
    elseif (p.direction>0 && p.angle<=cfg.exitDegrees) || ...
            (p.direction<0 && p.angle>=-cfg.exitDegrees)
        p.direction=0;
    end
    hipRise=(p.hip-f.hip)/p.scale;
    ankleRise=(p.ankle-f.ankle)/p.scale;
    hipSpeed=(p.lastHip-f.hip)/p.scale/dt;
    ankleSpeed=(p.lastAnkle-f.ankle)/p.scale/dt;
    atGround=abs(hipRise)<cfg.landTolerance && abs(ankleRise)<cfg.landTolerance;
    if strcmp(p.jumpPhase,'standing') && hipRise>cfg.jumpHipRise && ...
            ankleRise>cfg.jumpAnkleRise && hipSpeed>cfg.jumpVelocity && ...
            ankleSpeed>cfg.jumpVelocity
        p.jumpPhase='airborne'; p.standSince=NaN;
        if strcmp(state.phase,'active')
            p.sequence=p.sequence+1; p.eventTime=time;
        end
    elseif ~strcmp(p.jumpPhase,'standing')
        if atGround && abs(hipSpeed)<cfg.jumpVelocity && abs(ankleSpeed)<cfg.jumpVelocity
            if isnan(p.standSince), p.standSince=time; end
            p.jumpPhase='landing';
            % Compensate only floating-point timestamp resolution. Without
            % this, 0.3 s can round below the boundary and cost a camera frame.
            resolution=2*eps(max(abs([time p.standSince])));
            if time-p.standSince+resolution>=cfg.standSeconds
                p.jumpPhase='standing';
            end
        else
            p.standSince=NaN;
        end
    end
    % Frozen calibration height avoids learning a crouch, jump or tiptoe.
    p.lastHip=f.hip; p.lastAnkle=f.ankle; p.lastTime=time;
    if ~strcmp(state.phase,'active')
        p.direction=0; p.eventTime=-inf;
    end
    state.player(i)=p;
end
end

function state=calibrate(state,features,time,cfg)
if numel(features)~=2 || ~all([features.controlPose])
    state.samples=zeros(0,11); return;
end
% Mirror-left is raw-camera-right, bind ONCE at calibration.
[~,order]=sort(arrayfun(@(f) f.centre(1),features),'descend');
features=features(order);
if features(1).centre(1)-features(2).centre(1)<cfg.minimumSeparation
    state.samples=zeros(0,11); return;
end
row=[time features(1).angle features(2).angle features(1).hip ...
    features(2).hip features(1).ankle features(2).ankle ...
    features(1).scale features(2).scale features(1).centre(1) features(2).centre(1)];
state.samples(end+1,:)=row;
if any(abs(row(2:3))>cfg.enterDegrees) || ...
        any(spread(state.samples(:,2:3))>cfg.calibrationAngleRange) || ...
        any(spread(state.samples(:,10:11))>cfg.calibrationPositionRange) || ...
        any(spread(state.samples(:,4:7))>0.025*min(row(8:9)))
    state.samples=row; return;
end
if time-state.samples(1,1)<cfg.calibrationSeconds, return; end
base=median(state.samples,1);
for i=1:2
    state.player(i).anchor=features(i).centre;
    state.player(i).zero=base(1+i);
    state.player(i).hip=base(3+i);
    state.player(i).ankle=base(5+i);
    state.player(i).scale=base(7+i);
    state.player(i).lastTime=time;
    state.player(i).lastHip=features(i).hip;
    state.player(i).lastAnkle=features(i).ankle;
end
state.phase='countdown'; state.countdownUntil=time+cfg.countdownSeconds;
state.reason='已绑定：镜像左为玩家一；倒计时后逐人核对左右与试跳';
state.samples=zeros(0,11);
end

function [assigned,ok]=matchPlayers(state,features,cfg)
empty=struct('valid',false,'controlPose',false,'centre',[NaN NaN], ...
    'scale',NaN,'angle',NaN,'hip',NaN,'ankle',NaN);
assigned=repmat(empty,1,2); ok=false;
if isempty(features), ok=true; return; end
if isscalar(features)
    distances=arrayfun(@(p) norm(p.anchor-features.centre),state.player);
    [distance,index]=min(distances);
    ratio=features.scale/state.player(index).scale;
    if distance<=cfg.identityMaxShift && abs(diff(distances))>=cfg.identityMargin && ...
            ratio<=cfg.maxScaleRatio && ratio>=1/cfg.maxScaleRatio
        assigned(index)=features; ok=true;
    end
    return;
end
if numel(features)~=2, return; end
d=zeros(2);
for i=1:2
    for j=1:2, d(i,j)=norm(state.player(i).anchor-features(j).centre); end
end
costs=[d(1,1)+d(2,2) d(1,2)+d(2,1)];
if abs(diff(costs))<cfg.identityMargin, return; end
if costs(1)<=costs(2), order=[1 2]; else, order=[2 1]; end
assigned=features(order);
if assigned(1).centre(1)-assigned(2).centre(1)<cfg.minimumSeparation, return; end
for i=1:2
    ratio=assigned(i).scale/state.player(i).scale;
    if d(i,order(i))>cfg.identityMaxShift || ...
            ratio>cfg.maxScaleRatio || ratio<1/cfg.maxScaleRatio, return; end
end
ok=true;
end

function value=spread(values)
value=max(values,[],1)-min(values,[],1);
end
