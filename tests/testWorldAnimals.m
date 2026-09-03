function testWorldAnimals()
%TESTWORLDANIMALS Verify moving geese and one-shot alpaca impulse.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state.players(1).pos = [40.8, 1.55];

state = stepWorldAnimals(state, world, cfg, 0.01);
assert(state.levelState.animals.sneezeWarning > 0, ...
    'Touching the alpaca nose did not start the warning.');
assert(size(state.levelState.animals.geeseRects, 1) == 2, ...
    'North Lake geese were not created as moving boundaries.');

initialVelocity = state.players(1).vel;
for index = 1:10
    state = stepWorldAnimals(state, world, cfg, 0.05);
end
assert(state.players(1).vel(2) > initialVelocity(2), ...
    'Alpaca sneeze did not apply an upward impulse.');
assert(state.stats.alpacaBoosts == 1 && ...
    state.levelState.animals.sneezeCooldown > 0, ...
    'Alpaca boost did not latch into cooldown.');
end
