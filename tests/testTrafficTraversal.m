function testTrafficTraversal()
%TESTTRAFFICTRAVERSAL Walk both tethered players through one pedestrian phase.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
traffic = world.mechanic.traffic;
state = createInitialState(world, cfg, []);
state.levelState.traffic.route = 'lower';
state.players(1).pos = [traffic.waitingZone(1) + 0.55, 1];
state.players(2).pos = [traffic.waitingZone(1) + 1.65, 1];
state.players(1).onGround = true;
state.players(2).onGround = true;

pedestrianStart = sum(traffic.signalPhaseDurations(1:3)) + 0.05;
state.levelTime = pedestrianStart;
state = stepLevel(state, world, cfg, 0);
state.levelState.traffic.signalClock = pedestrianStart;
state = stepLevel(state, world, cfg, 0);
assert(state.levelState.traffic.pedestriansMayCross, ...
    'Traversal test did not start during pedestrian green.');
assert(~anyBarrier(state.levelState.colliders, traffic.pedestrianBarrier), ...
    'Pedestrian barrier stayed closed during pedestrian green.');

input = rightInput();
dt = cfg.physics.fixedDt;
for stepIndex = 1:round(4.5 / dt)
    state = stepPhysics(state, input, world, cfg, dt);
    state = stepLevel(state, world, cfg, dt);
    assert(~state.requestReset && state.stats.damageTaken==0, ...
        'A player was reset while following the pedestrian signal.');
end

crossingRight = traffic.crosswalk(1) + traffic.crosswalk(3);
assert(state.players(1).pos(1) > crossingRight && ...
    state.players(2).pos(1) > crossingRight, ...
    'Both tethered players did not reach the far side in one green phase.');
end

function input = rightInput()
for playerIndex = 1:2
    input.player(playerIndex).left = false;
    input.player(playerIndex).right = true;
    input.player(playerIndex).jump = false;
end
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end

function tf = anyBarrier(colliders, barrier)
tf = any(all(abs(colliders - barrier) < 1e-10, 2));
end
