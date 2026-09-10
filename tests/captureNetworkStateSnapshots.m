function captureNetworkStateSnapshots(outputFolder)
%CAPTURENETWORKSTATESNAPSHOTS Render the four fixed world-page states.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputFolder = fullfile(projectRoot, 'docs', 'visuals', ...
        'runtime-snapshots-network-v6');
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
page = world.mechanic.network.pageRect;
login = world.mechanic.network.loginButton;
notice = world.mechanic.network.noticePanel;
fig = figure('Visible', 'off', 'Position', [50, 50, 1280, 720], ...
    'Color', [0.08, 0.12, 0.15], ...
    'GraphicsSmoothing', cfg.render.graphicsSmoothing);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);

modes = {'login', 'timeout', 'loading', 'success'};
for index = 1:numel(modes)
    mode = modes{index};
    state = createInitialState(world, cfg, []);
    state = stepLevel(state, world, cfg, 0);
    state.levelState.network.credentialsReady = true;
    state.levelState.network.failureSeen = ~strcmp(mode, 'login');
    state.levelState.network.pageMode = mode;
    state.levelState.network.feedback = mode;

    switch mode
        case 'login'
            state.players(1).pos = [notice(1) + 0.60 * notice(3), ...
                notice(2) + notice(4)];
            state.players(2).pos = [login(1) - 0.55, ...
                login(2) + login(4) + 0.65];
        case 'timeout'
            state.players(1).pos = [login(1) + 0.30, 2.10];
            state.players(2).pos = [login(1) + login(3) + 0.65, 3.00];
            state.players(1).vel(2) = -5.0;
            state.players(2).vel(2) = -4.4;
        case 'loading'
            loginTop = login(2) + login(4);
            state.players(1).pos = [login(1) + 0.30, loginTop];
            state.players(2).pos = [login(1) + login(3) - 0.30, loginTop];
            state.levelState.network.loadingTimer = 0.45;
        case 'success'
            floorTop = world.mechanic.network.successFloor(2) + ...
                world.mechanic.network.successFloor(4);
            state.players(1).pos = [page(1) + 0.61 * page(3), floorTop];
            state.players(2).pos = [page(1) + 0.71 * page(3), floorTop];
            state.levelState.network.authenticated = true;
    end

    state = stepLevel(state, world, cfg, 0);
    state.render.cameraCentre = page(1) + page(3) / 2;
    state = renderFrame(fig, ax, state, world, cfg); %#ok<NASGU>
    drawnow;
    exportgraphics(fig, fullfile(outputFolder, ...
        ['network-', mode, '.png']), 'Resolution', 120);
end

fprintf('WROTE 4 NETWORK-STATE SNAPSHOTS TO %s\n', outputFolder);
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
