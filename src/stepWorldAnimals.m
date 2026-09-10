function state = stepWorldAnimals(state, world, cfg, dt)
%STEPWORLDANIMALS Run solid lake animals, alpaca kick, and peacock bounce.

data = world.mechanic.animals;
allData = [data.geese; data.ducks];
animalCount = size(allData, 1);
if ~isfield(state.levelState, 'animals')
    state.levelState.animals = initialAnimalState( ...
        allData, state.levelTime, data);
end
animals = state.levelState.animals;
animals = ensureAnimalFields(animals, allData, state.levelTime, data);

[animals, yieldVelocity] = advanceYieldMotion(animals, data, dt);
[allRects, allDirections, allVelocities] = movingAnimalRects( ...
    allData, state.levelTime, animals.yieldOffsets, yieldVelocity);
previousRects = animals.previousEntityRects;
if size(previousRects, 1) ~= animalCount
    previousRects = allRects;
end
playerLeft = min([state.players(1).pos(1) - state.players(1).size(1) / 2, ...
    state.players(2).pos(1) - state.players(2).size(1) / 2]) - 0.35;
playerRight = max([state.players(1).pos(1) + state.players(1).size(1) / 2, ...
    state.players(2).pos(1) + state.players(2).size(1) / 2]) + 0.35;
nearbyAnimals = find(allRects(:, 1) + allRects(:, 3) >= playerLeft & ...
    allRects(:, 1) <= playerRight);
for animalIndex = nearbyAnimals(:)'
    state = carryPlayersWithPlatform(state, ...
        previousRects(animalIndex, :), allRects(animalIndex, :));
end

gooseCount = size(data.geese, 1);
animals.geeseRects = allRects(1:gooseCount, :);
animals.duckRects = allRects(gooseCount + 1:end, :);
animals.geeseDirections = allDirections(1:gooseCount);
animals.duckDirections = allDirections(gooseCount + 1:end);
animals.entityColliderRects = allRects;
animals.previousEntityRects = allRects;
animals.alpacaRect = data.alpacaRect;

% Ducks and geese are real rigid bodies. Their previous position was used
% for rider carry; the current position becomes next physics step's solid.
state.levelState.colliders = [state.levelState.colliders; allRects];
[animals, pushed] = updateAnimalPushTimers( ...
    animals, state.players, allRects, nearbyAnimals, data, dt);
if pushed
    animals.previousEntityRects = allRects;
end
state.levelState.animals = animals;
state = applyHeadOnAnimalDamage(state, allRects, allVelocities, ...
    nearbyAnimals, data, cfg);
animals = state.levelState.animals;

bridgeTop = max(data.shortcutPlatforms(:, 2) + ...
    data.shortcutPlatforms(:, 4));
playerAboveBridge = state.players(1).pos(2) > bridgeTop + 0.02 || ...
    state.players(2).pos(2) > bridgeTop + 0.02;
animals.shortcutSolid = animals.shortcutReached || playerAboveBridge;
% The deck always catches descending pears, including the partner arriving
% after the first landing. A solid underside would cancel their bounce.
state.levelState.oneWayPlatforms = [state.levelState.oneWayPlatforms; ...
    data.shortcutPlatforms];
if ~animals.shortcutReached
    for playerIndex = 1:2
        if playerStandingOnAny(state.players(playerIndex), ...
                data.shortcutPlatforms)
            animals.shortcutReached = true;
            state.stats.alpacaShortcutUses = ...
                state.stats.alpacaShortcutUses + 1;
            break;
        end
    end
end

[state, animals] = stepAlpacaKick(state, animals, data, dt);
[state, animals] = stepPeacockBounce(state, animals, data, dt);
state.levelState.animals = animals;
end

function animals = initialAnimalState(allData, levelTime, data)
count = size(allData, 1);
[rects, ~, ~] = movingAnimalRects(allData, levelTime, zeros(count, 1), ...
    zeros(count, 1));
