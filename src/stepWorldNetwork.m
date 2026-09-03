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

bothOnLogin = all(playersInRect(state.players, network.loginButton));
if bothOnLogin && ~state.levelState.network.loginPressLatched
    state.stats.networkAttempts = state.stats.networkAttempts + 1;
    state.levelState.network.loginPressLatched = true;
end
if ~bothOnLogin
    state.levelState.network.loginPressLatched = false;
end

if state.levelState.network.authenticated
    state.levelState.network.feedback = 'success';
elseif ~state.levelState.network.credentialsReady
    state.levelState.network.loginTimer = 0;
    if bothOnLogin
        state.levelState.network.feedback = 'needCredentials';
    else
        state.levelState.network.feedback = 'idle';
    end
elseif bothOnLogin
    state.levelState.network.feedback = 'holding';
    state.levelState.network.loginTimer = min(network.loginHoldDuration, ...
        state.levelState.network.loginTimer + dt);
    if state.levelState.network.loginTimer >= network.loginHoldDuration
        state.levelState.network.authenticated = true;
        state.levelState.network.feedback = 'success';
    end
else
    state.levelState.network.loginTimer = max(0, ...
        state.levelState.network.loginTimer - 1.5 * dt);
    state.levelState.network.feedback = 'ready';
end

state.levelState.colliders = removeRect( ...
    state.levelState.colliders, network.authGate);
if ~state.levelState.network.authenticated
    state.levelState.colliders = [state.levelState.colliders; network.authGate];
end

state.levelState.dynamicObjects.network.usernameField = ...
    network.usernameField;
state.levelState.dynamicObjects.network.passwordField = ...
    network.passwordField;
state.levelState.dynamicObjects.network.loginButton = network.loginButton;
state.levelState.dynamicObjects.network.authGate = network.authGate;
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
