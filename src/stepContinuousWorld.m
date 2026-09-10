function state = stepContinuousWorld(state, world, cfg, dt)
%STEPCONTINUOUSWORLD Advance global region, checkpoint, and finish state.

state.levelState.colliders = world.platforms;
state.levelState.oneWayPlatforms = zeros(0, 4);
centreX = mean([state.players(1).pos(1), state.players(2).pos(1)]);
minimumX = min([state.players(1).pos(1), state.players(2).pos(1)]);
regionIndex = findRegionIndex(centreX, world.regions);
state.world.previousRegionIndex = state.world.activeRegionIndex;
state.world.activeRegionIndex = regionIndex;
state.levelState.activeRegionId = world.regions(regionIndex).id;
state = collectTeaPickups(state, world);
campusOnly = isfield(state.levelState, 'bicycle') && ...
    state.levelState.bicycle.landed && ...
    min([state.players(1).pos(1), state.players(2).pos(1)]) >= 170;
if campusOnly
    % Earlier regions can no longer affect the players after the compulsory
    % flight has landed.  Updating every retired mechanic at 60 Hz copied a
    % large nested state tree and consumed more time than the bus gameplay.
    state.levelState.oneWayPlatforms = zeros(0, 4);
    state = stepWorldBus(state, world, cfg, dt);
else
    % Each mechanic owns a disjoint horizontal pocket.  They are initialized
    % together on the zero-time setup step, then only nearby mechanics advance
    % at 60 Hz.  Off-screen traffic is derived from levelTime when needed, so
    % this does not change collision or route state at the player position.
    requiredStates = {'animals', 'race', 'traffic', 'bicycle', 'bus'};
    initializeAll = dt == 0 && ...
        any(~isfield(state.levelState, requiredStates));
    if initializeAll || centreX < 66
        state = stepWorldAnimals(state, world, cfg, dt);
    end
    playgroundRoadSeam = world.mechanic.network.successFloor(1) + ...
        world.mechanic.network.successFloor(3);
    networkNearby = centreX >= 58 && minimumX < playgroundRoadSeam;
    if initializeAll || networkNearby
        state = stepWorldNetwork(state, world, cfg, dt);
    end
    raceRunning = isfield(state.levelState, 'race') && ...
        strcmp(state.levelState.race.phase, 'running');
    if initializeAll || (centreX >= 58 && centreX < 112) || raceRunning
        state = stepWorldRace(state, world, dt);
    end
    if initializeAll || (centreX >= 106 && centreX < 150)
        state = stepWorldTraffic(state, world, cfg, dt);
    end
    bicycleActive = isfield(state.levelState, 'bicycle') && ...
        (strcmp(state.levelState.bicycle.phase, 'warning') || ...
        strcmp(state.levelState.bicycle.phase, 'flight'));
    if initializeAll || (centreX >= 142 && centreX < 176) || bicycleActive
        state = stepWorldBicycle(state, world, cfg, dt);
    end
    if initializeAll || centreX >= 176
        state = stepWorldBus(state, world, cfg, dt);
    end
end

for index = state.checkpointIndex + 1:numel(world.checkpoints)
    if checkpointSatisfied(state, world, index, minimumX)
        state.checkpointIndex = index;
    else
        break;
    end
end

if state.players(1).pos(2) < world.killY || ...
        state.players(2).pos(2) < world.killY
    if strcmp(state.levelState.network.pageMode, 'timeout')
        % Falling from the scripted timeout page is the joke itself, not a
        % damage event. The reset keeps failureSeen and restores the page.
        if ~isfield(state.levelState.network,'timeoutResetTimer')
            state.levelState.network.timeoutResetTimer=cfg.network.timeoutExtraHold;
        else
            state.levelState.network.timeoutResetTimer=max(0, ...
                state.levelState.network.timeoutResetTimer-dt);
        end
        state.requestReset=state.levelState.network.timeoutResetTimer==0;
    else
        state = applyDamageEvent(state, cfg, 'fatal');
    end
end

state.completed = isfield(state.levelState, 'bus') && ...
    state.levelState.bus.completed;

state.trajectorySampleClock = state.trajectorySampleClock + dt;
if state.trajectorySampleClock >= 0.1
    state.trajectorySampleClock = state.trajectorySampleClock - 0.1;
    sample = [state.levelTime, state.players(1).pos, state.players(2).pos];
    state.levelTrajectory(end + 1, :) = sample;
    state.stats.trajectory(end + 1, :) = [world.id, state.stats.elapsed, ...
        state.players(1).pos, state.players(2).pos];
end

if any(~isfinite([state.players(1).pos, state.players(1).vel, ...
        state.players(2).pos, state.players(2).vel]))
    error('matlabHi:NonFinitePhysics', ...
        '物理状态出现 NaN 或 Inf，游戏已安全停止。');
end

state = stepCameraTracking(state, world, cfg, dt);

if cfg.health.maxHearts <= 0
    error('matlabHi:InvalidHealthConfig', '共享爱心上限必须为正数。');
end
end

function tf = checkpointSatisfied(state, world, index, minimumX)
checkpoint = world.checkpoints(index);
tf = minimumX >= checkpoint.x && ~state.status.deathPending && ...
    all([state.players(1).pos(2), state.players(2).pos(2)] >= 0.9);
if index == 3
    % Reaching the notice panel is progress; passing beneath it is not.
    top = world.mechanic.network.noticePanel(2) + ...
        world.mechanic.network.noticePanel(4);
    tf = tf && (state.levelState.network.authenticated || ...
        all([state.players(1).pos(2), state.players(2).pos(2)] >= top - 0.1));
elseif index >= 4
    tf = tf && state.levelState.network.authenticated;
end
if index >= 6
    tf = tf && state.levelState.bicycle.landed;
end
end

function index = findRegionIndex(x, regions)
index = numel(regions);
for candidate = 1:numel(regions)
    range = regions(candidate).xRange;
    if x >= range(1) && x < range(2)
        index = candidate;
        return;
    end
end
end
