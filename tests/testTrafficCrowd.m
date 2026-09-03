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

state.levelTime = 5.8;
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
assert(abs(boostedState.players(1).vel(1)) < ...
    abs(normalState.players(1).vel(1)), ...
    'Iced-tea buff did not reduce environmental crowd knockback.');
end

function tf = rectanglesOverlap(first, second)
tf = first(1) + first(3) > second(1) && ...
    first(1) < second(1) + second(3) && ...
    first(2) + first(4) > second(2) && ...
    first(2) < second(2) + second(4);
end
