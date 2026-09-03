function state = stepWorldAnimals(state, world, ~, dt)
%STEPWORLDANIMALS Move geese and apply the optional alpaca sneeze boost.

data = world.mechanic.animals;
if ~isfield(state.levelState, 'animals')
    state.levelState.animals.sneezeCooldown = 0;
    state.levelState.animals.sneezeWarning = 0;
    state.levelState.animals.sneezeTarget = 0;
end

geese = data.geese;
geeseRects = zeros(size(geese, 1), 4);
for index = 1:size(geese, 1)
    row = geese(index, :);
    x = row(1) + row(6) * 0.5 * ...
        (1 + sin(2 * pi * state.levelTime / row(5) + row(7)));
    geeseRects(index, :) = [x, row(2), row(3), row(4)];
end
state.levelState.animals.geeseRects = geeseRects;
state.levelState.animals.alpacaRect = data.alpacaRect;
state.levelState.colliders = [state.levelState.colliders; ...
    geeseRects; data.alpacaRect];

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

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