animals.yieldOffsets = zeros(count, 1);
animals.yieldRemaining = zeros(count, 1);
animals.yieldDirections = zeros(count, 1);
animals.pushTimers = zeros(count, 2);
animals.previousEntityRects = rects;
animals.shortcutReached = false;
animals.shortcutSolid = false;
animals.kickCooldown = 0;
animals.kickWarning = 0;
animals.kickTarget = 0;
animals.peacockOpen = false;
animals.peacockCooldowns = zeros(1, 2);
animals.peacockRect = data.peacockRect;
animals.fieldsReady = true;
end

function animals = ensureAnimalFields(animals, allData, levelTime, data)
if isfield(animals, 'fieldsReady') && animals.fieldsReady
    return;
end
defaults = initialAnimalState(allData, levelTime, data);
names = fieldnames(defaults);
for index = 1:numel(names)
    name = names{index};
    if ~isfield(animals, name)
        animals.(name) = defaults.(name);
    end
end
animals.fieldsReady = true;
end

function [animals, velocity] = advanceYieldMotion(animals, data, dt)
velocity = zeros(size(animals.yieldRemaining));
moving = animals.yieldRemaining > 0 & animals.yieldDirections ~= 0;
distance = min(animals.yieldRemaining(moving), data.yieldSpeed * dt);
animals.yieldOffsets(moving) = animals.yieldOffsets(moving) + ...
    animals.yieldDirections(moving) .* distance;
animals.yieldRemaining(moving) = animals.yieldRemaining(moving) - distance;
if dt > 0
    velocity(moving) = animals.yieldDirections(moving) .* distance / dt;
end
end

function [rects, directions, velocities] = movingAnimalRects( ...
        data, levelTime, offsets, yieldVelocity)
phase = 2 * pi * levelTime ./ data(:, 5) + data(:, 7);
x = data(:, 1) + data(:, 6) .* 0.5 .* (1 + sin(phase)) + offsets;
velocities = data(:, 6) .* pi ./ data(:, 5) .* cos(phase) + yieldVelocity;
rects = [x, data(:, 2:4)];
directions = sign(velocities);
directions(directions == 0) = 1;
end

function [animals, pushed] = updateAnimalPushTimers( ...
        animals, players, rects, nearbyAnimals, data, dt)
pushed = false;
farAnimals = true(size(rects, 1), 1);
farAnimals(nearbyAnimals) = false;
animals.pushTimers(farAnimals, :) = max(0, ...
    animals.pushTimers(farAnimals, :) - 2 * dt);
for animalIndex = nearbyAnimals(:)'
    for playerIndex = 1:2
        pushDirection = playerPushDirection( ...
            players(playerIndex), rects(animalIndex, :));
        if pushDirection == 0 || animals.yieldRemaining(animalIndex) > 0
            animals.pushTimers(animalIndex, playerIndex) = max(0, ...
                animals.pushTimers(animalIndex, playerIndex) - 2 * dt);
            continue;
        end
        animals.pushTimers(animalIndex, playerIndex) = ...
            animals.pushTimers(animalIndex, playerIndex) + dt;
        if animals.pushTimers(animalIndex, playerIndex) >= ...
                data.pushHoldDuration
            animals.yieldRemaining(animalIndex) = data.yieldDistance;
            animals.yieldDirections(animalIndex) = pushDirection;
            animals.pushTimers(animalIndex, :) = 0;
            pushed = true;
        end
    end
end
end

function direction = playerPushDirection(player, rect)
direction = 0;
halfWidth = player.size(1) / 2;
vertical = player.pos(2) + player.size(2) > rect(2) + 0.08 && ...
    player.pos(2) < rect(2) + rect(4) - 0.08;
if ~vertical
    return;
end
leftGap = abs(player.pos(1) + halfWidth - rect(1));
rightGap = abs(player.pos(1) - halfWidth - (rect(1) + rect(3)));
if leftGap <= 0.10 && player.moveIntent > 0
    direction = 1;
elseif rightGap <= 0.10 && player.moveIntent < 0
    direction = -1;
end
end

function state = applyHeadOnAnimalDamage( ...
        state, rects, velocities, nearbyAnimals, data, cfg)
