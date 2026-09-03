function state = stepWorldLexue(state, world, cfg, dt)
%STEPWORLDLEXUE Advance the physical course-selection page.

lexue = world.mechanic.lexue;
if ~isfield(state.levelState, 'lexue')
    state.levelState.lexue.entered = false;
    state.levelState.lexue.elapsed = 0;
    state.levelState.lexue.lastFlipIndex = 0;
    state.levelState.lexue.selectionOpen = false;
    state.levelState.lexue.startTimer = 0;
    state.levelState.lexue.startPressLatched = false;
    state.levelState.lexue.homeActive = false;
    state.levelState.lexue.feedback = 'countdown';
    state.levelState.lexue.courseCardReached = false;
end
if ~isfield(state.levelState.lexue, 'taskElapsed')
    state.levelState.lexue.taskElapsed = 0;
    state.levelState.lexue.taskCards = zeros(0, 4);
end

centreX = mean([state.players(1).pos(1), state.players(2).pos(1)]);
if centreX >= world.regions(5).xRange(1)
    state.levelState.lexue.entered = true;
end

flipNow = false;
if state.levelState.lexue.entered && ...
        ~state.levelState.lexue.selectionOpen
    previousFlipIndex = state.levelState.lexue.lastFlipIndex;
    state.levelState.lexue.elapsed = min(lexue.countdownDuration, ...
        state.levelState.lexue.elapsed + dt);
    currentFlipIndex = floor(state.levelState.lexue.elapsed + 1e-9);
    flipNow = currentFlipIndex > previousFlipIndex;
    state.levelState.lexue.lastFlipIndex = currentFlipIndex;
    if state.levelState.lexue.elapsed >= lexue.countdownDuration
        state.levelState.lexue.selectionOpen = true;
    end
end

if flipNow
    for playerIndex = 1:2
        if standingOnAny(state.players(playerIndex), ...
                lexue.countdownPlatforms)
            state.players(playerIndex).vel(2) = max( ...
                state.players(playerIndex).vel(2), lexue.flipImpulse);
        end
    end
end

fraction = mod(state.levelState.lexue.elapsed, 1);
timeUntilFlip = 1 - fraction;
warning = state.levelState.lexue.entered && ...
    ~state.levelState.lexue.selectionOpen && ...
    timeUntilFlip <= lexue.flipWarningDuration;
remaining = max(0, ceil(lexue.countdownDuration - ...
    state.levelState.lexue.elapsed));

bothOnStart = all(playersInRect(state.players, lexue.startButtonZone));
if bothOnStart && ~state.levelState.lexue.startPressLatched
    state.stats.selectionAttempts = state.stats.selectionAttempts + 1;
    state.levelState.lexue.startPressLatched = true;
elseif ~bothOnStart
    state.levelState.lexue.startPressLatched = false;
end
if state.levelState.lexue.homeActive
    state.levelState.lexue.feedback = 'success';
elseif ~state.levelState.lexue.selectionOpen
    state.levelState.lexue.startTimer = 0;
    state.levelState.lexue.feedback = 'countdown';
elseif bothOnStart
    state.levelState.lexue.feedback = 'holding';
    state.levelState.lexue.startTimer = min(lexue.startHoldDuration, ...
        state.levelState.lexue.startTimer + dt);
    if state.levelState.lexue.startTimer >= lexue.startHoldDuration
        state.levelState.lexue.homeActive = true;
        state.levelState.lexue.feedback = 'success';
    end
else
    state.levelState.lexue.startTimer = max(0, ...
        state.levelState.lexue.startTimer - 1.5 * dt);
    state.levelState.lexue.feedback = 'ready';
end
if state.levelState.lexue.homeActive && ...
        any(playersInRect(state.players, lexue.courseCardZone))
    state.levelState.lexue.courseCardReached = true;
end

if state.levelState.lexue.homeActive
    state.levelState.lexue.taskElapsed = ...
        state.levelState.lexue.taskElapsed + dt;
