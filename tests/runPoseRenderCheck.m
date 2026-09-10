function report = runPoseRenderCheck(useCamera)
%RUNPOSERENDERCHECK Visible 30-Hz render / 60-Hz scene workload, five pockets.
% Scripted camera/player positions measure workload, not a human playthrough.
if nargin<1, useCamera=false; end
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
disp(rendererinfo(ax));
gameFrameWait();
for scene=1:5
    state=createPerformanceScene(level,cfg,centres(scene));
    for i=1:20
        state=advancePerformanceFrame(state,level,cfg,centres(scene),i);
        state=renderFrame(fig,ax,state,level,cfg); drawnow;
        if useCamera, session=pollPoseSession(session,poseClock()); end
    end
    clock=tic; previous=0; accumulator=0; nextRender=0;
    rendered=[]; costs=[]; steps=0; ages=[]; seenPacket=0;
    while toc(clock)<5
        now=toc(clock); accumulator=accumulator+min(now-previous,.12); previous=now;
        if useCamera
            session=pollPoseSession(session,poseClock());
            if session.packets>seenPacket
                seenPacket=session.packets;
                ages(end+1)=poseClock()-session.lastPacket.captureTime; %#ok<AGROW>
            end
        end
        while accumulator>=cfg.physics.fixedDt
            steps=steps+1;
            % Existing fixture advances only deterministic scene mechanisms.
            stepCfg=cfg; stepCfg.render.targetHz=60;
            state=advancePerformanceFrame(state,level,stepCfg,centres(scene),steps);
            accumulator=accumulator-cfg.physics.fixedDt;
        end
        if now>=nextRender
            t=tic; state=renderFrame(fig,ax,state,level,cfg); drawnow;
            costs(end+1)=toc(t); rendered(end+1)=toc(clock); %#ok<AGROW>
            nextRender=max(nextRender+1/30,toc(clock));
        else
            drawnow limitrate;
            gameFrameWait();
        end
    end
    duration=toc(clock); intervals=diff(rendered);
    result=struct('fps',numel(rendered)/duration,'physicsStepsHz',steps/duration, ...
        'renderTimes',costs,'frameIntervals',intervals,'longFrames50ms',sum(intervals>.05), ...
        'maxFrameMs',1000*max(intervals),'captureToConsumerSeconds',ages);
    report.(matlab.lang.makeValidName(names{scene}))=result;
    fprintf('POSE DISPLAY %-12s %.2f FPS | %.2f steps/s | long>50ms %d | max %.1fms\n', ...
        names{scene},result.fps,result.physicsStepsHz,result.longFrames50ms,result.maxFrameMs);
end
stamp=char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'));
save(fullfile(root,'docs','validation','pose-control',sprintf('render-camera-%d-%s.mat',useCamera,stamp)),'report');
clear guard poolGuard waitGuard;
fprintf('Report only: no 40/50-FPS gate; not human acceptance or exact monitor presentation timing.\n');
end
