function state = stepWorldTraffic(state, world, ~, dt)
%STEPWORLDTRAFFIC Advance the fountain and later road/bridge mechanics.

traffic = world.mechanic.traffic;
if ~isfield(state.levelState, 'traffic')
    state.levelState.traffic = struct();
end
if ~isfield(state.levelState.traffic, 'fountainCooldowns')
    state.levelState.traffic.fountainCooldowns = zeros(1, 2);
end
if ~isfield(state.levelState.traffic, 'route')
    state.levelState.traffic.route = 'undecided';
    state.levelState.traffic.routeCandidate = 'none';
    state.levelState.traffic.routeTimer = 0;
end
state.levelState.traffic.fountainCooldowns = max(0, ...
    state.levelState.traffic.fountainCooldowns - dt);
phase = mod(state.levelTime, traffic.fountainPeriod);
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

[signalPhase, phaseProgress] = signalAtTime(traffic, state.levelTime);
state.levelState.traffic.signalPhase = signalPhase;
state.levelState.traffic.signalProgress = phaseProgress;
state.levelState.traffic.carsMayMove = strcmp(signalPhase, 'vehicleGreen') || ...
    strcmp(signalPhase, 'yellow');
state.levelState.traffic.pedestriansMayCross = ...
    strcmp(signalPhase, 'pedestrianGreen');
if strcmp(state.levelState.traffic.route, 'lower') && ...
        ~state.levelState.traffic.pedestriansMayCross && ...
        any(playersInRect(state.players, traffic.waitingZone))
    state.stats.trafficWaitTime = state.stats.trafficWaitTime + dt;
end

state.levelState.dynamicObjects.traffic.fountain = traffic.fountainRect;
state.levelState.dynamicObjects.traffic.upperRouteZone = ...
    traffic.upperRouteZone;
state.levelState.dynamicObjects.traffic.lowerRouteZone = ...
    traffic.lowerRouteZone;
state.levelState.dynamicObjects.traffic.crosswalk = traffic.crosswalk;
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
