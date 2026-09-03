function captureSceneSnapshots(outputFolder)
%CAPTURESCENESNAPSHOTS Render deterministic evidence frames for visual QA.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    outputFolder = fullfile(projectRoot, 'docs', 'visuals', 'runtime-snapshots');
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
loaders = {@level01NorthLake, @level02NetworkBridge, ...
    @level03IbitNavigation, @level04DeadlineStorm};
fig = figure('Visible', 'off', 'Position', [50, 50, 1280, 720], ...
    'Color', [0.08, 0.12, 0.15]);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);

for index = 1:numel(loaders)
    level = loaders{index}();
    state = createInitialState(level, cfg, []);
    state.players(1).pos = [level.worldWidth * 0.42, 4.0];
    state.players(2).pos = [level.worldWidth * 0.42 + 4.8, 3.0];
    if index == 1
        state.players(1).pos = [4.0, 1.0];
        state.players(2).pos = [8.6, 1.0];
    elseif index == 2
        state.levelTime = 3.2;
    elseif index == 3
        state.players(1).pos = [8.1, 1];
        state.players(2).pos = [11.8, 1];
        state.levelState.confirmTimer = level.mechanic.confirmDuration;
        state.levelState.routeActive = true;
        state.levelState.routeTimer = level.mechanic.activeDuration;
    elseif index == 4
        state.players(1).pos = [34.0, 1];
        state.players(2).pos = [38.5, 1];
        state.levelState.bottleCollected = true;
        state.levelState.slowTimer = 4.2;
    end
    state = stepLevel(state, level, cfg, 0);
    renderFrame(fig, ax, state, level, cfg);
    drawnow;
    outputPath = fullfile(outputFolder, sprintf('level-%02d.png', index));
    exportgraphics(fig, outputPath, 'Resolution', 120);
end

% Repeat a dense scene at 3:2 to detect aspect-ratio clipping.
set(fig, 'Position', [50, 50, 1200, 800]);
level = level02NetworkBridge();
state = createInitialState(level, cfg, []);
state.players(1).pos = [12.0, 3.0];
state.players(2).pos = [16.0, 3.0];
state.levelTime = 3.2;
state = stepLevel(state, level, cfg, 0);
renderFrame(fig, ax, state, level, cfg);
drawnow;
exportgraphics(fig, fullfile(outputFolder, 'level-02-3x2.png'), ...
    'Resolution', 120);
fprintf('WROTE 5 RUNTIME SNAPSHOTS TO %s\n', outputFolder);
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
