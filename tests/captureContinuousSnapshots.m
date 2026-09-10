function captureContinuousSnapshots(outputFolder, lowPowerMode)
%CAPTURECONTINUOUSSNAPSHOTS Render deterministic v3 visual-QA frames.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputFolder = fullfile(projectRoot, 'docs', 'visuals', ...
        'runtime-snapshots-world-v4');
end
if nargin < 2
    lowPowerMode = true;
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
addpath(projectRoot);
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));

cfg = gameConfig(projectRoot);
cfg.runtime.testMode = true;
cfg.runtime.lowPowerMode = logical(lowPowerMode);
if ~cfg.runtime.lowPowerMode
    cfg.render.windowSize = [1280, 720];
    cfg.render.backgroundTextureStride = 2;
end
world = continuousCampusWorld();
sceneNames = {'origin', 'north-lake-animals', 'north-lake-shortcut', ...
    'network-login', 'network-timeout', 'network-loading', ...
    'network-success', 'north-li-bridge-climb', ...
    'north-li-bridge-signal', 'bicycle-warning', 'bicycle-flight', ...
    'museum-landing', 'museum-sports-map', 'campus-bus-lamps', ...
    'sports-center-finish'};
fig = figure('Visible', 'off', 'Position', [50, 50, cfg.render.windowSize], ...
    'Color', [0.08, 0.12, 0.15], ...
    'GraphicsSmoothing', cfg.render.graphicsSmoothing);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);

for index = 1:numel(sceneNames)
    state = createInitialState(world, cfg, []);
    state = stepLevel(state, world, cfg, 0);
    [state, cameraX, cameraY] = configureScene( ...
        state, world, cfg, sceneNames{index});
    state = stepLevel(state, world, cfg, 0);
    state.render.cameraCentre = cameraX;
    state.render.cameraCentreY = cameraY;
    state = renderFrame(fig, ax, state, world, cfg); %#ok<NASGU>
    drawnow;
    exportgraphics(fig, fullfile(outputFolder, ...
        [sceneNames{index}, '.png']), 'Resolution', 120);
end
fprintf('WROTE %d CONTINUOUS-WORLD SNAPSHOTS TO %s\n', ...
    numel(sceneNames), outputFolder);
clear cleanupGuard;
end

function [state, cameraX, cameraY] = configureScene( ...
        state, world, cfg, sceneName)
