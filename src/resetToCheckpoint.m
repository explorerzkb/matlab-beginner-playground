function state = resetToCheckpoint(state, level, cfg)
%RESETTOCHECKPOINT Reset both players together and preserve earned progress.
if nargin<3
    root=fileparts(fileparts(mfilename('fullpath')));
    cfg=gameConfig(root);
end

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
    state.players(playerIndex).hitWall = false;
    state.players(playerIndex).hitCeiling = false;
    state.players(playerIndex).preCollisionVelocityX = 0;
    state.players(playerIndex).environmentBoostTime = 0;
    state.players(playerIndex).visualImpactTimer = 0;
    state.players(playerIndex).visualImpactKind = 'none';
end
if strcmp(level.mechanic.type, 'continuousCampus')
    state = resetContinuousTransients(state, level);
end
state.rope.currentTension = 0;
state.rope.tautLast = false;
state.status.currentHearts = state.status.maxHearts;
state.status.deathPending = false;
state.status.deathTimer = 0;
state.input.resetHeldTime = 0;
state.input.bufferedJumps = [false false];
state.input.bufferedLeft = [false false];
state.input.bufferedRight = [false false];
state.input.bufferedUseItem = false;
state.requestReset = false;
state.stats.failures = state.stats.failures + 1;
if strcmp(level.mechanic.type,'continuousCampus')
    % Rendering may happen before another physics tick. Restore every dynamic
    % state and its matching colliders now, without advancing the clock.
    state=stepContinuousWorld(state,level,cfg,0);
end
end

function state = resetContinuousTransients(state, world)
if isfield(state.levelState,'race') && ...
        min([state.players(1).pos(1),state.players(2).pos(1)]) < world.mechanic.race.startX
    state.levelState=rmfield(state.levelState,'race');
end
traffic = world.mechanic.traffic;
cars = traffic.carData(:, 1:4);
for carIndex = 1:size(cars, 1)
    if traffic.carData(carIndex, 6) > 0
        cars(carIndex, 1) = traffic.crosswalk(1) - ...
            traffic.stopLineGap - cars(carIndex, 3);
    else
        cars(carIndex, 1) = traffic.crosswalk(1) + ...
            traffic.crosswalk(3) + ...
            traffic.stopLineGap;
    end
end
state.levelState.traffic.cars = cars;
state.levelState.traffic.carDirections = traffic.carData(:,6);
state.levelState.traffic.signalClock = ...
    sum(traffic.signalPhaseDurations(1:2));
state.levelState.traffic.signalPhase = 'allRedBeforePed';
state.levelState.traffic.signalProgress = 0;
state.levelState.traffic.carsMayMove = false;
state.levelState.traffic.pedestriansMayCross = false;
state.levelState.traffic.crowd = traffic.crowdData(:, 1:4);
state.levelState.dynamicObjects.traffic.cars = cars;
state.levelState.dynamicObjects.traffic.carDirections = traffic.carData(:,6);
state.levelState.dynamicObjects.traffic.crowd = ...
    traffic.crowdData(:, 1:4);

state.levelState.animals.kickWarning = 0;
state.levelState.animals.kickTarget = 0;
state.levelState.network.loginPressLatched = false;
if strcmp(state.levelState.network.pageMode, 'timeout') || ...
        strcmp(state.levelState.network.pageMode, 'loading')
    state.levelState.network.pageMode = 'retry';
    state.levelState.network.loadingTimer = 0;
    state.levelState.network.feedback = 'ready';
end
if isfield(state.levelState, 'bicycle') && ...
        ~state.levelState.bicycle.landed
    state.levelState.bicycle.phase = 'waiting';
    state.levelState.bicycle.timer = 0;
    state.levelState.bicycle.bikeRects = ...
        world.mechanic.bicycle.bikeRects;
    state.levelState.bicycle.launched = false;
    state.levelState.dynamicObjects.bicycle.phase = 'waiting';
    state.levelState.dynamicObjects.bicycle.timer = 0;
    state.levelState.dynamicObjects.bicycle.bikeRects = ...
        world.mechanic.bicycle.bikeRects;
end
if isfield(state.levelState, 'bus')
    state.levelState = rmfield(state.levelState, 'bus');
end
if state.checkpointIndex==7
    state.levelState.busTimeOffset=state.levelTime;
end
if isfield(state.levelState.dynamicObjects, 'bus')
    state.levelState.dynamicObjects = rmfield( ...
        state.levelState.dynamicObjects, 'bus');
end
state.status.hitCooldown = 0;
state.inventory.useHeldTime = 0;
state.inventory.useLatched = false;
state.completed = false;
% Rebuild before the next physics tick: a timeout reset must not use the
% old page's missing supports, and a bus must not remain at its old location.
state.levelState.colliders = world.platforms;
state.levelState.colliders = [state.levelState.colliders; traffic.upperBridgePlatforms];
state.levelState.oneWayPlatforms = world.mechanic.animals.shortcutPlatforms;
if isfield(state.levelState, 'animals') && ...
        isfield(state.levelState.animals, 'entityColliderRects')
    state.levelState.colliders = [state.levelState.colliders; ...
        state.levelState.animals.entityColliderRects];
end
network = world.mechanic.network;
if state.levelState.network.authenticated
    state.levelState.colliders = [state.levelState.colliders; network.successFloor];
else
    state.levelState.colliders = [state.levelState.colliders; ...
        network.noticePanel; network.loginButton; ...
        network.selfServiceButton; network.authGate];
end
state.levelState.colliders = [state.levelState.colliders; ...
    world.mechanic.bus.lampColliders];
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
