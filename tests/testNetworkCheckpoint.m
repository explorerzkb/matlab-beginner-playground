function testNetworkCheckpoint()
%TESTNETWORKCHECKPOINT Verify the page checkbox controls the save point.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state.checkpointIndex = 2;
checkbox = world.mechanic.network.rememberCheckbox;

pageExit = world.mechanic.network.authGate(1) - 1.5;
state.players(1).pos = [pageExit, 1];
state.players(2).pos = [pageExit + 1, 1];
state = stepLevel(state, world, cfg, 0.1);
assert(state.checkpointIndex == 2, ...
    'Passing the page without checking it incorrectly saved progress.');

state.players(1).pos = [checkbox(1) + 0.25, checkbox(2)];
state.players(2).pos = [checkbox(1) + checkbox(3) - 0.25, checkbox(2)];
state = stepLevel(state, world, cfg, 0.1);
assert(state.levelState.network.rememberChecked && ...
    state.checkpointIndex == 3, ...
    'Touching the remember-login checkbox did not save progress.');

state.players(1).pos = [pageExit, 1];
state.players(2).pos = [pageExit + 1, 1];
state = resetToCheckpoint(state, world);
assert(norm(state.players(1).pos - world.checkpoints(3).spawn(1, :)) < ...
    1e-9, 'Reset did not use the page checkbox checkpoint.');
end
