function testTeaPickups()
%TESTTEAPICKUPS Verify unique pickup, capacity, and respawn persistence.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);

firstTea = world.mechanic.tea(1).rect;
state.players(1).pos = [firstTea(1) + firstTea(3) / 2, firstTea(2)];
state = collectTeaPickups(state, world);
state = collectTeaPickups(state, world);
assert(state.inventory.teaCount == 1 && state.stats.teaCollected == 1, ...
    'The same tea pickup was collected more than once.');

secondTea = world.mechanic.tea(2).rect;
state.players(1).pos = [secondTea(1) + secondTea(3) / 2, secondTea(2)];
state = collectTeaPickups(state, world);
assert(state.inventory.teaCount == 2, ...
    'Second unique tea did not fill the shared inventory.');

thirdTea = world.mechanic.tea(3).rect;
state.players(1).pos = [thirdTea(1) + thirdTea(3) / 2, thirdTea(2)];
state = collectTeaPickups(state, world);
assert(state.inventory.teaCount == 2 && ...
    numel(state.inventory.collectedTeaIds) == 2, ...
    'A full inventory consumed or removed another pickup.');

state.checkpointIndex = 2;
state = resetToCheckpoint(state, world);
assert(state.inventory.teaCount == 2 && ...
    numel(state.inventory.collectedTeaIds) == 2, ...
    'Checkpoint recovery recreated or removed collected tea.');
state=createInitialState(world,cfg,[]);
tea=world.mechanic.tea(4).rect;
assert(tea(1)+tea(3)<world.mechanic.traffic.crosswalk(1));
state.players(1).pos=[tea(1)+.7,1];
state=collectTeaPickups(state,world);
assert(state.inventory.teaCount==1 && any(state.inventory.collectedTeaIds=="bridge-entry-tea"));
end