for animalIndex = nearbyAnimals(:)'
    animalVelocity = velocities(animalIndex);
    if abs(animalVelocity) < data.chargeSpeedThreshold
        continue;
    end
    rect = rects(animalIndex, :);
    for playerIndex = 1:2
        player = state.players(playerIndex);
        side = horizontalContactSide(player, rect);
        if side == 0
            continue;
        end
        if isfield(player, 'preCollisionVelocityX')
            playerVelocity = player.preCollisionVelocityX;
        else
            playerVelocity = player.vel(1);
        end
        animalMovingTowardPlayer = sign(animalVelocity) == side;
        playerMovingTowardAnimal = sign(playerVelocity) == -side;
        relativeSpeed = abs(playerVelocity - animalVelocity);
        if animalMovingTowardPlayer && playerMovingTowardAnimal && ...
                relativeSpeed >= data.headOnRelativeSpeed
            [state, applied] = applyDamageEvent(state, cfg, 'minor');
            if applied
                state.players(playerIndex).visualImpactTimer = 0.38;
                state.players(playerIndex).visualImpactKind = 'animal';
                state.players(playerIndex).vel(1) = ...
                    2.2 * side;
            end
            return;
        end
    end
end
end

function side = horizontalContactSide(player, rect)
side = 0;
halfWidth = player.size(1) / 2;
vertical = player.pos(2) + player.size(2) > rect(2) + 0.08 && ...
    player.pos(2) < rect(2) + rect(4) - 0.08;
if ~vertical
    return;
end
leftGap = abs(player.pos(1) + halfWidth - rect(1));
rightGap = abs(player.pos(1) - halfWidth - (rect(1) + rect(3)));
if leftGap <= 0.12
    side = -1;
elseif rightGap <= 0.12
    side = 1;
end
end

function [state, animals] = stepAlpacaKick(state, animals, data, dt)
animals.kickCooldown = max(0, animals.kickCooldown - dt);
if animals.kickWarning > 0
    animals.kickWarning = max(0, animals.kickWarning - dt);
    if animals.kickWarning == 0
        target = animals.kickTarget;
        if target >= 1 && target <= 2
            state.players(target).vel = state.players(target).vel + ...
                data.kickImpulse;
            state.players(target).onGround = false;
            for p=1:2
                state.players(p).environmentBoostTime = 1.0;
            end
            state.players(target).visualImpactTimer = 0.32;
            state.players(target).visualImpactKind = 'kick';
            state.stats.alpacaBoosts = state.stats.alpacaBoosts + 1;
        end
        animals.kickTarget = 0;
        animals.kickCooldown = data.kickCooldown;
    end
elseif animals.kickCooldown == 0
    for playerIndex = 1:2
        if playerOverlaps(state.players(playerIndex), data.alpacaRearZone)
            animals.kickWarning = data.kickWarning;
            animals.kickTarget = playerIndex;
            break;
        end
    end
end
end

function [state, animals] = stepPeacockBounce(state, animals, data, dt)
animals.peacockCooldowns = max(0, animals.peacockCooldowns - dt);
phase = mod(state.levelTime, data.peacockPeriod);
animals.peacockOpen = phase < data.peacockOpenDuration;
animals.peacockRect = data.peacockRect;
if ~animals.peacockOpen
    return;
end
for playerIndex = 1:2
    if animals.peacockCooldowns(playerIndex) == 0 && ...
            playerOverlaps(state.players(playerIndex), data.peacockBounceZone)
        state.players(playerIndex).vel(1) = max( ...
            state.players(playerIndex).vel(1), data.peacockImpulse(1));
        state.players(playerIndex).vel(2) = max( ...
            state.players(playerIndex).vel(2), data.peacockImpulse(2));
        state.players(playerIndex).onGround = false;
        for p=1:2
            state.players(p).environmentBoostTime = 1.0;
        end
        animals.peacockCooldowns(playerIndex) = data.peacockCooldown;
    end
end
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end

function tf = playerStandingOnAny(player, rects)
tf = false;
halfWidth = player.size(1) / 2;
for index = 1:size(rects, 1)
    rect = rects(index, :);
    horizontallyInside = player.pos(1) + halfWidth > rect(1) && ...
        player.pos(1) - halfWidth < rect(1) + rect(3);
    onTop = abs(player.pos(2) - (rect(2) + rect(4))) <= 0.08;
    if horizontallyInside && onTop
        tf = true;
        return;
    end
end
end
