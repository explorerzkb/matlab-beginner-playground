function testVisualFeedbackV29()
%TESTVISUALFEEDBACKV29 Runtime pixels, not only object visibility flags.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=gameConfig(root); world=continuousCampusWorld();
folder=fullfile(root,'docs','visuals','playability-v29');
if ~isfolder(folder), mkdir(folder); end
fig=figure('Visible','off','Position',[50 50 cfg.render.windowSize], ...
    'MenuBar','none','ToolBar','none','GraphicsSmoothing',cfg.render.graphicsSmoothing);
guard=onCleanup(@() delete(fig)); ax=axes(fig,'Position',[.045 .08 .92 .86]);
s=createInitialState(world,cfg,[]);
s.players(1).pos=[60.2 6.25]; s.players(2).pos=[61.5 6.25];
s=stepLevel(s,world,cfg,0); s.render.cameraCentre=60;
s=renderFrame(fig,ax,s,world,cfg); drawnow;
h=s.render.handles; front=capture(fig,folder,'lake-rail.png');
children=h.worldTransform.Children;
assert(find(children==h.lakeRailForeground(1))<find(children==h.players(1).transform));
set(h.lakeRailForeground,'Visible','off'); drawnow;
behind=capture(fig,folder,'lake-rail-disabled.png');
point=h.worldTransform.Matrix*[s.players(1).pos 0 1]';
[row,col]=pixelAt(ax,front,point(1:2)',cfg);
a=double(front(row-90:row,col-45:col+45,:));
b=double(behind(row-90:row,col-45:col+45,:));
assert(nnz(max(abs(a-b),[],3)>20)>30,'Lake rail did not cover pear pixels.');
for side=1:2
    s=createInitialState(world,cfg,[]);
    x=world.mechanic.traffic.signalX(side);
    s.players(1).pos=[x-4 1]; s.players(2).pos=[x-2.5 1];
    s=stepLevel(s,world,cfg,0); s.render.cameraCentre=x+2;
    s=renderFrame(fig,ax,s,world,cfg); drawnow;
    h=s.render.handles;
    frame=capture(fig,folder,sprintf('signal-%d.png',side));
    lamp=h.continuous.signalLights(1,side); rect=lamp.Position;
    point=h.worldTransform.Matrix*[rect(1)+rect(3)/2;rect(2)+rect(4)/2;0;1];
    [row,col]=pixelAt(ax,frame,point(1:2)',cfg);
    color=double(squeeze(frame(row,col,:)))/255;
    assert(color(1)>.65 && color(2)<.4,'Signal LED is covered by its housing or bridge.');
end
% Layout-only wide view, explicitly separate from normal gameplay framing.
s.render.cameraScale=.60; s.render.cameraCentre=134;
s.render.cameraCentreY=cfg.render.viewportHeight/.60/2-.4;
renderFrame(fig,ax,s,world,cfg); drawnow;
capture(fig,folder,'traffic-layout-debug.png');
clear guard;
fprintf('V29 VISUAL PIXELS PASSED: lake rail, both unobscured large LEDs\n');
end

function frame=capture(fig,folder,name)
f=getframe(fig); frame=f.cdata; imwrite(frame,fullfile(folder,name));
end

function [row,col]=pixelAt(ax,frame,point,cfg)
px=ax.Position(1)+ax.Position(3)*point(1)/cfg.render.viewportWidth;
py=ax.Position(2)+ax.Position(4)*point(2)/cfg.render.viewportHeight;
col=round(px*size(frame,2)); row=round((1-py)*size(frame,1));
end
