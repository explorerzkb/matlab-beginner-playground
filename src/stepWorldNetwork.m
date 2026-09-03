function state = stepWorldNetwork(state, world, ~, dt)
%STEPWORLDNETWORK Advance cooperative controls in the campus-network page.

network = world.mechanic.network;
usernamePlayers = playersInRect(state.players, network.usernameField);
passwordPlayers = playersInRect(state.players, network.passwordField);
state.levelState.network.fieldOccupancy = [sum(usernamePlayers), ...
    sum(passwordPlayers)];

distinctPlayersReady = ...
    (usernamePlayers(1) && passwordPlayers(2)) || ...
    (usernamePlayers(2) && passwordPlayers(1));
if ~state.levelState.network.credentialsReady
    if distinctPlayersReady
        state.levelState.network.credentialsTimer = min( ...
            network.credentialsHoldDuration, ...
            state.levelState.network.credentialsTimer + dt);
    else
        state.levelState.network.credentialsTimer = max(0, ...
            state.levelState.network.credentialsTimer - 1.5 * dt);
    end
    if state.levelState.network.credentialsTimer >= ...
            network.credentialsHoldDuration
        state.levelState.network.credentialsReady = true;
    end
end

state.levelState.dynamicObjects.network.usernameField = ...
    network.usernameField;
state.levelState.dynamicObjects.network.passwordField = ...
    network.passwordField;
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
