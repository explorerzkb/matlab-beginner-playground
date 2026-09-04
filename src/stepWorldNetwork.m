function state = stepWorldNetwork(state, world, cfg, dt)
%STEPWORLDNETWORK Advance the physical campus-network login page.

network = world.mechanic.network;

if ~state.levelState.network.rememberChecked && ...
        any(playersOverlapping(state.players, network.rememberCheckbox))
    state.levelState.network.rememberChecked = true;
end

usernamePlayers = playersOverlapping(state.players, network.usernameField);
passwordPlayers = playersOverlapping(state.players, network.passwordField);
state.levelState.network.fieldOccupancy = [sum(usernamePlayers), ...
    sum(passwordPlayers)];
if ~state.levelState.network.credentialsReady && any(usernamePlayers)
    state.levelState.network.credentialsReady = true;
end

state = stepLagEasterEgg(state, network, cfg, dt);
loginPlayers = playersStandingOn(state.players, network.loginButton);
bothOnLogin = all(loginPlayers);
anyOnLogin = any(loginPlayers);
if bothOnLogin && ~state.levelState.network.loginPressLatched
    state.stats.networkAttempts = state.stats.networkAttempts + 1;
    state.levelState.network.loginPressLatched = true;
end
if ~bothOnLogin
    state.levelState.network.loginPressLatched = false;
end

lagBlocksLogin = strcmp(state.levelState.network.lagPhase, 'warning') || ...
    strcmp(state.levelState.network.lagPhase, 'outage');
if state.levelState.network.authenticated
    state.levelState.network.feedback = 'success';
elseif strcmp(state.levelState.network.lagPhase, 'warning')
    state.levelState.network.feedback = 'lagWarning';
elseif strcmp(state.levelState.network.lagPhase, 'outage')
    state.levelState.network.feedback = 'lagOutage';
elseif ~state.levelState.network.credentialsReady
    if anyOnLogin
        state.levelState.network.feedback = 'needCredentials';
    else
        state.levelState.network.feedback = 'idle';
    end
elseif bothOnLogin && ~lagBlocksLogin
    state.levelState.network.authenticated = true;
    state.levelState.network.feedback = 'success';
elseif anyOnLogin
    state.levelState.network.feedback = 'needPartner';
else
    state.levelState.network.feedback = 'ready';
end

state.levelState.colliders = removeRect( ...
    state.levelState.colliders, network.authGate);
if ~state.levelState.network.authenticated
    state.levelState.colliders = [state.levelState.colliders; network.authGate];
end

% The notice panel is the landing object reached from the North Lake red
% bridge. Only the two first-row buttons are physical platforms. Username,
% password, remember-password, and recharge controls remain trigger/visual
% regions so they cannot catch a pear during the outage gag.
state.levelState.colliders = removeRect( ...
    state.levelState.colliders, network.noticePanel);
state.levelState.colliders = removeRect( ...
    state.levelState.colliders, network.loginButton);
state.levelState.colliders = removeRect( ...
    state.levelState.colliders, network.selfServiceButton);
state.levelState.colliders = [state.levelState.colliders; network.noticePanel];
if ~strcmp(state.levelState.network.lagPhase, 'outage')
    state.levelState.colliders = [state.levelState.colliders; ...
        network.loginButton; network.selfServiceButton];
end

state.levelState.dynamicObjects.network.noticePanel = network.noticePanel;
state.levelState.dynamicObjects.network.usernameField = ...
    network.usernameField;
state.levelState.dynamicObjects.network.passwordField = ...
    network.passwordField;
state.levelState.dynamicObjects.network.rememberCheckbox = ...
    network.rememberCheckbox;
state.levelState.dynamicObjects.network.loginButton = network.loginButton;
state.levelState.dynamicObjects.network.authGate = network.authGate;
state.levelState.dynamicObjects.network.selfServiceButton = ...
    network.selfServiceButton;
state.levelState.dynamicObjects.network.rechargePads = network.rechargePads;
end

function state = stepLagEasterEgg(state, network, cfg, dt)
phase = state.levelState.network.lagPhase;
switch phase
    case 'waiting'
        fixedStep = dt > 0 && dt <= cfg.physics.fixedDt * 1.01;
        if state.levelState.network.credentialsReady && ...
                ~state.levelState.network.authenticated && ...
                state.levelState.network.lagEligible && fixedStep
            state.levelState.network.lagClock = ...
                state.levelState.network.lagClock + dt;
            if state.levelState.network.lagClock >= ...
                    state.levelState.network.lagDelay
                state.levelState.network.lagPhase = 'warning';
                state.levelState.network.lagPhaseTimer = ...
                    network.lagWarningDuration;
            end
        end
    case 'warning'
        state.levelState.network.lagPhaseTimer = max(0, ...
            state.levelState.network.lagPhaseTimer - dt);
        if state.levelState.network.lagPhaseTimer == 0
            state.levelState.network.lagPhase = 'outage';
            state.levelState.network.lagPhaseTimer = ...
                network.lagOutageDuration;
        end
    case 'outage'
        state.levelState.network.lagPhaseTimer = max(0, ...
            state.levelState.network.lagPhaseTimer - dt);
        if state.levelState.network.lagPhaseTimer == 0
            state.levelState.network.lagPhase = 'spent';
        end
end
end

function rects = removeRect(rects, target)
if isempty(rects)
    return;
end
matching = all(abs(rects - target) < 1e-9, 2);
rects(matching, :) = [];
end

function occupancy = playersOverlapping(players, rect)
occupancy = false(1, 2);
for playerIndex = 1:2
    occupancy(playerIndex) = playerOverlaps(players(playerIndex), rect);
end
end

function occupancy = playersStandingOn(players, rect)
occupancy = false(1, 2);
platformTop = rect(2) + rect(4);
for playerIndex = 1:2
    player = players(playerIndex);
    halfWidth = player.size(1) / 2;
    horizontallySupported = player.pos(1) + halfWidth > rect(1) && ...
        player.pos(1) - halfWidth < rect(1) + rect(3);
    occupancy(playerIndex) = horizontallySupported && ...
        abs(player.pos(2) - platformTop) <= 0.10;
end
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
