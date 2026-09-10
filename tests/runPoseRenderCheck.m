function report = runPoseRenderCheck(useCamera, scenes)
%RUNPOSERENDERCHECK Visible 30-Hz render / 60-Hz scene workload, five pockets.
% Scripted camera/player positions measure workload, not a human playthrough.
if nargin<1, useCamera=false; end
if nargin<2, scenes=1:5; end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'),fullfile(root,'levels'));
cfg=gameConfig(root); cfg.render.targetHz=30;
session=[];
if useCamera
    pc=poseConfig(); pc.modelPath=fullfile(root,'assets','game','models','movenet-single-lightning.tflite');
    session=startPoseSession(pc);
end
poolGuard=onCleanup(@() stopPoseSession(session));
fig=figure('Visible','on','Position',[50 50 cfg.render.windowSize], ...
    'MenuBar','none','ToolBar','none','GraphicsSmoothing',cfg.render.graphicsSmoothing);
guard=onCleanup(@() delete(fig)); ax=axes(fig,'Position',[.045 .08 .92 .86]);
waitGuard=onCleanup(@() gameFrameWait('close'));
level=continuousCampusWorld();
names={'north-lake','network-race','traffic','bicycle','campus'};
centres=[26 82 122 154 mean([level.mechanic.bus.loopStart level.mechanic.bus.finishX])];
report=struct();
input.player=repmat(struct('left',false,'right',false,'jump',false),1,2);
input.useItem=false;
disp(rendererinfo(ax));
gameFrameWait();
for scene=scenes
    state=createPerformanceScene(level,cfg,centres(scene));
    for i=1:20
        state=advancePerformanceFrame(state,level,cfg,centres(scene),i);
        state=renderFrame(fig,ax,state,level,cfg); drawnow;
        if useCamera, session=pollPoseSession(session,poseClock()); end
    end
    clock=tic; previous=0; accumulator=0; nextRender=0;
    rendered=[]; costs=[]; steps=0; ages=[]; seenPacket=0;
    packetStart=0; validStart=[0 0];
    if useCamera
        packetStart=session.packets; seenPacket=packetStart;
        validStart=session.telemetry.validUpdates;
    end
    while toc(clock)<5
        now=toc(clock); elapsed=now-previous;
        accumulator=accumulator+min(elapsed,.12); previous=now;
        if useCamera
            session=pollPoseSession(session,poseClock());
            assert(isempty(session.error),'%s',session.error);
            session.telemetry=poseTelemetry(session.telemetry,'scene',poseClock(), ...
                struct('centre',centres(scene),'active',true,'elapsed',elapsed));
            if session.packets>seenPacket
                seenPacket=session.packets;
                ages(end+1)=poseClock()-session.lastPacket.captureTime; %#ok<AGROW>
            end
        end
        while accumulator>=cfg.physics.fixedDt
            steps=steps+1;
            % Execute real consumables, collision and rope physics, then
            % constrain positions to this scene; this is still a fixture.
            state=stepConsumables(state,input,cfg,cfg.physics.fixedDt);
            state=stepPhysics(state,input,level,cfg,cfg.physics.fixedDt);
            if useCamera
                packet=[];
                if ~isempty(session.lastPacket) && poseClock()-session.lastPacket.captureTime<=pc.staleSeconds
                    packet=session.lastPacket;
                end
                session.telemetry=poseTelemetry(session.telemetry,'physics',poseClock(),packet);
            end
            stepCfg=cfg; stepCfg.render.targetHz=60;
            state=advancePerformanceFrame(state,level,stepCfg,centres(scene),steps);
            accumulator=accumulator-cfg.physics.fixedDt;
        end
        if now>=nextRender
            t=tic; state=renderFrame(fig,ax,state,level,cfg); drawnow;
            costs(end+1)=toc(t); rendered(end+1)=toc(clock); %#ok<AGROW>
            if useCamera, session.telemetry=poseTelemetry(session.telemetry,'render',poseClock(),[]); end
            nextRender=nextRender+1/30;
            if toc(clock)-nextRender>1/30, nextRender=toc(clock); end
        else
            drawnow limitrate;
            gameFrameWait();
        end
    end
    duration=toc(clock); intervals=diff(rendered);
    result=struct('fps',numel(rendered)/duration,'physicsStepsHz',steps/duration, ...
        'renderTimes',costs,'frameIntervals',intervals,'longFrames50ms',sum(intervals>.05), ...
        'maxFrameMs',1000*max(intervals),'captureToConsumerSeconds',ages);
    if useCamera
        result.captureCallHz=(session.packets-packetStart)/duration;
        result.perRoiValidPoseHz=(session.telemetry.validUpdates-validStart)/duration;
        result.inferenceCallHz=2*result.captureCallHz;
        result.softwareTiming=session.telemetry.scene(scene);
        m=result.softwareTiming.captureRender;
        fprintf('  capture %.2f Hz | valid ROI %.2f / %.2f Hz | infer calls %.2f Hz | capture->draw mean %.1f max %.1f ms (fixture, not action latency)\n', ...
            result.captureCallHz,result.perRoiValidPoseHz,result.inferenceCallHz,1000*m.sum/max(1,m.count),1000*m.max);
    end
    report.(matlab.lang.makeValidName(names{scene}))=result;
    fprintf('POSE DISPLAY %-12s %.2f FPS | %.2f steps/s | long>50ms %d | max %.1fms\n', ...
        names{scene},result.fps,result.physicsStepsHz,result.longFrames50ms,result.maxFrameMs);
end
stamp=char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'));
save(fullfile(root,'docs','validation','pose-control',sprintf('render-camera-%d-%s.mat',useCamera,stamp)),'report');
clear guard poolGuard waitGuard;
fprintf('Report only: no 40/50-FPS gate; not human acceptance or exact monitor presentation timing.\n');
end
