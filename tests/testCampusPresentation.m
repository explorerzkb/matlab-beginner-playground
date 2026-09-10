function testCampusPresentation()
%TESTCAMPUSPRESENTATION Cover one-way wraps, timeout hold and view transitions.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'src'),fullfile(root,'levels'));
cfg=gameConfig(root); world=continuousCampusWorld();
s=createInitialState(world,cfg,[]); s=stepLevel(s,world,cfg,0);
s.levelState.network.pageMode='timeout';
[s,ok]=applyDamageEvent(s,cfg,'fatal');
assert(ok && s.status.deathTimer==6);
input.useItem=false;
s=stepConsumables(s,input,cfg,5.99);
assert(~s.requestReset && s.status.deathTimer>0);
s=stepConsumables(s,input,cfg,.02);
assert(s.requestReset);

s=createInitialState(world,cfg,[]);
s.players(1).pos=[215 1]; s.players(2).pos=[217 1];
data=world.mechanic.bus;
period=(data.loopEnd-data.loopStart)/data.speed;
s.levelTime=period-.01; s=stepWorldBus(s,world,cfg,0);
old=s.levelState.bus.rects;
s.levelTime=period+.01; s=stepWorldBus(s,world,cfg,.02);
assert(s.status.currentHearts==3,'Wrapped bus swept the whole road.');
delta=s.levelState.bus.rects(:,1)-old(:,1);
assert(delta(1)<0 && all(delta(2:end)>0));
assert(numel(data.phaseOffsets)==8 && diff(data.phaseOffsets(1:2))>data.size(1));

folder=fullfile(root,'docs','visuals','playability-v29');
if ~isfolder(folder), mkdir(folder); end
fig=figure('Visible','off','Position',[50 50 cfg.render.windowSize], ...
    'GraphicsSmoothing',cfg.render.graphicsSmoothing);
guard=onCleanup(@() delete(fig));
ax=axes(fig,'Position',[.045 .08 .92 .86]);
s=createInitialState(world,cfg,[]); s=stepLevel(s,world,cfg,0);
s=renderFrame(fig,ax,s,world,cfg); drawnow;
verifyScenery(fig,folder,'opening.png');
originalTransform=s.render.handles.worldTransform;
s.levelState.bicycle.phase='flight';
s.players(1).pos=[166 24]; s.players(2).pos=[167 25];
s=stepCameraTracking(s,world,cfg,0);
s=renderFrame(fig,ax,s,world,cfg); drawnow;
assert(strcmp(s.render.viewMode,'world') && ...
    isequal(originalTransform,s.render.handles.worldTransform), ...
    'Flight rebuilt the scene instead of moving its camera.');
assert(s.render.cameraCentreY>15,'Flight camera hit the old height ceiling.');
f=getframe(fig); imwrite(f.cdata,fullfile(folder,'flight.png'));
s.levelState.bicycle.phase='landed'; s.levelState.bicycle.landed=true;
top=data.y+data.size(2);
s.players(1).pos=[data.loopStart top]; s.players(2).pos=[data.loopStart+2 top];
s=stepLevel(s,world,cfg,0);
s.render.cameraCentre=data.backgroundRect(1)+33;
[~,viewHeight]=cameraViewport(s,cfg);
s.render.cameraCentreY=viewHeight/2-.4;
s=renderFrame(fig,ax,s,world,cfg); drawnow;
assert(strcmp(s.render.viewMode,'world'));
assert(strcmp(get(s.render.handles.campusBackdrop,'Visible'),'on'));
sourceInfo=imfinfo(cfg.assets.lastBusHandscroll);
expectedSize=[ceil(sourceInfo.Height/cfg.render.campusHandscrollTextureStride), ...
    ceil(sourceInfo.Width/cfg.render.campusHandscrollTextureStride),3];
actualSize=size(get(s.render.handles.campusBackdrop,'CData'));
assert(isequal(actualSize,expectedSize), ...
    'Campus backdrop was sampled more than once.');
firstTransform=get(s.render.handles.worldTransform,'Matrix');
assert(isequal(get(s.render.handles.campusBackdrop,'Parent'), ...
    s.render.handles.worldTransform),'Backdrop does not share world camera.');
assert(~isgraphics(s.render.handles.campusRoad),'A duplicate road was created.');
assert(max(abs(get(s.render.handles.continuous.buses(1),'Position')- ...
    s.levelState.bus.rects(1,:)))<1e-10,'Bus drawing differs from its collider.');
f=getframe(fig); imwrite(f.cdata,fullfile(folder,'road.png'));
s.render.cameraCentre=data.backgroundRect(1)+110;
s.players(1).pos=[data.backgroundRect(1)+109 top]; s.players(2).pos=[data.backgroundRect(1)+111 top];
s=renderFrame(fig,ax,s,world,cfg); drawnow;
secondTransform=get(s.render.handles.worldTransform,'Matrix');
assert(secondTransform(1,4)<firstTransform(1,4), ...
    'Last-bus handscroll did not move with the camera.');
f=getframe(fig); imwrite(f.cdata,fullfile(folder,'road-scroll-right.png'));
s.checkpointIndex=1; s=resetToCheckpoint(s,world,cfg);
s=renderFrame(fig,ax,s,world,cfg);
assert(strcmp(s.render.viewMode,'world'));
drawnow; verifyScenery(fig,folder,'reset.png');
for x=[35 119]
    s.players(1).pos=[x-1 1]; s.players(2).pos=[x+1 1];
    s=stepLevel(s,world,cfg,0);
    s.render.cameraCentre=x;
    s=renderFrame(fig,ax,s,world,cfg); drawnow;
    verifyScenery(fig,folder,sprintf('scene-%d.png',x));
end
clear guard;
fprintf(['CAMPUS PRESENTATION PASSED: 6s hold, one-way wrap, ' ...
    'world-anchored handscroll, continuous flight/reset views\n']);
end

function verifyScenery(fig,folder,name)
f=getframe(fig); imwrite(f.cdata,fullfile(folder,name));
rgb=double(f.cdata);
area=rgb(round(end*.30):round(end*.72),round(end*.15):round(end*.80),:);
assert(max(std(reshape(area,[],3),0,1))>18,'The scenery is covered by a flat sky layer.');
end
