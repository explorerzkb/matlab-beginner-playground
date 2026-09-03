function state = stepWorldTraffic(state, world, cfg, dt)
%STEPWORLDTRAFFIC Advance the fountain and later road/bridge mechanics.

traffic = world.mechanic.traffic;
if ~isfield(state.levelState, 'traffic')
    state.levelState.traffic = struct();
end
if ~isfield(state.levelState.traffic, 'fountainCooldowns')
    state.levelState.traffic.fountainCooldowns = zeros(1, 2);
end
if ~isfield(state.levelState.traffic, 'fountainClock')
    state.levelState.traffic.fountainClock = state.levelTime;
else
    state.levelState.traffic.fountainClock = ...
        state.levelState.traffic.fountainClock + dt;
end
if ~isfield(state.levelState.traffic, 'route')
    state.levelState.traffic.route = 'undecided';
    state.levelState.traffic.routeCandidate = 'none';
    state.levelState.traffic.routeTimer = 0;
end
if ~isfield(state.levelState.traffic, 'cars')
    state.levelState.traffic.cars = traffic.carData(:, 1:4);
end
state.levelState.traffic.fountainCooldowns = max(0, ...
    state.levelState.traffic.fountainCooldowns - dt);
phase = mod(state.levelState.traffic.fountainClock, ...
    traffic.fountainPeriod);
jetActive = phase < traffic.fountainActiveDuration;

if jetActive
    for playerIndex = 1:2
        if state.levelState.traffic.fountainCooldowns(playerIndex) == 0 && ...
                playerOverlaps(state.players(playerIndex), ...
                traffic.fountainRect)
            state.players(playerIndex).vel(1) = max( ...
                state.players(playerIndex).vel(1), ...
                traffic.fountainImpulse(1));
            state.players(playerIndex).vel(2) = max( ...
                state.players(playerIndex).vel(2), ...
                traffic.fountainImpulse(2));
            state.levelState.traffic.fountainCooldowns(playerIndex) = ...
                traffic.fountainCooldown;
            state.stats.fountainLaunches = state.stats.fountainLaunches + 1;
        end
    end
end

state.levelState.traffic.fountainPhase = phase;
state.levelState.traffic.jetActive = jetActive;

if strcmp(state.levelState.traffic.route, 'undecided')
    upperReady = all(playersInRect(state.players, traffic.upperRouteZone));
    lowerReady = all(playersInRect(state.players, traffic.lowerRouteZone));
    if upperReady
        candidate = 'upper';
    elseif lowerReady
        candidate = 'lower';
    else
        candidate = 'none';
    end
    if strcmp(candidate, state.levelState.traffic.routeCandidate) && ...
            ~strcmp(candidate, 'none')
        state.levelState.traffic.routeTimer = min( ...
            traffic.routeHoldDuration, ...
            state.levelState.traffic.routeTimer + dt);
    elseif ~strcmp(candidate, 'none')
        state.levelState.traffic.routeCandidate = candidate;
        state.levelState.traffic.routeTimer = dt;
    else
        state.levelState.traffic.routeCandidate = 'none';
        state.levelState.traffic.routeTimer = max(0, ...
            state.levelState.traffic.routeTimer - 1.5 * dt);
    end
    if state.levelState.traffic.routeTimer >= traffic.routeHoldDuration
        state.levelState.traffic.route = candidate;
        if strcmp(candidate, 'upper')
            state.stats.trafficRoute = '北理桥';
        else
            state.stats.trafficRoute = '红绿灯';
        end
    end
end

if ~isfield(state.levelState.traffic, 'signalClock')
    state.levelState.traffic.signalClock = state.levelTime;
else
    state.levelState.traffic.signalClock = ...
        state.levelState.traffic.signalClock + dt;
end
[signalPhase, phaseProgress] = signalAtTime(traffic, ...
    state.levelState.traffic.signalClock);
state.levelState.traffic.signalPhase = signalPhase;
state.levelState.traffic.signalProgress = phaseProgress;
state.levelState.traffic.carsMayMove = strcmp(signalPhase, 'vehicleGreen') || ...
    strcmp(signalPhase, 'yellow');
state.levelState.traffic.pedestriansMayCross = ...
    strcmp(signalPhase, 'pedestrianGreen');
if ~state.levelState.traffic.pedestriansMayCross
    state.levelState.colliders = [state.levelState.colliders; ...
        traffic.pedestrianBarrier];
end
if strcmp(state.levelState.traffic.route, 'lower') && ...
        ~state.levelState.traffic.pedestriansMayCross && ...
        any(playersInRect(state.players, traffic.waitingZone))
    state.stats.trafficWaitTime = state.stats.trafficWaitTime + dt;
