function testMovingPlatform()
%TESTMOVINGPLATFORM Verify that a standing player follows platform motion.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
state = createInitialState(continuousCampusWorld(), cfg, []);
previousRect = [10, 2, 4, 0.5];
currentRect = [10.4, 2.3, 4, 0.5];
state.players(1).pos = [12, 2.5];
state.players(2).pos = [4, 1];

state = carryPlayersWithPlatform(state, previousRect, currentRect);
assert(norm(state.players(1).pos - [12.4, 2.8]) < 1e-12, ...
    'Standing player did not inherit moving-platform displacement.');
assert(norm(state.players(2).pos - [4, 1]) < 1e-12, ...
    'Distant player was incorrectly moved with the platform.');
end
