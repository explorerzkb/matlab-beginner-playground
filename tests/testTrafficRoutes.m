function testTrafficRoutes()
%TESTTRAFFICROUTES Verify bridge and signal routes are both selectable.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
traffic = world.mechanic.traffic;

upperState = createInitialState(world, cfg, []);
upperState.players(1).pos = pointIn(traffic.upperRouteZone, 0.30);
upperState.players(2).pos = pointIn(traffic.lowerRouteZone, 0.70);
upperState = stepWorldTraffic(upperState, world, cfg, 0.5);
assert(strcmp(upperState.levelState.traffic.route, 'undecided'), ...
    'Players on different paths incorrectly selected a route.');
upperState.players(2).pos = pointIn(traffic.upperRouteZone, 0.70);
upperState = stepWorldTraffic(upperState, world, cfg, 0.2);
upperState = stepWorldTraffic(upperState, world, cfg, 0.15);
assert(strcmp(upperState.levelState.traffic.route, 'upper') && ...
    strcmp(upperState.stats.trafficRoute, '北理桥'), ...
    'Two players on the bridge did not select the upper route.');

lowerState = createInitialState(world, cfg, []);
lowerState.players(1).pos = pointIn(traffic.lowerRouteZone, 0.30);
lowerState.players(2).pos = pointIn(traffic.lowerRouteZone, 0.70);
lowerState = stepWorldTraffic(lowerState, world, cfg, 0.2);
lowerState = stepWorldTraffic(lowerState, world, cfg, 0.15);
assert(strcmp(lowerState.levelState.traffic.route, 'lower') && ...
    strcmp(lowerState.stats.trafficRoute, '红绿灯'), ...
    'Two players on the road did not select the lower route.');
end

function point = pointIn(rect, fraction)
point = [rect(1) + rect(3) * fraction, rect(2)];
end
