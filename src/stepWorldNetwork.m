function state = stepWorldNetwork(state, world, cfg, dt)
%STEPWORLDNETWORK Advance the world-embedded campus-network page.

network = world.mechanic.network;
mode = state.levelState.network.pageMode;
loginPageActive = any(strcmp(mode, {'login', 'retry', 'loading'}));

if loginPageActive && ~state.levelState.network.rememberChecked && ...
        any(playersOverlapping(state.players, network.rememberCheckbox))
    state.levelState.network.rememberChecked = true;
end

if loginPageActive
    usernamePlayers = playersOverlapping(state.players, ...
        network.usernameField);
    passwordPlayers = playersOverlapping(state.players, ...
        network.passwordField);
else
    usernamePlayers = false(1, 2);
    passwordPlayers = false(1, 2);
end
state.levelState.network.fieldOccupancy = [sum(usernamePlayers), ...
    sum(passwordPlayers)];
if ~state.levelState.network.credentialsReady && any(usernamePlayers)
    state.levelState.network.credentialsReady = true;
end

loginPlayers = false(1, 2);
if loginPageActive
    loginPlayers = playersStandingOn(state.players, network.loginButton);
end
anyOnLogin = any(loginPlayers);
bothOnLogin = all(loginPlayers);
if ~anyOnLogin
    state.levelState.network.loginPressLatched = false;
end

switch mode
    case {'login', 'retry'}
        if ~state.levelState.network.credentialsReady
            if anyOnLogin
                state.levelState.network.feedback = 'needCredentials';
            else
                state.levelState.network.feedback = 'idle';
            end
        elseif ~state.levelState.network.failureSeen && anyOnLogin && ...
                ~state.levelState.network.loginPressLatched
            % The first real login contact always replaces the entire page
            % with the supplied Chrome timeout page. No warning or fade.
            state.stats.networkAttempts = state.stats.networkAttempts + 1;
            state.levelState.network.loginPressLatched = true;
            state.levelState.network.failureSeen = true;
            state.levelState.network.pageMode = 'timeout';
            state.levelState.network.feedback = 'timeout';
        elseif state.levelState.network.failureSeen && bothOnLogin && ...
                ~state.levelState.network.loginPressLatched
            state.stats.networkAttempts = state.stats.networkAttempts + 1;
            state.levelState.network.loginPressLatched = true;
            state.levelState.network.pageMode = 'loading';
            state.levelState.network.loadingTimer = network.loadingDuration;
            state.levelState.network.feedback = 'loading';
        elseif state.levelState.network.failureSeen && anyOnLogin
            state.levelState.network.feedback = 'needPartner';
        else
            state.levelState.network.feedback = 'ready';
        end

    case 'timeout'
        % This state deliberately persists until the unsupported player
        % falls below the world and resetToCheckpoint restores the login page.
        state.levelState.network.feedback = 'timeout';

    case 'loading'
        state.levelState.network.loadingTimer = max(0, ...
            state.levelState.network.loadingTimer - dt);
        state.levelState.network.feedback = 'loading';
        if state.levelState.network.loadingTimer == 0
            state.levelState.network.authenticated = true;
            state.levelState.network.pageMode = 'success';
            state.levelState.network.feedback = 'success';
        end

    case 'success'
        state.levelState.network.authenticated = true;
        state.levelState.network.feedback = 'success';

    otherwise
        error('matlabHi:UnknownNetworkPageMode', ...
            '未知校园网页面状态：%s', mode);
end

mode = state.levelState.network.pageMode;
pageRects = [network.noticePanel; network.loginButton; ...
    network.selfServiceButton; network.successFloor];
for index = 1:size(pageRects, 1)
    state.levelState.colliders = removeRect( ...
        state.levelState.colliders, pageRects(index, :));
end
state.levelState.colliders = removeRect( ...
    state.levelState.colliders, network.authGate);

switch mode
    case {'login', 'retry', 'loading'}
        state.levelState.colliders = [state.levelState.colliders; ...
            network.noticePanel; network.loginButton; ...
            network.selfServiceButton; network.authGate];
    case 'timeout'
        % The visual plane stays put, but the web page no longer supports
        % either pear. The closed gate only prevents skipping the retry.
        state.levelState.colliders = [state.levelState.colliders; ...
            network.authGate];
    case 'success'
        % The successful page contains a playground. Its lower edge becomes
        % one continuous road so the players can simply keep walking right.
        state.levelState.colliders = [state.levelState.colliders; ...
            network.successFloor];
end

state.levelState.dynamicObjects.network.pageRect = network.pageRect;
state.levelState.dynamicObjects.network.pageMode = mode;
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
state.levelState.dynamicObjects.network.successFloor = network.successFloor;

% cfg remains part of the stepping interface; validate the only timing
% relationship that could otherwise leave the page stuck forever.
if cfg.physics.fixedDt <= 0 || network.loadingDuration <= 0
    error('matlabHi:InvalidNetworkTiming', ...
        '校园网固定步长和加载时长必须为正数。');
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
