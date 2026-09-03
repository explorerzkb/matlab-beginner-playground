function testTrafficSignal()
%TESTTRAFFICSIGNAL Verify deterministic, mutually exclusive road phases.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
traffic = world.mechanic.traffic;
samples = [0.0, 3.1, 3.9, 4.4, 7.4];
expected = {'vehicleGreen', 'yellow', 'allRedBeforePed', ...
    'pedestrianGreen', 'allRedBeforeCars'};

for index = 1:numel(samples)
    state = createInitialState(world, cfg, []);
    state.levelTime = samples(index);
    state = stepWorldTraffic(state, world, cfg, 0);
    assert(strcmp(state.levelState.traffic.signalPhase, expected{index}), ...
        'Traffic signal phase did not match the deterministic timeline.');
    assert(~(state.levelState.traffic.carsMayMove && ...
        state.levelState.traffic.pedestriansMayCross), ...
        'Vehicles and pedestrians were enabled at the same time.');
end

state = createInitialState(world, cfg, []);
state.levelState.traffic.route = 'lower';
state.players(1).pos = pointIn(traffic.waitingZone, 0.3);
state.players(2).pos = pointIn(traffic.waitingZone, 0.7);
state.levelTime = 0;
state = stepWorldTraffic(state, world, cfg, 0.5);
assert(abs(state.stats.trafficWaitTime - 0.5) < 1e-9, ...
    'Waiting during vehicle green was not measured.');
state.levelTime = 4.4;
state = stepWorldTraffic(state, world, cfg, 0.5);
assert(abs(state.stats.trafficWaitTime - 0.5) < 1e-9, ...
    'Pedestrian green incorrectly counted as waiting time.');
end

function point = pointIn(rect, fraction)
point = [rect(1) + rect(3) * fraction, rect(2)];
end
