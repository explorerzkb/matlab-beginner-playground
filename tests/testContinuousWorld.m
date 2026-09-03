function testContinuousWorld()
%TESTCONTINUOUSWORLD Verify seamless regions, checkpoints, and one finish.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);

state = stepLevel(state, world, cfg, 0);
assert(strcmp(state.levelState.activeRegionId, 'origin'), ...
    'World did not begin in the MATLAB origin region.');

checkbox = world.mechanic.network.rememberCheckbox;
state.players(1).pos = [checkbox(1) + 0.25, checkbox(2)];
state.players(2).pos = [checkbox(1) + checkbox(3) - 0.25, checkbox(2)];
state = stepLevel(state, world, cfg, 0.1);
assert(state.checkpointIndex == 3, ...
    'Campus-network checkbox did not become a checkpoint.');

networkExit = world.checkpoints(4).spawn;
state.players(1).pos = networkExit(1, :);
state.players(2).pos = networkExit(2, :);
state = stepLevel(state, world, cfg, 0.1);
assert(strcmp(state.levelState.activeRegionId, 'network'), ...
    'Crossing global coordinates did not update the active region.');
assert(state.checkpointIndex == 4, ...
    'Continuous checkpoint progress did not advance for both players.');

state.players(1).pos = world.finish(1:2) + [0.8, 0];
state.players(2).pos = world.finish(1:2) + [1.8, 0];
state.levelState.lexue.homeActive = true;
state.levelState.lexue.courseCardReached = true;
state = stepLevel(state, world, cfg, 0.1);
assert(state.completed, 'Both players inside Lucy River did not finish.');
assert(size(state.levelTrajectory, 1) == 3, ...
    'Continuous trajectory sampling was unexpectedly reset.');
assert(all(diff(state.levelTrajectory(:, 1)) >= 0), ...
    'Continuous trajectory time moved backwards.');
end
