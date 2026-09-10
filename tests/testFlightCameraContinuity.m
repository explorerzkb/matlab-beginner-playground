function testFlightCameraContinuity()
%TESTFLIGHTCAMERACONTINUITY Follow a real launch without scene or scale cuts.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=gameConfig(root); world=continuousCampusWorld();
s=createInitialState(world,cfg,[]);
s.players(1).pos=[154 1]; s.players(2).pos=[156 1];
s.levelState.network.authenticated=true;
s.levelState.network.pageMode='success'; s.checkpointIndex=5;
s=stepLevel(s,world,cfg,0); s=stepCameraTracking(s,world,cfg,0);
fig=figure('Visible','off','Position',[50 50 cfg.render.windowSize]);
guard=onCleanup(@() delete(fig));
ax=axes(fig,'Position',[.045 .08 .92 .86]);
s=renderFrame(fig,ax,s,world,cfg); drawnow;
transform=s.render.handles.worldTransform;
sizes=[s.players.size]; input.useItem=false;
for p=1:2
    input.player(p)=struct('left',false,'right',false,'jump',false);
end
folder=fullfile(root,'docs','visuals','playability-v30');
if ~isfolder(folder), mkdir(folder); end
ys=zeros(900,1); started=false; landed=false;
renderSeconds=0; frames=0;
for tick=1:900
    previousY=s.render.cameraCentreY;
    previousScale=s.render.cameraScale;
    s=stepConsumables(s,input,cfg,cfg.physics.fixedDt);
    s=stepPhysics(s,input,world,cfg,cfg.physics.fixedDt);
    s=stepLevel(s,world,cfg,cfg.physics.fixedDt);
    timer=tic; s=renderFrame(fig,ax,s,world,cfg); drawnow;
    renderSeconds=renderSeconds+toc(timer); frames=frames+1;
    assert(isequal(transform,s.render.handles.worldTransform));
    assert(isequal(sizes,[s.players.size]));
    assert(abs(s.render.cameraCentreY-previousY)<1.6,'Camera jumped vertically.');
    assert(abs(s.render.cameraScale-previousScale)<.006,'Camera scale jumped.');
    if strcmp(s.levelState.bicycle.phase,'flight')
        started=true;
        face=pearExpressionState(s.players(1),[0 0],s.rope.currentTension);
        assert(strcmp(face.name,'terrified'),'Story flight lost its frightened face.');
        [~,viewHeight]=cameraViewport(s,cfg);
        bottom=s.render.cameraCentreY-viewHeight/2;
        assert(min([s.players(1).pos(2),s.players(2).pos(2)])>=bottom-.1);
        assert(max([s.players(1).pos(2)+s.players(1).size(2), ...
            s.players(2).pos(2)+s.players(2).size(2)])<=bottom+viewHeight+.1);
    end
    ys(tick)=s.render.cameraCentreY;
    if s.levelState.bicycle.landed && ~landed
        [vw,~]=cameraViewport(s,cfg);
        assert(s.render.cameraCentre-vw/2>180,'Canteen still in landing viewport.');
    end
    landed=landed || s.levelState.bicycle.landed;
    if any(tick==[50 70 100 140 180 220 270 350 430 550 850])
        frame=getframe(fig);
        imwrite(frame.cdata,fullfile(folder,sprintf('flight-%03d.png',tick)));
    end
end
assert(started && landed && max(ys)>30);
[~,viewHeight,scale]=cameraViewport(s,cfg);
assert(abs(ys(end)-(viewHeight/2-.4))<.05);
assert(abs(scale-cfg.render.campusCameraScale)<.002);
assert(s.levelState.bicycle.disappeared);
assert(strcmp(s.render.handles.continuous.bicycleFrames.Visible,'off'));
fprintf('FLIGHT CAMERA PASSED: continuous launch/apex/landing; %.1f forced render FPS\n', ...
    frames/renderSeconds);
clear guard;
end
