function testPlayabilityV30()
%TESTPLAYABILITYV30 Ground impact, tea-only bridge and bounded spawn immunity.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'src'),fullfile(root,'levels'));
cfg=gameConfig(root);w=continuousCampusWorld();dt=cfg.physics.fixedDt;
for boosted=[false true]
    s=createInitialState(w,cfg,[]);
    for p=1:2
        s.players(p).pos=[115.5 1];s.players(p).onGround=true;
        input.player(p)=struct('left',false,'right',false,'jump',true);
    end
    if boosted,s.inventory.buffTimer=8;end
    s=stepLevel(s,w,cfg,0);highest=1;reached=false;
    for tick=1:180
        for p=1:2
            input.player(p).right=s.players(p).pos(2)>6.5;
            input.player(p).jump=tick==1;
        end
        s=stepPhysics(s,input,w,cfg,dt);s=stepLevel(s,w,cfg,dt);
        highest=max(highest,s.players(1).pos(2));
        reached=reached || strcmp(s.levelState.traffic.route,'upper');
    end
    assert(reached==boosted,'Tea jump gate is not physically correct.');
    if ~boosted,assert(highest<6.5);end
end
% The red cycle begins on arrival, not on the original level timer.
s=createInitialState(w,cfg,[]);s.levelTime=100;
s=stepWorldTraffic(s,w,cfg,0);
s.players(1).pos=[112 1];s.players(2).pos=[111 1];
s=stepWorldTraffic(s,w,cfg,dt);
assert(~s.levelState.traffic.pedestriansMayCross && s.levelState.traffic.signalClock<.1);
assert(size(w.mechanic.traffic.carData,1)>=20);
assert(diff(w.mechanic.bus.phaseOffsets(1:2))-w.mechanic.bus.size(1)>=12);
assert(w.mechanic.bus.loopStart+w.mechanic.bus.size(1)<301);
assert(w.mechanic.bus.sportsFinish(1)>=426);

% Both airborne pears fall naturally before any bicycle impulse is applied.
s=createInitialState(w,cfg,[]);
s.players(1).pos=[154 12];s.players(2).pos=[156 7];
s=stepLevel(s,w,cfg,0);launched=false;
for p=1:2,input.player(p)=struct('left',false,'right',true,'jump',true);end
for tick=1:300
    s=stepPhysics(s,input,w,cfg,dt);
    before=vertcat(s.players.pos);
    grounded=all([s.players.onGround]);
    s=stepLevel(s,w,cfg,dt);
    if s.levelState.bicycle.launched
        assert(grounded && all(abs(before(:,2)-1)<.08));
        assert(isequal(s.levelState.bicycle.impactPositions,before));
        launched=true;break;
    end
end
assert(launched,'The ground contact never launched the pair.');

s=createInitialState(w,cfg,[]);s=stepLevel(s,w,cfg,0);
s.checkpointIndex=7;s=resetToCheckpoint(s,w,cfg);
assert(s.status.respawnProtection==3);
input.useItem=false;
probe=s;
for p=1:2,input.player(p)=struct('left',false,'right',false,'jump',false);end
for tick=1:300
    probe=stepConsumables(probe,input,cfg,dt);
    probe=stepPhysics(probe,input,w,cfg,dt);
    probe=stepLevel(probe,w,cfg,dt);
    assert(~probe.status.deathPending,'Idle bus respawn died within five seconds.');
end
for lane=unique(w.mechanic.traffic.carData(:,1))'
    depths=s.levelState.traffic.carDepth(w.mechanic.traffic.carData(:,1)==lane);
    assert(numel(unique(depths))==5,'Reset stacked all cars in one lane.');
end
for tick=1:179
    s=stepConsumables(s,input,cfg,dt);
    [s,hit]=applyDamageEvent(s,cfg,'bus');
    assert(~hit && s.status.currentHearts==3);
end
s=stepConsumables(s,input,cfg,2*dt);
[s,hit]=applyDamageEvent(s,cfg,'bus');
assert(hit && s.status.currentHearts==0,'Spawn protection became permanent.');
fprintf('V30 PASSED: tea-only bridge, arrival red, dense cars, ground impact, three-second immunity.\n');
end
