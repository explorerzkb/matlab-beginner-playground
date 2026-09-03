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
state.rope.currentTension = 0;
state.rope.tautLast = false;
state.input.resetHeldTime = 0;
state.requestReset = false;
state.stats.failures = state.stats.failures + 1;
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
