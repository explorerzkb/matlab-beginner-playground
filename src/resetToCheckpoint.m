function state = resetToCheckpoint(state, level)
%RESETTOCHECKPOINT Reset both players together and preserve earned progress.

if strcmp(level.mechanic.type, 'navigation') && ...
        ~state.levelState.auxCreated
    state = createTrajectoryAid(state);
end

spawn = level.checkpoints(state.checkpointIndex).spawn;
for playerIndex = 1:2
    state.players(playerIndex).pos = spawn(playerIndex, :);
    state.players(playerIndex).vel = [0, 0];
    state.players(playerIndex).onGround = false;
    state.players(playerIndex).jumpHeld = false;
end
if strcmp(level.mechanic.type, 'continuousCampus')
    state = resetContinuousTransients(state, level);
end
state.rope.currentTension = 0;
state.rope.tautLast = false;
state.input.resetHeldTime = 0;
state.requestReset = false;
state.stats.failures = state.stats.failures + 1;
end

function state = resetContinuousTransients(state, world)
traffic = world.mechanic.traffic;
crosswalk = traffic.crosswalk;
cars = traffic.carData(:, 1:4);
for carIndex = 1:size(cars, 1)
    if traffic.carData(carIndex, 6) > 0
        cars(carIndex, 1) = crosswalk(1) - traffic.stopLineGap - ...
            cars(carIndex, 3);
    else
        cars(carIndex, 1) = crosswalk(1) + crosswalk(3) + ...
            traffic.stopLineGap;
    end
end
state.levelState.traffic.cars = cars;
state.levelState.traffic.signalClock = ...
    sum(traffic.signalPhaseDurations(1:2));
state.levelState.traffic.signalPhase = 'allRedBeforePed';
state.levelState.traffic.signalProgress = 0;
state.levelState.traffic.carsMayMove = false;
state.levelState.traffic.pedestriansMayCross = false;
state.levelState.traffic.fountainClock = ...
    traffic.fountainActiveDuration + 0.05;
state.levelState.traffic.fountainPhase = ...
    state.levelState.traffic.fountainClock;
state.levelState.traffic.jetActive = false;
state.levelState.traffic.fountainCooldowns(:) = 0;
state.levelState.traffic.crowd = traffic.crowdData(:, 1:4);
state.levelState.dynamicObjects.traffic.cars = cars;
state.levelState.dynamicObjects.traffic.crowd = ...
    traffic.crowdData(:, 1:4);

state.levelState.lexue.taskElapsed = ...
    -world.mechanic.lexue.taskResetGrace;
state.levelState.lexue.taskCards = zeros(0, 4);
state.levelState.dynamicObjects.lexue.taskCards = zeros(0, 4);
state.levelState.animals.sneezeWarning = 0;
state.levelState.animals.sneezeTarget = 0;
state.levelState.network.credentialsTimer = 0;
state.levelState.network.loginTimer = 0;
state.status.hitCooldown = 0;
state.inventory.useHeldTime = 0;
state.inventory.useLatched = false;
state.completed = false;
end

function state = createTrajectoryAid(state)
% Freeze only points the players actually traversed; never invent a route.
trajectory = state.levelTrajectory;
state.levelState.auxCreated = true;
if size(trajectory, 1) < 2
    return;
end

averageX = mean(trajectory(:, [2, 4]), 2);
averageY = mean(trajectory(:, [3, 5]), 2);
keep = averageX >= 13.5 & averageX <= 25.8 & averageY >= 0.8;
points = [averageX(keep), averageY(keep)];
if size(points, 1) < 2
    return;
end

[~, order] = sort(points(:, 1));
points = points(order, :);
selected = points(1, :);
for index = 2:size(points, 1)
    if points(index, 1) - selected(end, 1) >= 0.8
        selected(end + 1, :) = points(index, :); %#ok<AGROW>
    end
end
if size(selected, 1) < 2
    return;
end

platforms = zeros(size(selected, 1), 4);
for index = 1:size(selected, 1)
    platforms(index, :) = [selected(index, 1) - 0.55, ...
        max(0.7, selected(index, 2) - 0.18), 1.1, 0.18];
end
state.levelState.auxCurve = selected;
state.levelState.auxPlatforms = platforms;
end
