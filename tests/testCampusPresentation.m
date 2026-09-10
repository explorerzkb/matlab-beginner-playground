function testCampusPresentation()
%TESTCAMPUSPRESENTATION Cover one-way wraps, timeout hold and view transitions.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'src'),fullfile(root,'levels'));
cfg=gameConfig(root); world=continuousCampusWorld();
s=createInitialState(world,cfg,[]); s=stepLevel(s,world,cfg,0);
s.levelState.network.pageMode='timeout';
[s,ok]=applyDamageEvent(s,cfg,'fatal');
assert(ok && s.status.deathTimer==5);
input.useItem=false;
s=stepConsumables(s,input,cfg,4.99);
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
assert(numel(data.phaseOffsets)==5 && 14/data.speed<5);

folder=fullfile(root,'docs','visuals','last-bus-handscroll-v26');
if ~isfolder(folder), mkdir(folder); end
fig=figure('Visible','off','Position',[50 50 cfg.render.windowSize], ...
    'GraphicsSmoothing',cfg.render.graphicsSmoothing);
guard=onCleanup(@() delete(fig));
ax=axes(fig,'Position',[.045 .08 .92 .86]);
s=createInitialState(world,cfg,[]); s=stepLevel(s,world,cfg,0);
s=renderFrame(fig,ax,s,world,cfg); drawnow;
verifyScenery(fig,folder,'opening.png');
s.levelState.bicycle.phase='flight';
s.players(1).pos=[166 24]; s.players(2).pos=[167 25];
s=renderFrame(fig,ax,s,world,cfg); drawnow;
assert(strcmp(s.render.viewMode,'sky') && isempty(findall(ax,'Type','image')), ...
    'Ground imagery leaked into the flight view.');
f=getframe(fig); imwrite(f.cdata,fullfile(folder,'flight.png'));
s.levelState.bicycle.phase='landed'; s.levelState.bicycle.landed=true;
s.players(1).pos=[195 3.4]; s.players(2).pos=[197 3.4];
s=stepLevel(s,world,cfg,0);
s.render.cameraCentre=196;
s.render.cameraCentreY=cfg.render.viewportHeight/2-.4;
s=renderFrame(fig,ax,s,world,cfg); drawnow;
assert(strcmp(s.render.viewMode,'campus'));
assert(strcmp(get(s.render.handles.campusBackdrop,'Visible'),'on'));
sourceInfo=imfinfo(cfg.assets.lastBusHandscroll);
expectedSize=[ceil(sourceInfo.Height/cfg.render.campusHandscrollTextureStride), ...
    ceil(sourceInfo.Width/cfg.render.campusHandscrollTextureStride),3];
actualSize=size(get(s.render.handles.campusBackdrop,'CData'));
assert(isequal(actualSize,expectedSize), ...
    'Campus backdrop was sampled more than once.');
firstScrollBounds=get(s.render.handles.campusBackgroundAxes,'XLim');
assert(firstScrollBounds(1)>0 && diff(firstScrollBounds)<0.5, ...
    'Last-bus backdrop is still a fixed full-screen plate.');
assert(max(abs(get(s.render.handles.continuous.buses(1),'Position')- ...
    s.levelState.bus.rects(1,:)))<1e-10,'Bus drawing differs from its collider.');
f=getframe(fig); imwrite(f.cdata,fullfile(folder,'road.png'));
s.render.cameraCentre=232;
s.players(1).pos=[231 3.4]; s.players(2).pos=[233 3.4];
s=renderFrame(fig,ax,s,world,cfg); drawnow;
secondScrollBounds=get(s.render.handles.campusBackgroundAxes,'XLim');
assert(secondScrollBounds(1)>firstScrollBounds(1), ...
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
fprintf(['CAMPUS PRESENTATION PASSED: 5s hold, one-way wrap, ' ...
    'moving handscroll, sky/side-view/reset views\n']);
end

function verifyScenery(fig,folder,name)
f=getframe(fig); imwrite(f.cdata,fullfile(folder,name));
rgb=double(f.cdata);
area=rgb(round(end*.30):round(end*.72),round(end*.15):round(end*.80),:);
assert(max(std(reshape(area,[],3),0,1))>18,'The scenery is covered by a flat sky layer.');
end
