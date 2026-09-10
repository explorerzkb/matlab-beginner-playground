function testPoseGameInput()
%TESTPOSEGAMEINPUT Event consumption at physics boundaries, not render reads.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'config'),fullfile(root,'src'),fullfile(root,'levels'));
cfg=gameConfig(root); pc=poseConfig(); level=continuousCampusWorld();
fig=figure('Visible','off'); guard=onCleanup(@() delete(fig));
setappdata(fig,'inputMode','pose');
s=createPoseState(); s.phase='active'; s.lastFrameTime=10;
for i=1:2
    s.player(i).valid=true; s.player(i).lastTime=10;
    s.player(i).sequence=1; s.player(i).eventTime=10;
    s.player(i).direction=1;
end
session=struct('state',s,'cursor',[0 0],'cfg',pc,'error','','epoch',1);
setappdata(fig,'poseSession',session);
for i=1:4
    p=readFigurePose(fig,10.01,false,true);
    assert(~any([p.player.jump]),'Render read consumed a jump');
end
p=readFigurePose(fig,10.02,true,true);
assert(all([p.player.jump]));
p=readFigurePose(fig,10.03,true,true);
assert(~any([p.player.jump]));
% A real physics step while airborne consumes the event without landing queue.
session.cursor=[0 0]; setappdata(fig,'poseSession',session);
state=createInitialState(level,cfg,[]); state=stepLevel(state,level,cfg,0);
for i=1:2, state.players(i).pos=[10+i*2 10]; state.players(i).onGround=false; end
p=readFigurePose(fig,10.04,true,true);
state=stepPhysics(state,p,level,cfg,cfg.physics.fixedDt);
assert(all(arrayfun(@(x) x.vel(2)<0,state.players)));
for i=1:2, state.players(i).onGround=true; state.players(i).vel(2)=0; end
p=readFigurePose(fig,10.05,true,true);
state=stepPhysics(state,p,level,cfg,cfg.physics.fixedDt);
assert(all(arrayfun(@(x) x.vel(2)<=0,state.players)));
% Pause/respawn invalidates in-flight epoch and all old actions.
flushFigurePose(fig,false);
after=getappdata(fig,'poseSession');
assert(after.epoch==2 && all(isinf([after.state.player.eventTime])));
p=readFigurePose(fig,10.06,true,true);
assert(p.safetyPause && ~any([p.player.jump p.player.left p.player.right]));
% Keyboard remains a separate source; physics unchanged.
setappdata(fig,'inputMode','keyboard');
[~,isPose]=readFigurePose(fig,10.07,true,true); assert(~isPose);
rmappdata(fig,'poseSession');
clear guard;
fprintf('POSE GAME INPUT PASSED: render/physics separation, no airborne queue, lifecycle epochs\n');
end
