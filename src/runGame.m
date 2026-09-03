function runGame(cfg)
%RUNGAME Own the figure lifecycle and the fixed-step game loop.

visibility = 'on';
if cfg.runtime.testMode
    visibility = 'off';
end
fig = figure( ...
    'Name', cfg.presentation.title, ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Color', [0.08, 0.12, 0.15], ...
    'Visible', visibility, ...
    'Position', [80, 80, 1280, 720]);
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);
installInputCallbacks(fig);
cleanupGuard = onCleanup(@() cleanupGame(fig));

restartRequested = true;
while restartRequested && isgraphics(fig)
    if ~cfg.runtime.testMode
        if ~runInputCheck(fig, ax, cfg)
            return;
        end
    end

    stats = [];
    levelLoaders = {@continuousCampusWorld};
    sessionQuit = false;

    for levelIndex = 1:numel(levelLoaders)
        level = levelLoaders{levelIndex}();
        state = createInitialState(level, cfg, stats);
        state = stepLevel(state, level, cfg, 0);

        if cfg.runtime.testMode
            state = runTestLevel(fig, ax, state, level, cfg);
        else
            state = runInteractiveLevel(fig, ax, state, level, cfg);
        end
        stats = state.stats;

        if state.requestQuit || closeWasRequested(fig)
            sessionQuit = true;
            break;
        end
        playSoundCue('checkpoint', cfg);
    end

    if sessionQuit || ~isgraphics(fig) || closeWasRequested(fig)
        return;
    end
    if cfg.runtime.testMode
        return;
    end
    restartRequested = showResults(fig, ax, stats, cfg);
end
clear cleanupGuard;
end

function state = runInteractiveLevel(fig, ax, state, level, cfg)
clock = tic;
previousTime = toc(clock);
accumulator = 0;
lastRenderTime = -inf;
renderInterval = 1 / cfg.render.targetHz;

while ~state.completed && ~state.requestQuit && isgraphics(fig)
    if closeWasRequested(fig)
        state.requestQuit = true;
        break;
    end
    nowTime = toc(clock);
    frameDelta = min(nowTime - previousTime, cfg.runtime.maxFrameDelta);
    previousTime = nowTime;
    input = readInputSnapshot(fig, cfg.input);

    pauseEdge = input.pause && ~state.input.previousPause;
    quitEdge = input.quit && ~state.input.previousQuit;
    state.input.previousPause = input.pause;
    state.input.previousQuit = input.quit;
    if pauseEdge
        state.paused = ~state.paused;
    end
    if quitEdge
        state.requestQuit = true;
    end

    if input.reset
        state.input.resetHeldTime = state.input.resetHeldTime + frameDelta;
    else
        state.input.resetHeldTime = 0;
    end
    if state.input.resetHeldTime >= cfg.runtime.resetHoldDuration
        state.requestReset = true;
    end

    if ~state.paused && ~state.requestQuit
        accumulator = accumulator + frameDelta;
        substeps = 0;
        while accumulator >= cfg.physics.fixedDt && ...
                substeps < cfg.physics.maxSubsteps
            state = stepPhysics(state, input, level, cfg, cfg.physics.fixedDt);
            state = stepLevel(state, level, cfg, cfg.physics.fixedDt);
            accumulator = accumulator - cfg.physics.fixedDt;
            substeps = substeps + 1;
            if state.requestReset
                playSoundCue('failure', cfg);
                state = resetToCheckpoint(state, level);
                break;
            end
            if state.completed
                break;
            end
        end
        if substeps >= cfg.physics.maxSubsteps
            accumulator = min(accumulator, cfg.physics.fixedDt);
        end
    end

    if nowTime - lastRenderTime >= renderInterval || state.paused
        state = renderFrame(fig, ax, state, level, cfg);
        lastRenderTime = nowTime;
    else
        drawnow limitrate;
    end
    pause(0.001);
end
end

function state = runTestLevel(fig, ax, state, level, cfg)
duration = max(0.18, cfg.runtime.testDuration);
steps = ceil(duration / cfg.physics.fixedDt);
for index = 1:steps
    input = syntheticInput(index);
    state = stepPhysics(state, input, level, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, level, cfg, cfg.physics.fixedDt);
    if state.requestReset
        state = resetToCheckpoint(state, level);
    end
    if mod(index, 4) == 1 || index == steps
        state = renderFrame(fig, ax, state, level, cfg);
    end
end
state.completed = true;
end

function input = syntheticInput(index)
input.player(1).left = false;
input.player(1).right = true;
input.player(1).jump = mod(index, 31) == 2;
input.player(2).left = false;
input.player(2).right = true;
input.player(2).jump = mod(index, 37) == 2;
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end

function tf = closeWasRequested(fig)
tf = ~isgraphics(fig);
if ~tf && isappdata(fig, 'closeRequested')
    tf = logical(getappdata(fig, 'closeRequested'));
end
end
