function framesPerSecond = runPerformanceCheck(lowPowerMode)
%RUNPERFORMANCECHECK Measure every visual pocket on the development Mac.
% Forced drawnow is stricter than the interactive loop's drawnow limitrate.
% This local evidence still does not replace testing on the target Windows PC.

if nargin < 1
    lowPowerMode = true;
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
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
level = continuousCampusWorld();

fig = figure('Visible', 'off', 'Position', [50, 50, cfg.render.windowSize], ...
    'Color', [0.08, 0.12, 0.15], ...
    'GraphicsSmoothing', cfg.render.graphicsSmoothing);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);
sceneNames = {'north-lake', 'network-race', 'traffic', 'bicycle', 'campus'};
sceneCentres = [26, 82, 122, 154, mean([level.mechanic.bus.loopStart,level.mechanic.bus.finishX])];
sceneFps = zeros(size(sceneCentres));
warmupFrames = 30;
frameCount = 120;
for sceneIndex = 1:numel(sceneCentres)
    centre = sceneCentres(sceneIndex);
    state = createPerformanceScene(level, cfg, centre);
    for index = 1:warmupFrames
        state = advancePerformanceFrame(state, level, cfg, centre, index);
        state = renderFrame(fig, ax, state, level, cfg);
        drawnow;
    end
    clock = tic;
    for index = 1:frameCount
        state = advancePerformanceFrame(state, level, cfg, centre, index);
        state = renderFrame(fig, ax, state, level, cfg);
        drawnow;
    end
    sceneFps(sceneIndex) = frameCount / toc(clock);
    fprintf('FORCED %-12s %5.1f FPS at %dx%d\n', sceneNames{sceneIndex}, ...
        sceneFps(sceneIndex), cfg.render.windowSize);
end
framesPerSecond = min(sceneFps);
fprintf('LOCAL FORCED-RENDER MINIMUM: %.1f FPS across all five pockets\n', ...
    framesPerSecond);
assert(all(sceneFps > 40), ...
    'At least one visual pocket did not exceed the required target of 40 FPS.');
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
