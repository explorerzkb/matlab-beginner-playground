function testLexueTasks()
%TESTLEXUETASKS Verify batched task cards cause minor break and knockback.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
safeStart = world.mechanic.lexue.selectionPageRect(1) + 0.5;
state.players(1).pos = [safeStart, 1];
state.players(2).pos = [safeStart + 1.5, 1];
state = stepWorldLexue(state, world, cfg, 0);
state.levelState.lexue.selectionOpen = true;
state.levelState.lexue.homeActive = true;

state = stepWorldLexue(state, world, cfg, 0.1);
assert(size(state.levelState.lexue.taskCards, 1) == 1, ...
    'Task storm did not begin with one bounded notification card.');
state = stepWorldLexue(state, world, cfg, 4.5);
assert(size(state.levelState.lexue.taskCards, 1) == 4, ...
    'Task storm did not release its small batches over time.');
assert(size(state.levelState.lexue.taskCards, 1) < 50, ...
    'Notification count was incorrectly turned into fifty entities.');

card = state.levelState.lexue.taskCards(1, :);
state.status.hitCooldown = 0;
state.players(1).pos = [card(1) + card(3) / 2, card(2)];
state.players(1).vel = [0, 0];
state = stepWorldLexue(state, world, cfg, 0);
assert(state.status.breakValue == cfg.break.minorIncrease, ...
    'Task-card contact did not raise break value by one.');
assert(any(abs(state.players(1).vel) > 0), ...
    'Task-card contact did not knock the player away.');
assert(~state.requestReset, ...
    'A single task card incorrectly caused a major reset.');
end
