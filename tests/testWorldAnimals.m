function testWorldAnimals()
%TESTWORLDANIMALS Verify the extended mixed-animal route and alpaca impulse.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
animals = world.mechanic.animals;
northLakeWidth = diff(world.regions(2).xRange);
assert(northLakeWidth >= 2 * cfg.render.viewportWidth, ...
    'The North Lake animal route is shorter than two complete views.');
assert(size(animals.geese, 1) >= 4 && size(animals.ducks, 1) >= 3, ...
    'The extended route does not contain enough geese and ducks.');
assert(numel(unique(animals.geese(:, 5))) > 1 && ...
    numel(unique(animals.ducks(:, 3))) > 1, ...
    'Geese and ducks do not vary in movement rhythm and body size.');

nose = animals.alpacaNose;
state.players(1).pos = [nose(1) + nose(3) / 2, nose(2)];

state = stepWorldAnimals(state, world, cfg, 0.01);
assert(state.levelState.animals.sneezeWarning > 0, ...
    'Touching the alpaca nose did not start the warning.');
assert(size(state.levelState.animals.geeseRects, 1) == 4 && ...
    size(state.levelState.animals.duckRects, 1) == 4, ...
    'North Lake geese and ducks were not created as moving boundaries.');
expectedColliderCount = size(world.platforms, 1) + 4 + 4 + 1;
assert(size(state.levelState.colliders, 1) == expectedColliderCount, ...
    'Not every lake animal participates in collision.');

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
