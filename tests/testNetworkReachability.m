function testNetworkReachability()
%TESTNETWORKREACHABILITY Check every jump in the red-bridge login route.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
cfg.runtime.testMode = true;
world = continuousCampusWorld();
network = world.mechanic.network;

measuredJumpRise = measureJumpRise(cfg, world);
bridge = world.mechanic.animals.shortcutPlatforms;
bridgeTop = bridge(2) + bridge(4);
noticeTop = network.noticePanel(2) + network.noticePanel(4);
assert(noticeTop - bridgeTop < measuredJumpRise - 0.2, ...
    'The notice panel is above the measured standard-jump envelope.');
assert(horizontalGap(bridge, network.noticePanel) < ...
    sameHeightJumpRange(cfg) * 0.45, ...
    'The red bridge is too far from the notice panel.');

assert(bodyCanCross(network.noticePanel, network.usernameField, ...
    cfg.player.width, measuredJumpRise), ...
    'A pear cannot cross from the notice panel through username.');
loginTop = network.loginButton(2) + network.loginButton(4);
assert(network.usernameField(2) > loginTop && ...
    rangesOverlap(network.usernameField, network.loginButton), ...
    'The username trigger no longer drops toward the login platform.');
assert(horizontalGap(network.loginButton, network.selfServiceButton) < ...
    cfg.player.width, ...
    'Login and self-service are separated by an avoidable dead gap.');
assert(horizontalGap(network.selfServiceButton, network.exitPlatform) < ...
    sameHeightJumpRange(cfg) * 0.45, ...
    'Self-service cannot reach the retained traffic-entry platform.');

[~, bridgeLanding] = runRightJump(cfg, world, [ ...
    61.8, bridgeTop; 63.0, bridgeTop], 120, network.noticePanel);
assert(bridgeLanding, ...
    'Two rope-linked pears did not physically land from red bridge to notice.');
[loginState, loginLanding] = runRightJump(cfg, world, [ ...
    72.8, noticeTop; 74.0, noticeTop], 9, network.loginButton);
assert(loginLanding && loginState.levelState.network.credentialsReady && ...
    loginState.levelState.network.authenticated && ...
    loginState.levelState.network.rememberChecked && ...
    loginState.checkpointIndex >= 3, ...
    'Notice-to-username-to-login traversal did not autofill and authenticate.');

loginTop = network.loginButton(2) + network.loginButton(4);
[selfState, selfLanding] = runRightJump(cfg, world, [ ...
    76.35, loginTop; 77.55, loginTop], 3, ...
    [network.loginButton; network.selfServiceButton], true);
assert(selfLanding && anyPlayerSupported( ...
    selfState.players, network.selfServiceButton), ...
    'The login platform cannot hand one pear onto self-service.');
selfTop = network.selfServiceButton(2) + network.selfServiceButton(4);
[exitState, exitLanding] = runRightJump(cfg, world, [ ...
    78.80, selfTop; 80.00, selfTop], 6, ...
    [network.selfServiceButton; network.exitPlatform], true);
assert(exitLanding && anyPlayerSupported( ...
    exitState.players, network.exitPlatform), ...
    'The self-service platform cannot hand a pear onto the traffic entry.');

checkpoint = world.checkpoints(3).spawn;
assert(all(abs(checkpoint(:, 2) - noticeTop) < 1e-9) && ...
    all(checkpoint(:, 1) > network.noticePanel(1)) && ...
    all(checkpoint(:, 1) < network.noticePanel(1) + ...
        network.noticePanel(3)), ...
    'The outage retry checkpoint is not safely on the notice panel.');
end

function [state, landed] = runRightJump(cfg, world, positions, ...
        releaseStep, targetRects, authenticated)
if nargin < 6
    authenticated = false;
end
state = createInitialState(world, cfg, []);
state.levelState.network.credentialsReady = authenticated;
state.levelState.network.authenticated = authenticated;
for playerIndex = 1:2
    state.players(playerIndex).pos = positions(playerIndex, :);
    state.players(playerIndex).onGround = true;
end
state = stepLevel(state, world, cfg, 0);
input = neutralInput();
input.player(1).right = true;
input.player(2).right = true;
input.player(1).jump = true;
input.player(2).jump = true;
landed = false;
for stepIndex = 1:150
    if stepIndex > releaseStep
        input.player(1).right = false;
        input.player(2).right = false;
    end
    state = stepPhysics(state, input, world, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
    input.player(1).jump = false;
    input.player(2).jump = false;
    if allPlayersSupported(state.players, targetRects)
        landed = true;
        return;
    end
end
end

function tf = allPlayersSupported(players, rects)
tf = true;
for playerIndex = 1:2
    playerSupported = false;
    for rectIndex = 1:size(rects, 1)
        playerSupported = playerSupported || ...
            playerSupportedBy(players(playerIndex), rects(rectIndex, :));
    end
    tf = tf && playerSupported;
end
end

function tf = anyPlayerSupported(players, rect)
tf = false;
for playerIndex = 1:2
    tf = tf || playerSupportedBy(players(playerIndex), rect);
end
end

function tf = playerSupportedBy(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
    player.pos(1) - halfWidth < rect(1) + rect(3) && ...
    abs(player.pos(2) - (rect(2) + rect(4))) < 0.05 && ...
    player.onGround;
end

function rise = measureJumpRise(cfg, world)
state = createInitialState(world, cfg, []);
bridge = world.mechanic.animals.shortcutPlatforms;
startY = bridge(2) + bridge(4);
state.players(1).pos = [bridge(1) + 2.0, startY];
state.players(2).pos = [bridge(1) + 3.2, startY];
state.players(1).onGround = true;
state.players(2).onGround = true;
state = stepLevel(state, world, cfg, 0);
input = neutralInput();
input.player(1).jump = true;
input.player(2).jump = true;
maxY = startY;
for index = 1:round(1.5 / cfg.physics.fixedDt)
    state = stepPhysics(state, input, world, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
    positions = vertcat(state.players.pos);
    maxY = max(maxY, min(positions(:, 2)));
    input.player(1).jump = false;
    input.player(2).jump = false;
end
rise = maxY - startY;
end

function range = sameHeightJumpRange(cfg)
range = cfg.physics.maxRunSpeed * ...
    (2 * cfg.physics.jumpSpeed / abs(cfg.physics.gravity));
end

function gap = horizontalGap(leftRect, rightRect)
gap = max(0, rightRect(1) - (leftRect(1) + leftRect(3)));
end

function tf = rangesOverlap(first, second)
tf = first(1) + first(3) > second(1) && ...
    first(1) < second(1) + second(3);
end

function tf = bodyCanCross(startRect, triggerRect, playerWidth, jumpRise)
gap = horizontalGap(startRect, triggerRect);
verticalDrop = startRect(2) + startRect(4) - ...
    (triggerRect(2) + triggerRect(4));
tf = gap < playerWidth + 2.0 && verticalDrop < jumpRise;
end

function input = neutralInput()
for playerIndex = 1:2
    input.player(playerIndex).left = false;
    input.player(playerIndex).right = false;
    input.player(playerIndex).jump = false;
end
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end
