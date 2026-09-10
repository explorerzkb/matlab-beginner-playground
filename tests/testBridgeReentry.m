function testBridgeReentry()
%TESTBRIDGEREENTRY Finished climbing must not capture subsequent normal jumps.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); world=continuousCampusWorld();
state=createInitialState(world,cfg,[]); state=stepLevel(state,world,cfg,0);
deck=world.mechanic.traffic.upperBridgePlatforms(1,:);
deckTop=deck(2)+deck(4);
for p=1:2
    state.players(p).pos=[117.2+(p-1)*1.1 deckTop];
    state.players(p).onGround=true;
    input.player(p).left=false; input.player(p).right=false;
    input.player(p).jump=true;
end
state.levelState.traffic.route='upper';
state.levelState.traffic.climbPresses=[4 4];
state.levelState.traffic.climbHeldLast=[false false];
state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
assert(state.players(1).pos(2)>deckTop && state.players(1).vel(2)>0, ...
    'A normal jump after the fourth rung was snapped back onto the bridge.');

% Returning to the ladder below the deck must permit another ascent.
state.players(1).pos=[114 1]; state.players(1).vel=[0 0];
state.players(1).jumpHeld=false;
state.levelState.traffic.climbHeldLast(1)=false;
state=stepLevel(state,world,cfg,0);
assert(state.levelState.traffic.climbPresses(1)==0, ...
    'A player returning below the bridge retained a completed ladder.');
for press=1:4
    state.players(1).jumpHeld=true;
    state=stepLevel(state,world,cfg,0);
    state.players(1).jumpHeld=false;
    state=stepLevel(state,world,cfg,0);
end
assert(state.levelState.traffic.climbPresses(1)==4 && ...
    abs(state.players(1).pos(2)-deckTop)<1e-8, ...
    'A completed climber could not return to the deck after falling off.');
fprintf('BRIDGE REENTRY PASSED\n');
end
