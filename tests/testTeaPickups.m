function testTeaPickups()
%TESTTEAPICKUPS Verify unique pickup, capacity, and respawn persistence.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);

state.players(1).pos = [30.5, 1.0];
state = collectTeaPickups(state, world);
state = collectTeaPickups(state, world);
assert(state.inventory.teaCount == 1 && state.stats.teaCollected == 1, ...
    'The same tea pickup was collected more than once.');

state.players(1).pos = [79.1, 1.0];
state = collectTeaPickups(state, world);
assert(state.inventory.teaCount == 2, ...
    'Second unique tea did not fill the shared inventory.');

state.players(1).pos = [130.5, 3.45];
state = collectTeaPickups(state, world);
assert(state.inventory.teaCount == 2 && ...
    numel(state.inventory.collectedTeaIds) == 2, ...
    'A full inventory consumed or removed another pickup.');

state.checkpointIndex = 2;
state = resetToCheckpoint(state, world);
assert(state.inventory.teaCount == 2 && ...
    numel(state.inventory.collectedTeaIds) == 2, ...
    'Checkpoint recovery recreated or removed collected tea.');
end
