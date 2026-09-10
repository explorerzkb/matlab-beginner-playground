function testContinuousWorld()
%TESTCONTINUOUSWORLD Verify region continuity, checkpoints, and Sports finish.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state = stepLevel(state, world, cfg, 0);
assert(strcmp(state.levelState.activeRegionId, 'origin'), ...
    'The world did not begin in the MATLAB origin region.');

state.levelState.network.authenticated = true;
state.levelState.network.pageMode = 'success';
state.players(1).pos = world.checkpoints(4).spawn(1, :);
state.players(2).pos = world.checkpoints(4).spawn(2, :);
state = stepLevel(state, world, cfg, 0.1);
assert(strcmp(state.levelState.activeRegionId, 'playground'), ...
    'The authenticated playground did not share global coordinates.');
assert(state.checkpointIndex == 4, ...
    'Checkpoint progress did not follow both players through the webpage.');

state.levelTime = (world.mechanic.bus.finishX-world.mechanic.bus.loopStart)/world.mechanic.bus.speed;
busData = world.mechanic.bus;
busX = busData.loopStart + mod(busData.speed * state.levelTime, ...
    busData.loopEnd - busData.loopStart);
busRect = [busX, busData.y, busData.size];
state.players(1).pos = [busRect(1) + 2.0, busRect(2) + busRect(4)];
state.players(2).pos = [busRect(1) + 4.2, busRect(2) + busRect(4)];
state = stepLevel(state, world, cfg, 0);
assert(state.completed && state.levelState.bus.completed, ...
    'Two players on one bus did not finish at the Sports Center.');
assert(strcmp(state.levelState.activeRegionId, 'sportsCenter'), ...
    'The only finish is not inside the Sports Center region.');
assert(size(state.levelTrajectory, 1) >= 1 && ...
    all(diff(state.levelTrajectory(:, 1)) >= 0), ...
    'Continuous trajectory time was reset or moved backwards.');
end
