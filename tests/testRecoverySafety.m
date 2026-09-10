function testRecoverySafety()
%TESTRECOVERYSAFETY Check failures at the actual state and collision seams.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); world=continuousCampusWorld();
state=createInitialState(world,cfg,[]); state=stepLevel(state,world,cfg,0);
state.checkpointIndex=3;
state.levelState.network.pageMode='timeout';
state.levelState.network.failureSeen=true;
state=stepLevel(state,world,cfg,0);
state=resetToCheckpoint(state,world);
notice=world.mechanic.network.noticePanel;
assert(any(all(abs(state.levelState.colliders-notice)<1e-9,2)), ...
    'The retry frame still used the timeout collision set.');
for p=1:2
    input.player(p).left=false; input.player(p).right=false; input.player(p).jump=false;
end
input.useItem=false;
assert(all(abs(state.levelState.traffic.carDepth)>world.mechanic.traffic.contactDepth), ...
    'Reset left depth traffic in the player crossing.');
for tick=1:120
    state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
    state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
end
assert(all([state.players(1).pos(2) state.players(2).pos(2)]>=notice(2)+notice(4)-0.1), ...
    'Neutral retry input fell through the restored notice.');

% Every earned checkpoint starts outside terrain and remains playable.
for checkpoint=1:numel(world.checkpoints)
    state=createInitialState(world,cfg,[]); state=stepLevel(state,world,cfg,0);
    if checkpoint>=4
        state.levelState.network.authenticated=true;
        state.levelState.network.pageMode='success';
    end
    if checkpoint>=6
        state.levelState.bicycle.landed=true;
        state.levelState.bicycle.phase='landed';
    end
    state.checkpointIndex=checkpoint;
    state=resetToCheckpoint(state,world);
    for tick=1:60
        state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
        state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
        assert(~state.requestReset && state.stats.damageTaken==0, ...
            'Checkpoint %d immediately failed with neutral input.',checkpoint);
    end
    assert(all([state.players(1).pos(2) state.players(2).pos(2)]>=0.99), ...
        'Checkpoint %d spawned inside or below the road.',checkpoint);
end

% Repeated boarding attempts must never push the pair below the safe road.
state=createInitialState(world,cfg,[]);
state=stepLevel(state,world,cfg,0);
state.players(1).pos=[world.mechanic.bus.loopStart+12 1];
state.players(2).pos=[world.mechanic.bus.loopStart+14 1];
state.checkpointIndex=7;
state.levelState.network.authenticated=true; state.levelState.network.pageMode='success';
state.levelState.bicycle.phase='landed'; state.levelState.bicycle.landed=true;
state=stepLevel(state,world,cfg,0);
for tick=1:2400
    for p=1:2
        input.player(p).jump=mod(tick+19*p,100)==0;
    end
    state=stepConsumables(state,input,cfg,cfg.physics.fixedDt);
    state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
    state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
    assert(all([state.players(1).pos(2) state.players(2).pos(2)]>=0.99), ...
        'A bus/lamp/rope interaction pushed a pear through the safe road.');
    if state.requestReset
        assert(state.status.currentHearts==0 && mod(state.stats.damageTaken,3)==0);
        state=resetToCheckpoint(state,world);
    end
end
assert(state.stats.damageTaken>=3 && ~state.status.deathPending, ...
    'A bus body hit must deal damage and recover at the safe checkpoint.');

% A falling partner cannot pull the grounded player through solid terrain.
state=createInitialState(world,cfg,[]);
state.players(1).pos=[38 1]; state.players(2).pos=[34.8 -3];
state=stepLevel(state,world,cfg,0);
input.player(1).jump=false; input.player(2).jump=false;
state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
assert(state.players(1).pos(2)>=1-1e-8,'Rope correction bypassed the ground collision.');

% A road-route jump must meet the same physical bridge underside that is drawn.
state=createInitialState(world,cfg,[]); state=stepLevel(state,world,cfg,0);
state.players(1).pos=[131 1]; state.players(2).pos=[133 1];
state.players(1).onGround=true; state.players(2).onGround=true;
state.levelState.traffic.route='lower';
state.levelState.traffic.signalClock=5;
state=stepLevel(state,world,cfg,0);
hitCeiling=false;
for tick=1:60
    input.player(1).jump=true; input.player(2).jump=true;
    state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
    state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
    hitCeiling=hitCeiling || any([state.players.hitCeiling]);
    assert(all([state.players(1).pos(2)+state.players(1).size(2), ...
        state.players(2).pos(2)+state.players(2).size(2)]<= ...
        world.mechanic.traffic.upperBridgePlatforms(2)+1e-8), ...
        'Road-route input jumped through the bridge.');
end
assert(hitCeiling,'The underside test never reached the bridge.');
fprintf('RECOVERY SAFETY PASSED\n');
end
