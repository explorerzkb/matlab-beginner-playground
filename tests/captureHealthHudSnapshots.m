function captureHealthHudSnapshots(outputFolder)
%CAPTUREHEALTHHUDSNAPSHOTS Render full and damaged pixel-HUD states.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputFolder = fullfile(projectRoot, 'docs', 'visuals', ...
        'runtime-snapshots-health-v3');
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
fig = figure('Visible', 'off', 'Position', [50, 50, 1280, 720], ...
    'Color', [0.04, 0.08, 0.10], ...
    'GraphicsSmoothing', cfg.render.graphicsSmoothing);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.025, 0.045, 0.95, 0.92]);

names = {'hud-three-hearts', 'hud-one-heart-two-teas'};
for index = 1:numel(names)
    state = createInitialState(world, cfg, []);
    state.players(1).pos = [22.6, 1.0];
    state.players(2).pos = [25.2, 1.0];
    state.render.cameraCentre = 23.5;
    if index == 2
        state.status.currentHearts = 1;
        state.inventory.teaCount = 2;
        state.inventory.buffTimer = 6.4;
        state.rope.currentTension = 48;
    end
    state = stepLevel(state, world, cfg, 0);
    state = renderFrame(fig, ax, state, world, cfg); %#ok<NASGU>
    drawnow;
    exportgraphics(fig, fullfile(outputFolder, ...
        [names{index}, '.png']), 'Resolution', 140);
end
fprintf('WROTE %d HEALTH-HUD SNAPSHOTS TO %s\n', ...
    numel(names), outputFolder);
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
