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

state.players(1).pos = [77, 1];
state.players(2).pos = [78, 1];
state = stepLevel(state, world, cfg, 0.1);
assert(strcmp(state.levelState.activeRegionId, 'network'), ...
    'Crossing global coordinates did not update the active region.');
assert(state.checkpointIndex == 3, ...
    'Continuous checkpoint progress did not advance for both players.');

state.players(1).pos = [181, 1];
state.players(2).pos = [182, 1];
state = stepLevel(state, world, cfg, 0.1);
assert(state.completed, 'Both players inside Lucy River did not finish.');
assert(size(state.levelTrajectory, 1) == 2, ...
    'Continuous trajectory sampling was unexpectedly reset.');
assert(all(diff(state.levelTrajectory(:, 1)) >= 0), ...
    'Continuous trajectory time moved backwards.');
end
