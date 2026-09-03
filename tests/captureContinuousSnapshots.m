function captureContinuousSnapshots(outputFolder)
%CAPTURECONTINUOUSSNAPSHOTS Render deterministic round-two QA frames.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputFolder = fullfile(projectRoot, 'docs', 'visuals', ...
        'runtime-snapshots-round2');
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
world = continuousCampusWorld();
sceneNames = {'origin', 'north-lake', 'north-lake-shortcut', ...
    'north-lake-east', 'network', ...
    'traffic-bridge', ...
    'traffic-signal', 'lexue', 'lexue-tasks', 'lucy'};
fig = figure('Visible', 'off', 'Position', [50, 50, 1280, 720], ...
    'Color', [0.08, 0.12, 0.15]);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);

for index = 1:numel(sceneNames)
    state = createInitialState(world, cfg, []);
    state = stepLevel(state, world, cfg, 0);
    cameraStart = nan;
    switch sceneNames{index}
        case 'origin'
            state.players(1).pos = [4.1, 1.0];
            state.players(2).pos = [7.8, 1.0];
        case 'north-lake'
            state.players(1).pos = [24.2, 1.0];
            state.players(2).pos = [27.4, 1.0];
            state.levelTime = 1.2;
            cameraStart = 25.5;
        case 'north-lake-east'
            state.players(1).pos = [51.2, 1.0];
            state.players(2).pos = [54.4, 1.0];
            state.levelTime = 1.2;
            cameraStart = 53.0;
        case 'north-lake-shortcut'
            bridge = world.mechanic.animals.shortcutPlatforms;
            state.players(1).pos = [bridge(1) + 2.0, ...
                bridge(2) + bridge(4)];
            state.players(2).pos = [42.0, 1.0];
            state.levelState.animals.shortcutReached = true;
            state.stats.alpacaShortcutUses = 1;
            state.levelTime = 1.2;
            cameraStart = 46.0;
        case 'network'
            username = world.mechanic.network.usernameField;
            password = world.mechanic.network.passwordField;
            state.players(1).pos = [username(1) + 1.0, username(2)];
            state.players(2).pos = [password(1) + 1.0, password(2)];
            state.levelState.network.credentialsTimer = 0.72;
            page = world.mechanic.network.pageRect;
            cameraStart = page(1) + page(3) / 2;
        case 'traffic-bridge'
            state.players(1).pos = [107.7, 5.5];
            state.players(2).pos = [111.1, 5.5];
            state.levelState.traffic.route = 'upper';
            state.stats.trafficRoute = '北理桥';
            cameraStart = 108.0;
        case 'traffic-signal'
            state.players(1).pos = [116.3, 1.0];
            state.players(2).pos = [117.8, 1.0];
            state.levelTime = 4.4;
            state.levelState.traffic.signalClock = state.levelTime;
            state.levelState.traffic.route = 'lower';
            state.stats.trafficRoute = '红绿灯';
        case 'lexue'
            state.players(1).pos = [156.3, 1.93];
            state.players(2).pos = [159.7, 3.33];
            state.levelState.lexue.entered = true;
            state.levelState.lexue.elapsed = 0.82;
            state.levelState.lexue.lastFlipIndex = 0;
        case 'lexue-tasks'
            state.players(1).pos = [178.9, 2.48];
            state.players(2).pos = [180.6, 2.48];
            state.levelState.lexue.entered = true;
            state.levelState.lexue.elapsed = 6;
            state.levelState.lexue.lastFlipIndex = 6;
            state.levelState.lexue.selectionOpen = true;
            state.levelState.lexue.homeActive = true;
            state.levelState.lexue.courseCardReached = true;
            state.levelState.lexue.taskElapsed = 5;
        case 'lucy'
            state.players(1).pos = [196.6, 1.0];
            state.players(2).pos = [198.0, 1.0];
            state.levelState.lexue.entered = true;
            state.levelState.lexue.elapsed = 6;
            state.levelState.lexue.lastFlipIndex = 6;
            state.levelState.lexue.selectionOpen = true;
            state.levelState.lexue.homeActive = true;
            state.levelState.lexue.courseCardReached = true;
    end
    state = stepLevel(state, world, cfg, 0);
    if isnan(cameraStart)
        cameraStart = mean([state.players(1).pos(1), ...
            state.players(2).pos(1)]);
    end
    state.render.cameraCentre = cameraStart;
    state = renderFrame(fig, ax, state, world, cfg); %#ok<NASGU>
    drawnow;
    exportgraphics(fig, fullfile(outputFolder, ...
        [sceneNames{index}, '.png']), 'Resolution', 120);
end
fprintf('WROTE %d CONTINUOUS-WORLD SNAPSHOTS TO %s\n', ...
    numel(sceneNames), outputFolder);
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
