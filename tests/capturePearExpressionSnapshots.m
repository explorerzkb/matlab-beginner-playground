function capturePearExpressionSnapshots(outputFolder)
%CAPTUREPEAREXPRESSIONSNAPSHOTS Render close evidence for the three key faces.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputFolder = fullfile(projectRoot, 'docs', 'visuals', ...
        'runtime-snapshots-final', 'expressions');
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
sceneNames = {'airborne-joy', 'head-impact-pain', 'rope-pull-gaze'};
fig = figure('Visible', 'off', 'Position', [50, 50, 1280, 720], ...
    'Color', [0.08, 0.12, 0.15], ...
    'GraphicsSmoothing', cfg.render.graphicsSmoothing);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);

for index = 1:numel(sceneNames)
    state = createInitialState(world, cfg, []);
    state = stepLevel(state, world, cfg, 0);
    state.players(1).pos = [24.0, 4.8];
    state.players(2).pos = [27.4, 4.5];
    state.players(1).onGround = false;
    state.players(2).onGround = false;
    switch sceneNames{index}
        case 'airborne-joy'
            state.players(1).vel = [3.2, 8.8];
            state.players(2).vel = [2.6, 7.4];
        case 'head-impact-pain'
            state.players(1).visualImpactTimer = 0.20;
            state.players(1).visualImpactKind = 'ceiling';
            state.players(1).vel = [0, -0.8];
            state.players(2).visualImpactTimer = 0.20;
            state.players(2).visualImpactKind = 'wall';
        case 'rope-pull-gaze'
            state.players(1).pos = [23.0, 4.6];
            state.players(2).pos = [28.8, 5.7];
            state.players(1).vel = [-1.2, 0.2];
            state.players(2).vel = [1.0, 0.2];
            state.rope.currentTension = 38;
    end
    state.render.cameraCentre = mean([state.players(1).pos(1), ...
        state.players(2).pos(1)]);
    state = renderFrame(fig, ax, state, world, cfg); %#ok<NASGU>
    set(findall(ax, 'Type', 'text'), 'Visible', 'off');
    drawnow;
    fullPath = fullfile(outputFolder, [sceneNames{index}, '-full.png']);
    closePath = fullfile(outputFolder, [sceneNames{index}, '.png']);
    exportgraphics(fig, fullPath, 'Resolution', 180);
    rgb = imread(fullPath);
    rows = round(size(rgb, 1) * 0.20):round(size(rgb, 1) * 0.82);
    columns = round(size(rgb, 2) * 0.23):round(size(rgb, 2) * 0.77);
    imwrite(rgb(rows, columns, :), closePath);
    delete(fullPath);
end
fprintf('WROTE %d PEAR EXPRESSION SNAPSHOTS TO %s\n', ...
    numel(sceneNames), outputFolder);
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
