function testWorldAnimals()
%TESTWORLDANIMALS Verify solid riders, yielding, damage, kick, and bounce.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
animals = world.mechanic.animals;
state = createInitialState(world, cfg, []);
state = stepLevel(state, world, cfg, 0);

assert(size(state.levelState.animals.entityColliderRects, 1) == 8, ...
    'Not every duck and goose became a physical entity collider.');
for index = 1:size(state.levelState.animals.entityColliderRects, 1)
    assert(hasRect(state.levelState.colliders, ...
        state.levelState.animals.entityColliderRects(index, :)), ...
        'A visible duck or goose is missing from the collider list.');
end

% A pear already standing on a back must inherit the animal displacement.
firstRect = state.levelState.animals.entityColliderRects(1, :);
state.players(1).pos = [firstRect(1) + 0.5 * firstRect(3), ...
    firstRect(2) + firstRect(4)];
oldX = state.players(1).pos(1);
state = stepLevel(state, world, cfg, 0.10);
newRect = state.levelState.animals.entityColliderRects(1, :);
assert(abs((state.players(1).pos(1) - oldX) - ...
    (newRect(1) - firstRect(1))) < 1e-9, ...
    'A pear standing on an animal was not carried by its movement.');

% Sustained pushing should start one bounded 1.2-unit retreat.
pushState = createInitialState(world, cfg, []);
pushState.levelTime = animals.geese(1, 5) / 4;
pushState = stepWorldAnimals(pushState, world, cfg, 0);
rect = pushState.levelState.animals.entityColliderRects(1, :);
pushState.players(1).pos = [rect(1) - cfg.player.width / 2, rect(2)];
pushState.players(1).moveIntent = 1;
for index = 1:ceil(animals.pushHoldDuration / cfg.physics.fixedDt) + 1
    pushState = stepWorldAnimals(pushState, world, cfg, ...
        cfg.physics.fixedDt);
end
assert(pushState.levelState.animals.yieldRemaining(1) > 0 && ...
    pushState.levelState.animals.yieldDirections(1) == 1, ...
    'Sustained rightward pressure did not make the animal yield right.');
for index = 1:ceil(animals.yieldDistance / ...
        (animals.yieldSpeed * cfg.physics.fixedDt)) + 1
    pushState = stepWorldAnimals(pushState, world, cfg, ...
        cfg.physics.fixedDt);
end
assert(abs(pushState.levelState.animals.yieldOffsets(1) - ...
    animals.yieldDistance) < 1e-8, ...
    'The yielding animal did not retreat by the configured distance.');

% Only an active head-on meeting at sufficient relative speed costs a heart.
hitState = createInitialState(world, cfg, []);
hitState = stepWorldAnimals(hitState, world, cfg, 0);
rect = hitState.levelState.animals.entityColliderRects(1, :);
hitState.players(1).pos = [rect(1) + rect(3) + ...
    cfg.player.width / 2, rect(2)];
hitState.players(1).preCollisionVelocityX = -4.0;
hitState.players(1).moveIntent = -1;
hitState = stepWorldAnimals(hitState, world, cfg, 0);
assert(hitState.status.currentHearts == cfg.health.maxHearts - 1, ...
    'A configured active head-on animal collision did not cost one heart.');

safeState = createInitialState(world, cfg, []);
safeState = stepWorldAnimals(safeState, world, cfg, 0);
rect = safeState.levelState.animals.entityColliderRects(1, :);
safeState.players(1).pos = [rect(1) + 0.5 * rect(3), ...
    rect(2) + rect(4)];
safeState.players(1).preCollisionVelocityX = -8;
safeState = stepWorldAnimals(safeState, world, cfg, 0);
assert(safeState.status.currentHearts == cfg.health.maxHearts, ...
    'Standing on an animal incorrectly caused heart damage.');

% The alpaca is pass-through; entering its right-rear zone starts a kick.
kickState = createInitialState(world, cfg, []);
rear = animals.alpacaRearZone;
kickState.players(1).pos = [rear(1) + 0.5 * rear(3), rear(2)];
kickState = stepWorldAnimals(kickState, world, cfg, 0);
assert(kickState.levelState.animals.kickWarning > 0, ...
    'Crossing behind the left-facing alpaca did not start its kick warning.');
for index = 1:ceil(animals.kickWarning / cfg.physics.fixedDt) + 1
    kickState = stepWorldAnimals(kickState, world, cfg, ...
        cfg.physics.fixedDt);
end
assert(kickState.players(1).vel(1) > 0 && ...
    kickState.players(1).vel(2) > 0 && ...
    kickState.stats.alpacaBoosts == 1, ...
    'The alpaca kick did not launch its target up and right exactly once.');

% An open peacock provides a harmless upward recovery impulse.
peacockState = createInitialState(world, cfg, []);
zone = animals.peacockBounceZone;
peacockState.players(1).pos = [zone(1) + 0.5 * zone(3), zone(2)];
peacockState = stepWorldAnimals(peacockState, world, cfg, 0);
assert(peacockState.levelState.animals.peacockOpen && ...
    peacockState.players(1).vel(2) >= animals.peacockImpulse(2) && ...
    peacockState.status.currentHearts == cfg.health.maxHearts, ...
    'The open peacock did not provide a harmless upward bounce.');
end

function tf = hasRect(rects, target)
tf = any(all(abs(rects - target) < 1e-9, 2));
end
