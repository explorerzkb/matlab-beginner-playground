function testTrafficRoutes()
%TESTTRAFFICROUTES Verify four-press bridge climbing and lower-route lock.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
traffic = world.mechanic.traffic;

upperState = createInitialState(world, cfg, []);
upperState.players(1).pos = pointIn(traffic.climbZone, 0.35);
upperState.players(2).pos = pointIn(traffic.climbZone, 0.65);
upperState = stepWorldTraffic(upperState, world, cfg, 0);
for press = 1:traffic.climbPressesRequired
    upperState.players(1).jumpHeld = true;
    upperState.players(2).jumpHeld = true;
    upperState = stepWorldTraffic(upperState, world, cfg, 0);
    upperState.players(1).jumpHeld = false;
    upperState.players(2).jumpHeld = false;
    upperState = stepWorldTraffic(upperState, world, cfg, 0);
end
assert(strcmp(upperState.levelState.traffic.route, 'upper') && ...
    strcmp(upperState.stats.trafficRoute, '北理桥'), ...
    'The first climb press did not lock the North Li Bridge route.');
assert(all(upperState.levelState.traffic.climbPresses == 4), ...
    'Each player did not retain all four climb presses.');
assert(all(isfinite([upperState.players.pos])), ...
    'Bridge climbing produced a non-finite player coordinate.');
for index = 1:size(traffic.upperBridgePlatforms, 1)
    assert(any(all(abs(upperState.levelState.colliders - ...
        traffic.upperBridgePlatforms(index, :)) < 1e-12, 2)), ...
        'The selected North Li Bridge was not made solid.');
end

lowerState = createInitialState(world, cfg, []);
lowerState.players(1).pos = [traffic.lowerLockX + 0.4, 1.0];
lowerState.players(2).pos = [traffic.lowerLockX + 1.6, 1.0];
lowerState = stepWorldTraffic(lowerState, world, cfg, 0);
assert(strcmp(lowerState.levelState.traffic.route, 'lower') && ...
    strcmp(lowerState.stats.trafficRoute, '红绿灯'), ...
    'Crossing the ground entrance did not lock the traffic-light route.');
lowerState.players(1).jumpHeld = true;
lowerState.players(1).pos = pointIn(traffic.climbZone, 0.5);
lowerState = stepWorldTraffic(lowerState, world, cfg, 0);
assert(strcmp(lowerState.levelState.traffic.route, 'lower'), ...
    'A later jump incorrectly changed the locked lower route.');
end

function point = pointIn(rect, fraction)
point = [rect(1) + rect(3) * fraction, rect(2)];
end