end

cars = state.levelState.traffic.cars;
if state.levelState.traffic.carsMayMove
    for carIndex = 1:size(cars, 1)
        row = traffic.carData(carIndex, :);
        cars(carIndex, 2) = cars(carIndex, 2) + ...
            row(5) * row(6) * dt;
        if row(6) > 0 && cars(carIndex, 2) > row(8)
            cars(carIndex, 2) = row(7) - cars(carIndex, 4);
        elseif row(6) < 0 && ...
                cars(carIndex, 2) + cars(carIndex, 4) < row(7)
            cars(carIndex, 2) = row(8);
        end
    end
else
    cars = parkCarsOutsideCrosswalk(cars, traffic);
end
state.levelState.traffic.cars = cars;

carHit = false;
if state.levelState.traffic.carsMayMove
    for carIndex = 1:size(cars, 1)
        carInCrosswalk = rectanglesOverlap(cars(carIndex, :), ...
            traffic.crosswalk);
        if carInCrosswalk && ...
                any(playersInRect(state.players, cars(carIndex, :)))
            carHit = true;
            break;
        end
    end
end
if carHit
    state = applyBreakEvent(state, cfg, 'major');
end

crowd = traffic.crowdData(:, 1:4);
if state.levelState.traffic.pedestriansMayCross
    travelDistance = traffic.crosswalk(3) + 1.6;
    for crowdIndex = 1:size(crowd, 1)
        offset = traffic.crowdData(crowdIndex, 5);
        crowd(crowdIndex, 1) = traffic.crosswalk(1) - 0.8 + mod( ...
            (phaseProgress + offset) * travelDistance, travelDistance);
    end
end
pushMultiplier = 1;
if state.inventory.buffTimer > 0
    pushMultiplier = cfg.tea.knockbackMultiplier;
end
for crowdIndex = 1:size(crowd, 1)
    touchingPlayers = playersInRect(state.players, crowd(crowdIndex, :));
    for playerIndex = find(touchingPlayers)
        direction = sign(state.players(playerIndex).pos(1) - ...
            (crowd(crowdIndex, 1) + crowd(crowdIndex, 3) / 2));
        if direction == 0
            direction = 1;
        end
        state.players(playerIndex).vel(1) = min(max( ...
            state.players(playerIndex).vel(1) + direction * ...
            traffic.crowdPushAcceleration * pushMultiplier * dt, ...
            -traffic.crowdPushSpeedCap), traffic.crowdPushSpeedCap);
    end
end
state.levelState.traffic.crowd = crowd;

state.levelState.dynamicObjects.traffic.fountain = traffic.fountainRect;
state.levelState.dynamicObjects.traffic.upperRouteZone = ...
    traffic.upperRouteZone;
state.levelState.dynamicObjects.traffic.lowerRouteZone = ...
    traffic.lowerRouteZone;
state.levelState.dynamicObjects.traffic.crosswalk = traffic.crosswalk;
state.levelState.dynamicObjects.traffic.pedestrianBarrier = ...
    traffic.pedestrianBarrier;
state.levelState.dynamicObjects.traffic.cars = cars;
state.levelState.dynamicObjects.traffic.crowd = crowd;
end

function cars = parkCarsOutsideCrosswalk(cars, traffic)
crosswalk = traffic.crosswalk;
crossingBottom = crosswalk(2);
crossingTop = crosswalk(2) + crosswalk(4);
for carIndex = 1:size(cars, 1)
    direction = traffic.carData(carIndex, 6);
    carBottom = cars(carIndex, 2);
    carTop = carBottom + cars(carIndex, 4);
    overlapsCrossing = carTop > crossingBottom && carBottom < crossingTop;
    if overlapsCrossing && direction > 0
        cars(carIndex, 2) = crossingBottom - ...
            traffic.stopLineGap - cars(carIndex, 4);
    elseif overlapsCrossing
        cars(carIndex, 2) = crossingTop + traffic.stopLineGap;
    end
end
end

function tf = rectanglesOverlap(first, second)
tf = first(1) + first(3) > second(1) && ...
    first(1) < second(1) + second(3) && ...
    first(2) + first(4) > second(2) && ...
    first(2) < second(2) + second(4);
end

function [phase, progress] = signalAtTime(traffic, time)
durations = traffic.signalPhaseDurations;
cycleTime = mod(time, sum(durations));
phaseIndex = find(cycleTime < cumsum(durations), 1, 'first');
if isempty(phaseIndex)
    phaseIndex = numel(durations);
end
phaseStart = sum(durations(1:phaseIndex - 1));
phase = traffic.signalPhaseNames{phaseIndex};
progress = (cycleTime - phaseStart) / durations(phaseIndex);
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
