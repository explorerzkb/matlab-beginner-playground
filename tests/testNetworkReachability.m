function testNetworkReachability()
%TESTNETWORKREACHABILITY Check the page entry, retry, and success floor.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
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
    'The red bridge is too far from the embedded page.');
assert(bodyCanCross(network.noticePanel, network.usernameField, ...
    cfg.player.width, measuredJumpRise), ...
    'A pear cannot cross from the notice panel through username.');

loginTop = network.loginButton(2) + network.loginButton(4);
state = createInitialState(world, cfg, []);
state.levelState.network.credentialsReady = true;
state.players(1).pos = [network.loginButton(1) + 0.30, loginTop];
state.players(2).pos = [network.loginButton(1) + ...
    network.loginButton(3) - 0.30, loginTop];
state = stepWorldNetwork(state, world, cfg, 0);
assert(strcmp(state.levelState.network.pageMode, 'timeout'), ...
    'The physically reachable first login did not enter timeout.');

state.levelState.network.pageMode = 'retry';
state.levelState.network.loginPressLatched = false;
state = stepWorldNetwork(state, world, cfg, 0);
assert(strcmp(state.levelState.network.pageMode, 'loading'), ...
    'The physically reachable retry did not begin loading.');
for index = 1:ceil(network.loadingDuration / cfg.physics.fixedDt) + 1
    state = stepWorldNetwork(state, world, cfg, cfg.physics.fixedDt);
end
assert(strcmp(state.levelState.network.pageMode, 'success') && ...
    network.successFloor(1) <= network.pageRect(1) && ...
    network.successFloor(1) + network.successFloor(3) >= ...
    world.regions(4).xRange(1), ...
    'The success playground does not continuously reach the next region.');

% Crossing the playground-road seam is a two-player transition.  The
% leading pear can already be on the road while its partner still needs the
% successful-page floor; an average-position cull must not remove that floor.
state.players(1).pos = [110.5, 1.0];
state.players(2).pos = [113.8, 1.0];
state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
assert(any(all(abs(state.levelState.colliders - network.successFloor) < ...
    1e-9, 2)), ...
    'The playground floor vanished while the trailing pear crossed the road seam.');
input = neutralInput();
for index = 1:90
    state = stepPhysics(state, input, world, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
end
assert(state.players(1).pos(2) >= 0.99 && ~state.status.deathPending, ...
    'The trailing pear fell when its partner entered the road first.');

checkpoint = world.checkpoints(3).spawn;
assert(all(abs(checkpoint(:, 2) - noticeTop) < 1e-9), ...
    'The page retry checkpoint is not on the notice panel.');
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