cameraY = -0.4 + cfg.render.viewportHeight / 2;
switch sceneName
    case 'origin'
        state.players(1).pos = [4.1, 1.0];
        state.players(2).pos = [7.8, 1.0];
        cameraX = cfg.render.viewportWidth / 2;
    case 'north-lake-animals'
        state.players(1).pos = [25.7, 1.0];
        state.players(2).pos = [27.4, 1.0];
        state.levelTime = 1.2;
        cameraX = 25.5;
    case 'north-lake-shortcut'
        bridge = world.mechanic.animals.shortcutPlatforms;
        state.players(1).pos = [bridge(1) + 2.0, bridge(2) + bridge(4)];
        state.players(2).pos = [42.0, 3.1];
        state.levelState.animals.shortcutReached = true;
        state.levelState.animals.kickWarning = 0.35;
        state.levelTime = 1.2;
        cameraX = 46.0;
    case 'network-login'
        notice = world.mechanic.network.noticePanel;
        username = world.mechanic.network.usernameField;
        state.players(1).pos = [notice(1) + notice(3) - 1.2, ...
            notice(2) + notice(4)];
        state.players(2).pos = [username(1) + username(3) / 2, ...
            username(2)];
        state.levelState.network.credentialsReady = true;
        page = world.mechanic.network.pageRect;
        cameraX = page(1) + page(3) / 2;
    case 'network-timeout'
        login = world.mechanic.network.loginButton;
        state.players(1).pos = [login(1) + 0.35 * login(3), ...
            login(2) + login(4) - 0.65];
        state.players(2).pos = [login(1) + 0.75 * login(3), ...
            login(2) + login(4) - 0.50];
        state.players(1).vel(2) = -5.0;
        state.players(2).vel(2) = -4.4;
        state.levelState.network.credentialsReady = true;
        state.levelState.network.failureSeen = true;
        state.levelState.network.pageMode = 'timeout';
        page = world.mechanic.network.pageRect;
        cameraX = page(1) + page(3) / 2;
    case 'network-loading'
        login = world.mechanic.network.loginButton;
        loginTop = login(2) + login(4);
        state.players(1).pos = [login(1) + 0.30, loginTop];
        state.players(2).pos = [login(1) + login(3) - 0.30, loginTop];
        state.levelState.network.credentialsReady = true;
        state.levelState.network.failureSeen = true;
        state.levelState.network.pageMode = 'loading';
        state.levelState.network.loadingTimer = 0.45;
        page = world.mechanic.network.pageRect;
        cameraX = page(1) + page(3) / 2;
    case 'network-success'
        page = world.mechanic.network.pageRect;
        state.players(1).pos = [page(1) + page(3) + 3.0, 1.0];
        state.players(2).pos = [page(1) + page(3) + 5.0, 1.0];
        state.levelState.network.credentialsReady = true;
        state.levelState.network.failureSeen = true;
        state.levelState.network.authenticated = true;
        state.levelState.network.pageMode = 'success';
        cameraX = page(1) + page(3) - 1.5;
    case 'north-li-bridge-climb'
        firstBridge = world.mechanic.traffic.upperBridgePlatforms(1, :);
        state.players(1).pos = [firstBridge(1) + 2.0, ...
            firstBridge(2) + firstBridge(4)];
        state.players(2).pos = [firstBridge(1) + 4.0, ...
            firstBridge(2) + firstBridge(4)];
        state.levelState.traffic.route = 'upper';
        state.levelState.traffic.climbPresses = [4, 4];
        state.stats.trafficRoute = '北理桥';
        cameraX = 126.5;
    case 'north-li-bridge-signal'
        wait = world.mechanic.traffic.waitingZone;
        state.players(1).pos = [wait(1) + 0.7, 1.0];
        state.players(2).pos = [wait(1) + 2.0, 1.0];
        state.levelTime = 4.5;
        state.levelState.traffic.signalClock = 4.5;
        state.levelState.traffic.route = 'lower';
        state.stats.trafficRoute = '红绿灯';
        cameraX = 131.5;
    case 'bicycle-warning'
        zone = world.mechanic.bicycle.triggerZone;
        state.players(1).pos = [zone(1) + 2.0, 1.0];
        state.players(2).pos = [zone(1) + 4.0, 1.0];
        state = stepWorldBicycle(state, world, cfg, 0);
        state.levelState.bicycle.timer = 0.55;
        cameraX = 158.0;
    case 'bicycle-flight'
        state.players(1).pos = [164.5, 9.8];
        state.players(2).pos = [167.0, 11.0];
        state.players(1).vel = world.mechanic.bicycle.launchImpulse;
        state.players(2).vel = world.mechanic.bicycle.launchImpulse;
        state.levelState.bicycle.phase = 'flight';
        state.levelState.bicycle.launched = true;
        cameraX = 165.8;
        cameraY = 11.0;
    case 'museum-landing'
        state.players(1).pos = [176.0, 1.0];
        state.players(2).pos = [179.0, 1.0];
        state.levelState.bicycle.phase = 'landed';
        state.levelState.bicycle.landed = true;
        cameraX = 179.0;
    case 'museum-sports-map'
        state.levelState.network.authenticated = true;
        state.levelState.network.pageMode = 'success';
        state.levelState.network.failureSeen = true;
        state.levelState.bicycle.phase = 'landed';
        state.levelState.bicycle.landed = true;
        state.players(1).pos = [192.4, 1.0];
        state.players(2).pos = [194.2, 1.0];
        cameraX = 193.8;
    case 'campus-bus-lamps'
        state.levelTime = 5.6;
        state = stepWorldBus(state, world, cfg, 0);
        bus = state.levelState.bus.rects(1, :);
        state.players(1).pos = [bus(1) + 2.0, bus(2) + bus(4) + 0.65];
        state.players(2).pos = [bus(1) + 4.1, bus(2) + bus(4)];
        state.players(1).vel(2) = 5.0;
        cameraX = 210.0;
    case 'sports-center-finish'
        state.levelTime = (244-world.mechanic.bus.loopStart)/world.mechanic.bus.speed;
        state = stepWorldBus(state, world, cfg, 0);
        bus = state.levelState.bus.rects(1, :);
        state.players(1).pos = [bus(1) + 1.8, bus(2) + bus(4)];
        state.players(2).pos = [bus(1) + 4.2, bus(2) + bus(4)];
        cameraX = world.worldWidth - cfg.render.viewportWidth / 2;
    otherwise
        error('matlabHi:UnknownSnapshotScene', 'Unknown scene %s.', sceneName);
end
% Staged visual fixtures must still show progress consistent with this area.
if cameraX>105
    state.levelState.network.authenticated=true;
    state.levelState.network.pageMode='success';
    state.levelState.network.failureSeen=true;
    state.checkpointIndex=4;
end
if cameraX>=153, state.checkpointIndex=5; end
if cameraX>=173
    state.levelState.bicycle.phase='landed';
    state.levelState.bicycle.landed=true;
    state.checkpointIndex=6;
end
if cameraX>=190, state.checkpointIndex=7; end
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
