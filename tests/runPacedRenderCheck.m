function framesPerSecond = runPacedRenderCheck(lowPowerMode)
%RUNPACEDRENDERCHECK Verify scheduled frames use full screen updates.

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
guard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);

sceneNames = {'north-lake', 'network-race', 'traffic', 'bicycle', 'campus'};
sceneCentres = [26, 82, 122, 154, 220];
sceneFps = zeros(size(sceneCentres));
sampleDuration = 5;
renderInterval = 1 / cfg.render.targetHz;
java.util.concurrent.locks.LockSupport.parkNanos(int64(250000));
for sceneIndex = 1:numel(sceneCentres)
    centre = sceneCentres(sceneIndex);
    state = createPerformanceScene(level, cfg, centre);
    for index = 1:30
        state = advancePerformanceFrame(state, level, cfg, centre, index);
        state = renderFrame(fig, ax, state, level, cfg);
        drawnow;
    end
    sampleClock = tic;
    previousRender = -inf;
    frameCount = 0;
    stepIndex = 0;
    while toc(sampleClock) < sampleDuration
        nowTime = toc(sampleClock);
        if nowTime - previousRender >= renderInterval
            stepIndex = stepIndex + 1;
            state = advancePerformanceFrame( ...
                state, level, cfg, centre, stepIndex);
            state = renderFrame(fig, ax, state, level, cfg);
            drawnow;
            previousRender = nowTime;
            frameCount = frameCount + 1;
        else
            drawnow limitrate;
        end
        java.util.concurrent.locks.LockSupport.parkNanos(int64(250000));
    end
    elapsed = toc(sampleClock);
    sceneFps(sceneIndex) = frameCount / elapsed;
    fprintf('PACED  %-12s %5.1f FPS at %dx%d\n', sceneNames{sceneIndex}, ...
        sceneFps(sceneIndex), cfg.render.windowSize);
end
framesPerSecond = min(sceneFps);
fprintf('PACED FULL-DRAW MINIMUM: %.1f FPS across all five pockets\n', ...
    framesPerSecond);
assert(all(sceneFps > 40), ...
    'At least one paced visual pocket did not exceed 40 displayed updates per second.');
clear guard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
