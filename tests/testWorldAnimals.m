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
state.players(1).pos = [nose(1) + nose(3) / 2, 1.0];

state = stepWorldAnimals(state, world, cfg, 0.01);
assert(state.levelState.animals.sneezeWarning > 0, ...
    'Touching the alpaca nose did not start the warning.');
assert(size(state.levelState.animals.geeseRects, 1) == 4 && ...
    size(state.levelState.animals.duckRects, 1) == 4, ...
    'North Lake geese and ducks were not created as moving boundaries.');
expectedColliderCount = size(world.platforms, 1) + 1;
assert(size(state.levelState.colliders, 1) == expectedColliderCount, ...
    'Geese or ducks still entered the rigid collider list.');
assert(size(state.levelState.animals.softObstacleRects, 1) == 8, ...
    'Not every goose and duck participates in soft pushback.');
assert(animals.softPushSpeed < cfg.physics.maxRunSpeed, ...
    'Animal pushback is too strong for a player to push through.');
assert(~state.levelState.animals.shortcutSolid, ...
    'The one-way red bridge blocked players before the sneeze flight.');

% Starting inside a goose must create a finite escape nudge without adding
% a rigid wall. This models the worst overlap caused by moving animals.
state.players(2).pos = [state.levelState.animals.geeseRects(1, 1) + ...
    state.levelState.animals.geeseRects(1, 3) / 2, 1.0];
state.players(2).vel = [0, 0];
state = stepWorldAnimals(state, world, cfg, 0.10);
assert(abs(state.players(2).vel(1)) > 0 && ...
    abs(state.players(2).vel(1)) <= animals.softPushSpeed + eps, ...
    'An overlapping animal did not provide a bounded escape nudge.');

% Two tethered players holding right must physically get past the first
% goose's entire patrol range before the next ground gap. This guards the
% player-facing promise that an animal can delay, but cannot seal the route.
pushState = createInitialState(world, cfg, []);
pushState.players(1).pos = [15.9, 1.0];
pushState.players(2).pos = [16.7, 1.0];
pushState.players(1).onGround = true;
pushState.players(2).onGround = true;
pushState = stepLevel(pushState, world, cfg, 0);
input = rightInput();
firstGooseRight = animals.geese(1, 1) + animals.geese(1, 3) + ...
    animals.geese(1, 6);
passedGoose = false;
for stepIndex = 1:round(1.5 / cfg.physics.fixedDt)
    pushState = stepPhysics(pushState, input, world, cfg, ...
        cfg.physics.fixedDt);
    pushState = stepLevel(pushState, world, cfg, cfg.physics.fixedDt);
    playerXs = arrayfun(@(player) player.pos(1), pushState.players);
    if all(playerXs > firstGooseRight)
        passedGoose = true;
        break;
    end
end
assert(passedGoose, ...
    'Two tethered players could not force through the first moving goose.');

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

function input = rightInput()
for playerIndex = 1:2
    input.player(playerIndex).left = false;
    input.player(playerIndex).right = true;
    input.player(playerIndex).jump = false;
end
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end
