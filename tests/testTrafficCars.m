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
% Reach the pedestrian phase through the normal fixed-step timeline.
state.levelState.traffic.signalClock = 0;
state.levelState.traffic.cars = traffic.carData(:,1:4);
for tick=1:round(4.5/cfg.physics.fixedDt)
    state.levelState.colliders=zeros(0,4);
    state=stepWorldTraffic(state,world,cfg,cfg.physics.fixedDt);
end
state = stepWorldTraffic(state, world, cfg, 0);
assert(~state.levelState.traffic.carsMayMove, ...
    'Vehicles remained enabled during pedestrian green.');
for carIndex = 1:size(state.levelState.traffic.cars, 1)
    assert(~rectanglesOverlap(state.levelState.traffic.cars(carIndex, :), ...
        traffic.crosswalk), ...
        'A stopped vehicle remained inside the pedestrian crossing.');
end

state.levelTime = 0;
state.levelState.traffic.signalClock = 0;
state.status.hitCooldown = 0;
state.levelState.traffic.cars(1, 1) = traffic.crosswalk(1) + 0.1;
car = state.levelState.traffic.cars(1, :);
state.players(1).pos = [car(1) + car(3) / 2, car(2)];
state = stepWorldTraffic(state, world, cfg, 0);
assert(state.status.currentHearts == 0 && ...
    state.status.deathPending && ~state.requestReset, ...
    'Moving vehicle collision did not begin a fatal heart event.');
state = stepConsumables(state, emptyInput(), cfg, cfg.health.deathDelay);
assert(state.requestReset, ...
    'Fatal vehicle collision did not reset after its feedback delay.');

state = createInitialState(world, cfg, []);
state.levelTime = 4.5;
state.levelState.traffic.signalClock = state.levelTime;
state = stepWorldTraffic(state, world, cfg, 0);
state.players(1).pos = [traffic.waitingZone(1) + 0.6, 1];
state.players(2).pos = [traffic.waitingZone(1) + 1.6, 1];
state.status.hitCooldown = 0;
state = stepWorldTraffic(state, world, cfg, 0);
assert(~state.requestReset, ...
    'Safely waiting players were hit by stopped traffic.');

probe=createInitialState(world,cfg,[]);
probe.players(1).pos=[80 1]; probe.players(2).pos=[81 1];
probe=stepWorldTraffic(probe,world,cfg,0);
dt=cfg.physics.fixedDt;
previous=probe.levelState.traffic.cars;
for tick=1:round(6*sum(traffic.signalPhaseDurations)/dt)
    probe.levelState.colliders=zeros(0,4);
    probe=stepWorldTraffic(probe,world,cfg,dt);
    cars=probe.levelState.traffic.cars;
    assert(all(abs(cars(:,1)-previous(:,1))<=traffic.carData(:,5)*dt+1e-8), ...
        'A car teleported at the route boundary or signal change.');
    if probe.levelState.traffic.pedestriansMayCross
        for carIndex=1:size(cars,1)
            assert(~rectanglesOverlap(cars(carIndex,:),traffic.crosswalk), ...
                'A car blocked the crossing during pedestrian green.');
        end
    end
    previous=cars;
end
end

function input = emptyInput()
input.player(1) = struct('left', false, 'right', false, 'jump', false);
input.player(2) = input.player(1);
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end

function tf = rectanglesOverlap(first, second)
tf = first(1) + first(3) > second(1) && ...
    first(1) < second(1) + second(3) && ...
    first(2) + first(4) > second(2) && ...
    first(2) < second(2) + second(4);
end