end
cardData = lexue.taskCardData;
active = state.levelState.lexue.taskElapsed >= cardData(:, 9);
activeData = cardData(active, :);
taskCards = zeros(size(activeData, 1), 4);
for cardIndex = 1:size(activeData, 1)
    row = activeData(cardIndex, :);
    offset = row(5) * sin(2 * pi * ...
        state.levelState.lexue.taskElapsed / row(6) + row(7));
    taskCards(cardIndex, :) = row(1:4);
    if row(8) == 1
        taskCards(cardIndex, 2) = taskCards(cardIndex, 2) + offset;
    else
        taskCards(cardIndex, 1) = taskCards(cardIndex, 1) + offset;
    end
end
state.levelState.lexue.taskCards = taskCards;

knockbackMultiplier = 1;
if state.inventory.buffTimer > 0
    knockbackMultiplier = cfg.tea.knockbackMultiplier;
end
hitPlayer = 0;
hitCard = 0;
for cardIndex = 1:size(taskCards, 1)
    touching = playersInRect(state.players, taskCards(cardIndex, :));
    hitPlayer = find(touching, 1, 'first');
    if ~isempty(hitPlayer)
        hitCard = cardIndex;
        break;
    end
end
if ~isempty(hitPlayer) && hitPlayer > 0
    [state, applied] = applyBreakEvent(state, cfg, 'minor');
    if applied
        card = taskCards(hitCard, :);
        direction = sign(state.players(hitPlayer).pos(1) - ...
            (card(1) + card(3) / 2));
        if direction == 0
            direction = -1;
        end
        state.players(hitPlayer).vel(1) = min(max( ...
            state.players(hitPlayer).vel(1) + direction * ...
            lexue.taskKnockback(1) * knockbackMultiplier, ...
            -lexue.taskHorizontalSpeedCap), lexue.taskHorizontalSpeedCap);
        state.players(hitPlayer).vel(2) = max( ...
            state.players(hitPlayer).vel(2), ...
            lexue.taskKnockback(2) * knockbackMultiplier);
    end
end

state.levelState.colliders = [state.levelState.colliders; ...
    lexue.countdownPlatforms; lexue.startButtonPlatform; ...
    lexue.courseCardPlatform];
state.levelState.colliders = removeRect( ...
    state.levelState.colliders, lexue.selectionGate);
if ~state.levelState.lexue.homeActive
    state.levelState.colliders = [state.levelState.colliders; ...
        lexue.selectionGate];
end
state.levelState.lexue.flipWarning = warning;
state.levelState.lexue.flipNow = flipNow;
state.levelState.lexue.remaining = remaining;
state.levelState.dynamicObjects.lexue.countdownPlatforms = ...
    lexue.countdownPlatforms;
state.levelState.dynamicObjects.lexue.startButton = ...
    lexue.startButtonPlatform;
state.levelState.dynamicObjects.lexue.selectionGate = lexue.selectionGate;
state.levelState.dynamicObjects.lexue.courseCard = ...
    lexue.courseCardPlatform;
state.levelState.dynamicObjects.lexue.taskCards = taskCards;
state.levelState.dynamicObjects.lexue.notificationCount = 50;
end

function rects = removeRect(rects, target)
if isempty(rects)
    return;
end
matching = all(abs(rects - target) < 1e-9, 2);
rects(matching, :) = [];
end

function occupancy = playersInRect(players, rect)
occupancy = false(1, 2);
for playerIndex = 1:2
    occupancy(playerIndex) = playerOverlaps(players(playerIndex), rect);
end
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end

function tf = standingOnAny(player, rects)
tf = false;
halfWidth = player.size(1) / 2;
for index = 1:size(rects, 1)
    rect = rects(index, :);
    horizontal = player.pos(1) + halfWidth > rect(1) && ...
        player.pos(1) - halfWidth < rect(1) + rect(3);
    onTop = abs(player.pos(2) - (rect(2) + rect(4))) <= 0.10;
    if horizontal && onTop
        tf = true;
        return;
    end
end
end
