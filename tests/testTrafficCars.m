function testTrafficCars()
%TESTTRAFFICCARS Verify signal-controlled vehicles and major collisions.

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
startCars = state.levelState.traffic.cars;
state = stepWorldTraffic(state, world, cfg, 0.25);
assert(any(abs(state.levelState.traffic.cars(:, 1) - ...
    startCars(:, 1)) > 1e-9), ...
    'Vehicles did not move during the vehicle phase.');

state.levelTime = 4.4;
state.levelState.traffic.signalClock = state.levelTime;
state.levelState.traffic.cars(1, 1) = traffic.crosswalk(1) + 1;
state.levelState.traffic.cars(2, 1) = traffic.crosswalk(1) + 3;
state = stepWorldTraffic(state, world, cfg, 0);
assert(~state.levelState.traffic.carsMayMove, ...
    'Vehicles remained enabled during pedestrian green.');
for carIndex = 1:size(state.levelState.traffic.cars, 1)
    assert(~rectanglesOverlap(state.levelState.traffic.cars(carIndex, :), ...
        traffic.crosswalk), ...
        'A stopped vehicle remained inside the pedestrian crossing.');
end

state.levelTime = 0;
state.status.hitCooldown = 0;
car = state.levelState.traffic.cars(1, :);
state.players(1).pos = [car(1) + car(3) / 2, car(2)];
state = stepWorldTraffic(state, world, cfg, 0);
assert(state.requestReset && state.status.breakValue == ...
    cfg.break.majorIncrease, ...
    'Vehicle collision did not cause one major break event.');
end

function tf = rectanglesOverlap(first, second)
tf = first(1) + first(3) > second(1) && ...
    first(1) < second(1) + second(3) && ...
    first(2) + first(4) > second(2) && ...
    first(2) < second(2) + second(4);
end
