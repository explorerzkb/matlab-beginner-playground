function state = stepWorldTraffic(state, world, ~, dt)
%STEPWORLDTRAFFIC Advance the fountain and later road/bridge mechanics.

traffic = world.mechanic.traffic;
if ~isfield(state.levelState, 'traffic')
    state.levelState.traffic.fountainCooldowns = zeros(1, 2);
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
state.levelState.dynamicObjects.traffic.fountain = traffic.fountainRect;
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
