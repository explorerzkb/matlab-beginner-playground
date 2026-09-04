function state = stepWorldAnimals(state, world, ~, dt)
%STEPWORLDANIMALS Move lake animals and apply the optional alpaca boost.

data = world.mechanic.animals;
if ~isfield(state.levelState, 'animals')
    state.levelState.animals.sneezeCooldown = 0;
    state.levelState.animals.sneezeWarning = 0;
    state.levelState.animals.sneezeTarget = 0;
    state.levelState.animals.shortcutReached = false;
end

[geeseRects, geeseDirections] = movingAnimalRects( ...
    data.geese, state.levelTime);
[duckRects, duckDirections] = movingAnimalRects( ...
    data.ducks, state.levelTime);
state.levelState.animals.geeseRects = geeseRects;
state.levelState.animals.duckRects = duckRects;
state.levelState.animals.geeseDirections = geeseDirections;
state.levelState.animals.duckDirections = duckDirections;
state.levelState.animals.alpacaRect = data.alpacaRect;
state.levelState.animals.softObstacleRects = [geeseRects; duckRects];
state.levelState.colliders = [state.levelState.colliders; ...
    data.alpacaCollider];
state = applyAnimalSoftPush(state, [geeseRects; duckRects], ...
    [geeseDirections; duckDirections], data, dt);

bridgeTop = max(data.shortcutPlatforms(:, 2) + ...
    data.shortcutPlatforms(:, 4));
playerAboveBridge = state.players(1).pos(2) > bridgeTop + 0.02 || ...
    state.players(2).pos(2) > bridgeTop + 0.02;
state.levelState.animals.shortcutSolid = ...
    state.levelState.animals.shortcutReached || playerAboveBridge;
if state.levelState.animals.shortcutSolid
    state.levelState.colliders = [state.levelState.colliders; ...
        data.shortcutPlatforms];
end

if ~state.levelState.animals.shortcutReached
    for playerIndex = 1:2
        if playerStandingOnAny(state.players(playerIndex), ...
                data.shortcutPlatforms)
            state.levelState.animals.shortcutReached = true;
            state.stats.alpacaShortcutUses = ...
                state.stats.alpacaShortcutUses + 1;
            break;
        end
    end
end

state.levelState.animals.sneezeCooldown = max(0, ...
    state.levelState.animals.sneezeCooldown - dt);
if state.levelState.animals.sneezeWarning > 0
    state.levelState.animals.sneezeWarning = max(0, ...
        state.levelState.animals.sneezeWarning - dt);
    if state.levelState.animals.sneezeWarning == 0
        target = state.levelState.animals.sneezeTarget;
        if target >= 1 && target <= 2
            direction = sign(state.players(target).pos(1) - ...
                (data.alpacaRect(1) + data.alpacaRect(3) / 2));
            if direction == 0
                direction = 1;
            end
            state.players(target).vel = state.players(target).vel + ...
                [direction * data.sneezeImpulse(1), data.sneezeImpulse(2)];
            state.stats.alpacaBoosts = state.stats.alpacaBoosts + 1;
        end
        state.levelState.animals.sneezeTarget = 0;
        state.levelState.animals.sneezeCooldown = data.sneezeCooldown;
    end
elseif state.levelState.animals.sneezeCooldown == 0
    for playerIndex = 1:2
        if playerOverlaps(state.players(playerIndex), data.alpacaNose)
            state.levelState.animals.sneezeWarning = data.sneezeWarning;
            state.levelState.animals.sneezeTarget = playerIndex;
            break;
        end
    end
end
end

function [rects, directions] = movingAnimalRects(data, levelTime)
rects = zeros(size(data, 1), 4);
directions = ones(size(data, 1), 1);
for index = 1:size(data, 1)
    row = data(index, :);
    phase = 2 * pi * levelTime / row(5) + row(7);
    x = row(1) + row(6) * 0.5 * (1 + sin(phase));
    rects(index, :) = [x, row(2), row(3), row(4)];
    directions(index) = sign(cos(phase));
    if directions(index) == 0
        directions(index) = 1;
    end
end
end

function state = applyAnimalSoftPush(state, rects, directions, data, dt)
% Animals communicate motion and yield under sustained player input. They do
% not enter the rigid collider list, so two animals can never form a lock.
for playerIndex = 1:2
    player = state.players(playerIndex);
    for animalIndex = 1:size(rects, 1)
        rect = rects(animalIndex, :);
        if ~playerOverlaps(player, rect)
            continue;
        end
        animalCentre = rect(1) + rect(3) / 2;
        if player.pos(1) < animalCentre
            escapeDirection = -1;
        elseif player.pos(1) > animalCentre
            escapeDirection = 1;
        else
            escapeDirection = -directions(animalIndex);
        end
        targetVelocity = escapeDirection * data.softPushSpeed;
        velocityChange = data.softPushAcceleration * dt;
        player.vel(1) = moveTowards(player.vel(1), ...
            targetVelocity, velocityChange);
    end
    state.players(playerIndex) = player;
end
end

function value = moveTowards(value, target, maximumChange)
if value < target
    value = min(target, value + maximumChange);
elseif value > target
    value = max(target, value - maximumChange);
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
