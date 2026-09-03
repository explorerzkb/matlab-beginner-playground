function captureInterfaceSnapshots(outputFolder)
%CAPTUREINTERFACESNAPSHOTS Render HUD and pause-overlay visual evidence.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputFolder = fullfile(projectRoot, 'docs', 'visuals', ...
        'runtime-snapshots-final', 'interface');
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
sceneNames = {'hud-origin', 'pause-north-lake'};
fig = figure('Visible', 'off', 'Position', [50, 50, 1280, 720], ...
    'Color', [0.04, 0.08, 0.10]);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.025, 0.045, 0.95, 0.92]);

for index = 1:numel(sceneNames)
    state = createInitialState(world, cfg, []);
    state = stepLevel(state, world, cfg, 0);
    if strcmp(sceneNames{index}, 'pause-north-lake')
        state.players(1).pos = [25.0, 1.0];
        state.players(2).pos = [28.2, 1.0];
        state.paused = true;
        state.render.cameraCentre = 26.5;
    else
        state.players(1).pos = [4.1, 1.0];
        state.players(2).pos = [7.8, 1.0];
        state.render.cameraCentre = 11.0;
    end
    state = stepLevel(state, world, cfg, 0);
    state = renderFrame(fig, ax, state, world, cfg); %#ok<NASGU>
    drawnow;
    exportgraphics(fig, fullfile(outputFolder, ...
        [sceneNames{index}, '.png']), 'Resolution', 140);
end
fprintf('WROTE %d INTERFACE SNAPSHOTS TO %s\n', ...
    numel(sceneNames), outputFolder);
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
