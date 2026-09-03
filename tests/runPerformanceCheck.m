function framesPerSecond = runPerformanceCheck()
%RUNPERFORMANCECHECK Measure forced rendering on the current development Mac.
% This is local evidence only and does not replace Windows target testing.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
cfg.runtime.testMode = true;
level = continuousCampusWorld();
state = createInitialState(level, cfg, []);
state = stepLevel(state, level, cfg, 0);
state.levelState.network.authenticated = true;
state.levelState.lexue.entered = true;
state.levelState.lexue.elapsed = level.mechanic.lexue.countdownDuration;
state.levelState.lexue.lastFlipIndex = ...
    floor(level.mechanic.lexue.countdownDuration);
state.levelState.lexue.selectionOpen = true;
state.levelState.lexue.homeActive = true;
state.levelState.lexue.courseCardReached = true;
state.levelState.lexue.taskElapsed = 5;
state.levelState.traffic.route = 'lower';

fig = figure('Visible', 'off', 'Position', [50, 50, 1280, 720], ...
    'Color', [0.08, 0.12, 0.15]);
cleanupGuard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);
state = renderFrame(fig, ax, state, level, cfg);
drawnow;

frameCount = 120;
clock = tic;
for index = 1:frameCount
    centre = 168 + 3.5 * sin(index / 18);
    state.players(1).pos = [centre - 1.6, 6.0 + 0.4 * sin(index / 7)];
    state.players(2).pos = [centre + 1.6, 6.0 + 0.4 * cos(index / 8)];
    state = stepLevel(state, level, cfg, 1 / 30);
    state = renderFrame(fig, ax, state, level, cfg);
    drawnow;
end
elapsed = toc(clock);
framesPerSecond = frameCount / elapsed;
fprintf('LOCAL FORCED-RENDER RESULT: %.1f FPS at 1280x720\n', framesPerSecond);
assert(framesPerSecond >= 20, ...
    'Local forced rendering did not reach the low-power target of 20 FPS.');
clear cleanupGuard;
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
