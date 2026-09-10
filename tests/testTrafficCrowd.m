function testTrafficCrowd()
%TESTTRAFFICCROWD Verify waiting students cross safely and push softly.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
traffic = world.mechanic.traffic;
state = createInitialState(world, cfg, []);
state.players(1).pos = [80, 1];
state.players(2).pos = [81, 1];

state.levelTime = 0;
state = stepWorldTraffic(state, world, cfg, 0);
waitingCrowd = state.levelState.traffic.crowd;
for index = 1:size(waitingCrowd, 1)
    assert(~rectanglesOverlap(waitingCrowd(index, :), traffic.crosswalk), ...
        'Waiting students blocked the crossing during vehicle green.');
end

state.levelState.traffic.arrived=true;
state.levelTime = 8.8;
state.levelState.traffic.signalClock = state.levelTime;
state = stepWorldTraffic(state, world, cfg, 0);
crossingCrowd = state.levelState.traffic.crowd;
assert(any(arrayfun(@(index) rectanglesOverlap( ...
    crossingCrowd(index, :), traffic.crosswalk), ...
    1:size(crossingCrowd, 1))), ...
    'No waiting student entered the crossing during pedestrian green.');

normalState = state;
target = crossingCrowd(1, :);
normalState.players(1).pos = [target(1) + target(3) / 2, target(2)];
normalState.players(1).vel = [0, 0];
normalState = stepWorldTraffic(normalState, world, cfg, 0.1);
assert(abs(normalState.players(1).vel(1)) > 0 && ...
    abs(normalState.players(1).vel(1)) <= ...
    traffic.crowdPushSpeedCap + eps, ...
    'Crowd contact did not produce a bounded soft push.');

boostedState = state;
boostedState.inventory.buffTimer = 1;
boostedState.players(1).pos = [target(1) + target(3) / 2, target(2)];
boostedState.players(1).vel = [0, 0];
boostedState = stepWorldTraffic(boostedState, world, cfg, 0.1);
assert(abs(boostedState.players(1).vel(1) - ...
    normalState.players(1).vel(1)) < 1e-12, ...
    'Iced tea incorrectly changed environmental crowd knockback.');

% Inspect three full cycles, including both sides of every signal boundary.
probe=createInitialState(world,cfg,[]);
probe.players(1).pos=[80 1]; probe.players(2).pos=[81 1];
probe=stepWorldTraffic(probe,world,cfg,0);
probe.levelState.traffic.arrived=true;
previous=probe.levelState.traffic.crowd;
dt=cfg.physics.fixedDt;
for tick=1:ceil(3*sum(traffic.signalPhaseDurations)/dt)
    probe.levelState.colliders=zeros(0,4);
    probe=stepWorldTraffic(probe,world,cfg,dt);
    current=probe.levelState.traffic.crowd;
    destinations=traffic.crosswalk(1)+traffic.crosswalk(3)+.8+ ...
        (0:size(current,1)-1)'*.9;
    speeds=abs(destinations-traffic.crowdData(:,1))/traffic.signalPhaseDurations(4);
    assert(all(abs(current(:,1)-previous(:,1))<=speeds*dt+1e-8), ...
        'A pedestrian teleported at a signal change or crossing wrap.');
    if ~probe.levelState.traffic.pedestriansMayCross
        for p=1:size(current,1)
            assert(~rectanglesOverlap(current(p,:),traffic.crosswalk), ...
                'A pedestrian remained in the crossing during a vehicle phase.');
        end
    end
    previous=current;
end
end

function tf = rectanglesOverlap(first, second)
tf = first(1) + first(3) > second(1) && ...
    first(1) < second(1) + second(3) && ...
    first(2) + first(4) > second(2) && ...
    first(2) < second(2) + second(4);
end
