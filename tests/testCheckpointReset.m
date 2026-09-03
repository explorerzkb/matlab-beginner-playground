function testCheckpointReset()
%TESTCHECKPOINTRESET Verify persistent progress and safe temporary phases.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state = stepLevel(state, world, cfg, 0);
state.checkpointIndex = 5;
state.status.breakValue = 4;
state.inventory.teaCount = 1;
state.inventory.collectedTeaIds = "north-lake-tea";
state.levelState.network.authenticated = true;
state.levelState.traffic.route = 'lower';
state.levelState.lexue.homeActive = true;
state.levelState.traffic.cars(:, 1) = 105;
state.levelState.traffic.signalClock = 0;
state.levelState.traffic.fountainClock = 0;
state.levelState.lexue.taskElapsed = 5;
state.levelState.lexue.taskCards = ones(4, 4);
for playerIndex = 1:2
    state.players(playerIndex).pos = [110 + playerIndex, 6];
    state.players(playerIndex).vel = [8, -12];
end
state.rope.currentTension = 50;

state = resetToCheckpoint(state, world);
assert(state.status.breakValue == 4 && state.inventory.teaCount == 1 && ...
    any(state.inventory.collectedTeaIds == "north-lake-tea"), ...
    'Reset discarded persistent break or iced-tea state.');
assert(state.levelState.network.authenticated && ...
    strcmp(state.levelState.traffic.route, 'lower') && ...
    state.levelState.lexue.homeActive, ...
    'Reset discarded completed world events or route choice.');
assert(all(state.players(1).vel == 0) && ...
    all(state.players(2).vel == 0) && state.rope.currentTension == 0, ...
    'Reset did not clear velocity and rope tension.');
assert(~state.levelState.traffic.carsMayMove && ...
    ~state.levelState.traffic.pedestriansMayCross && ...
    ~state.levelState.traffic.jetActive, ...
    'Traffic or fountain did not reset to an all-red safe phase.');
for carIndex = 1:size(state.levelState.traffic.cars, 1)
    assert(~rectanglesOverlap(state.levelState.traffic.cars(carIndex, :), ...
        world.mechanic.traffic.crosswalk), ...
        'A reset vehicle remained inside the crossing.');
end
assert(state.levelState.lexue.taskElapsed < 0 && ...
    isempty(state.levelState.lexue.taskCards), ...
    'Task cards did not receive the configured post-reset grace period.');
assert(state.stats.failures == 1, ...
    'The shared reset was not counted exactly once.');
end

function tf = rectanglesOverlap(first, second)
tf = first(1) + first(3) > second(1) && ...
    first(1) < second(1) + second(3) && ...
    first(2) + first(4) > second(2) && ...
    first(2) < second(2) + second(4);
end
