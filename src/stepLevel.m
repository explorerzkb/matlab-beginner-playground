function state = stepLevel(state, level, ~, dt)
%STEPLEVEL Update level mechanics, checkpoints, failure, and completion.

state.levelTime = state.levelTime + dt;
state.stats.elapsed = state.stats.elapsed + dt;
state.levelState.colliders = level.platforms;
dynamicHazards = level.hazards;

switch level.mechanic.type
    case 'geese'
        geeseData = level.mechanic.geese;
        geeseRects = zeros(size(geeseData, 1), 4);
        for index = 1:size(geeseData, 1)
            row = geeseData(index, :);
            x = row(1) + row(6) * 0.5 * ...
                (1 + sin(2 * pi * state.levelTime / row(5) + row(7)));
            geeseRects(index, :) = [x, row(2), row(3), row(4)];
        end
        state.levelState.dynamicObjects.geese = geeseRects;
        state.levelState.colliders = [state.levelState.colliders; geeseRects];

    case 'loginCard'
        card = level.mechanic.cardBase;
        if state.levelTime < level.mechanic.fallDuration
            progress = state.levelTime / level.mechanic.fallDuration;
            smoothProgress = progress * progress * (3 - 2 * progress);
            card(2) = card(2) + level.mechanic.fallHeight * ...
                (1 - smoothProgress);
            cardAngle = -0.055 * (1 - smoothProgress);
        else
            localTime = state.levelTime - level.mechanic.fallDuration;
            card(2) = card(2) + level.mechanic.cardAmplitude * ...
                (0.5 + 0.5 * sin(2 * pi * localTime / ...
                level.mechanic.cardPeriod - pi / 2));
            cardAngle = 0.025 * sin(2 * pi * localTime / ...
                level.mechanic.cardPeriod);
        end
        state.levelState.dynamicObjects.loginCard = card;
        state.levelState.dynamicObjects.loginCardAngle = cardAngle;
        state.levelState.colliders = [state.levelState.colliders; card];

    case 'navigation'
        zones = level.mechanic.switches;
        player1Zone1 = playerOverlaps(state.players(1), zones(1, :));
        player1Zone2 = playerOverlaps(state.players(1), zones(2, :));
        player2Zone1 = playerOverlaps(state.players(2), zones(1, :));
        player2Zone2 = playerOverlaps(state.players(2), zones(2, :));
        bothConfirmed = (player1Zone1 && player2Zone2) || ...
            (player1Zone2 && player2Zone1);

        if bothConfirmed
            state.levelState.confirmTimer = min( ...
                level.mechanic.confirmDuration, ...
                state.levelState.confirmTimer + dt);
        else
            state.levelState.confirmTimer = max(0, ...
                state.levelState.confirmTimer - 1.5 * dt);
        end

        if state.levelState.confirmTimer >= level.mechanic.confirmDuration
            state.levelState.routeActive = true;
            state.levelState.routeTimer = level.mechanic.activeDuration;
        elseif state.levelState.routeActive
            state.levelState.routeTimer = state.levelState.routeTimer - dt;
            if state.levelState.routeTimer <= 0
                state.levelState.routeActive = false;
                state.levelState.routeTimer = 0;
            end
        end

        if state.levelState.routeActive
            state.levelState.colliders = [state.levelState.colliders; ...
                level.mechanic.routePlatforms];
        end
        if ~isempty(state.levelState.auxPlatforms)
            state.levelState.colliders = [state.levelState.colliders; ...
                state.levelState.auxPlatforms];
        end
        state.levelState.dynamicObjects.switches = zones;

    case 'deadlineStorm'
        if ~isfield(state.levelState, 'environmentTime')
            state.levelState.environmentTime = 0;
        end
        environmentScale = 1;
        if state.levelState.slowTimer > 0
            environmentScale = level.mechanic.slowScale;
            state.levelState.slowTimer = max(0, state.levelState.slowTimer - dt);
        end
        state.levelState.environmentTime = state.levelState.environmentTime + ...
            dt * environmentScale;

        if ~state.levelState.bottleCollected && ...
                (playerOverlaps(state.players(1), level.mechanic.bottle) || ...
                 playerOverlaps(state.players(2), level.mechanic.bottle))
            state.levelState.bottleCollected = true;
            state.levelState.slowTimer = level.mechanic.slowDuration;
        end

        cardData = level.mechanic.cards;
        cards = zeros(size(cardData, 1), 4);
        for index = 1:size(cardData, 1)
            row = cardData(index, :);
            offset = row(5) * sin(2 * pi * ...
                state.levelState.environmentTime / row(6) + row(7));
            if row(8) == 1
                cards(index, :) = [row(1), row(2) + offset, row(3), row(4)];
            else
                cards(index, :) = [row(1) + offset, row(2), row(3), row(4)];
            end
        end
        state.levelState.dynamicObjects.taskCards = cards;
        dynamicHazards = [dynamicHazards; cards];
end

minimumX = min(state.players(1).pos(1), state.players(2).pos(1));
for index = state.checkpointIndex + 1:numel(level.checkpoints)
    if minimumX >= level.checkpoints(index).x
        state.checkpointIndex = index;
    end
end

if state.players(1).pos(2) < level.killY || ...
        state.players(2).pos(2) < level.killY
    state.requestReset = true;
end
for index = 1:size(dynamicHazards, 1)
    if playerOverlaps(state.players(1), dynamicHazards(index, :)) || ...
            playerOverlaps(state.players(2), dynamicHazards(index, :))
        state.requestReset = true;
        break;
    end
end

state.completed = playerOverlaps(state.players(1), level.finish) && ...
    playerOverlaps(state.players(2), level.finish);

state.trajectorySampleClock = state.trajectorySampleClock + dt;
if state.trajectorySampleClock >= 0.1
    state.trajectorySampleClock = state.trajectorySampleClock - 0.1;
    sample = [state.levelTime, state.players(1).pos, state.players(2).pos];
    state.levelTrajectory(end + 1, :) = sample;
    state.stats.trajectory(end + 1, :) = [level.id, state.stats.elapsed, ...
        state.players(1).pos, state.players(2).pos];
end

if any(~isfinite([state.players(1).pos, state.players(1).vel, ...
        state.players(2).pos, state.players(2).vel]))
    error('matlabHi:NonFinitePhysics', ...
        '物理状态出现 NaN 或 Inf，游戏已安全停止。');
end
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
