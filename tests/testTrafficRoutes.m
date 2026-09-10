function testTrafficRoutes()
%TESTTRAFFICROUTES Verify four-press bridge climbing and lower-route lock.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
traffic = world.mechanic.traffic;

upperState=createInitialState(world,cfg,[]);
deck=traffic.upperBridgePlatforms;
upperState.players(1).pos=[118 sum(deck([2 4]))];
upperState.players(2).pos=[119 sum(deck([2 4]))];
upperState=stepWorldTraffic(upperState,world,cfg,0);
assert(strcmp(upperState.levelState.traffic.route,'upper'));
assert(all(upperState.levelState.traffic.climbPresses==0));

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
