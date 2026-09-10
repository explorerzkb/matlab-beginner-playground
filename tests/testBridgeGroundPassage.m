function testBridgeGroundPassage()
%TESTBRIDGEGROUNDPASSAGE Reproduce the reported invisible wall below the bridge.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); world=continuousCampusWorld();
for presses={[0 0],[1 0],[4 0]}
    state=createInitialState(world,cfg,[]);
    state=stepLevel(state,world,cfg,0);
    state.levelState.traffic.route='upper';
    state.levelState.traffic.climbPresses=presses{1};
    for p=1:2
        state.players(p).pos=[116.9+1.2*(p-1) 1];
        state.players(p).onGround=true;
        input.player(p)=struct('left',false,'right',true,'jump',false);
    end
    state=stepLevel(state,world,cfg,0);
    for tick=1:60
        state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
        state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
    end
    assert(all([state.players(1).pos(1) state.players(2).pos(1)]>121), ...
        'Climbing progress left an invisible wall across the road.');
end
fprintf('BRIDGE GROUND PASSAGE PASSED\n');
end
