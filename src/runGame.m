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
    'GraphicsSmoothing', cfg.render.graphicsSmoothing, ...
    'Visible', visibility, ...
    'Position', [80, 80, cfg.render.windowSize]);
ax = axes(fig, 'Position', [0.045, 0.08, 0.92, 0.86]);
installInputCallbacks(fig);
cleanupGuard = onCleanup(@() cleanupGame(fig));
setappdata(fig,'inputMode',cfg.input.mode);
if strcmp(cfg.input.mode,'pose') && ~cfg.runtime.testMode
    setPoseMode(fig,cfg,'pose');
end

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
            flushFigurePose(fig,false);
            state = runPrologue(fig, ax, state, level, cfg);
            flushFigurePose(fig,false);
            state = runInteractiveLevel(fig, ax, state, level, cfg);
            flushFigurePose(fig,false);
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
% Prime the JVM call before starting telemetry; its first invocation can
% take more than a second on a cold MATLAB process.
java.util.concurrent.locks.LockSupport.parkNanos(int64(250000));
clock = tic;
previousTime = toc(clock);
accumulator = 0;
lastRenderTime = -inf;
renderInterval = 1 / cfg.render.targetHz;
telemetry = initializeTelemetry();
manualPaused=state.paused;
previousToggle=false; previousCalibration=false;

while ~state.completed && ~state.requestQuit && isgraphics(fig)
    if closeWasRequested(fig)
        state.requestQuit = true;
        break;
    end
    nowTime = toc(clock);
    rawFrameDelta = nowTime - previousTime;
    frameDelta = min(rawFrameDelta, cfg.runtime.maxFrameDelta);
    previousTime = nowTime;
    input = readInputSnapshot(fig, cfg.input);
    if input.toggleMode && ~previousToggle
        if input.poseMode, mode='keyboard'; else, mode='pose'; end
        setPoseMode(fig,cfg,mode);
        if strcmp(mode,'pose'), cfg.render.targetHz=cfg.pose.renderHz;
        else, cfg.render.targetHz=50;
        end
        renderInterval=1/cfg.render.targetHz;
        manualPaused=false;
        state.input.bufferedLeft=[false false];
        state.input.bufferedRight=[false false];
        state.input.bufferedJumps=[false false];
        accumulator=0; previousTime=toc(clock);
        input=readInputSnapshot(fig,cfg.input);
    end
    previousToggle=input.toggleMode;
    if input.recalibrate && ~previousCalibration
        flushFigurePose(fig,true);
    end
    previousCalibration=input.recalibrate;
    state.input.bufferedLeft = state.input.bufferedLeft | ...
        [input.player(1).left, input.player(2).left];
    state.input.bufferedRight = state.input.bufferedRight | ...
        [input.player(1).right, input.player(2).right];
    state.input.bufferedJumps = state.input.bufferedJumps | ...
        [input.player(1).jump, input.player(2).jump];
    state.input.bufferedUseItem = state.input.bufferedUseItem || input.useItem;

    pauseEdge = input.pause && ~state.input.previousPause;
    quitEdge = input.quit && ~state.input.previousQuit;
    state.input.previousPause = input.pause;
    state.input.previousQuit = input.quit;
    if pauseEdge
        manualPaused = ~manualPaused;
        flushFigurePose(fig,false);
        state.input.bufferedLeft = [false false];
        state.input.bufferedRight = [false false];
        state.input.bufferedJumps = [false false];
        state.input.bufferedUseItem = false;
    end
    currentPose=readFigurePose(fig,poseClock(),false,true);
    input.safetyPause=currentPose.safetyPause;
    state.paused=manualPaused || input.safetyPause;
    if input.poseMode
        state.input.bufferedLeft=[false false];
        state.input.bufferedRight=[false false];
        state.input.bufferedJumps=[false false];
    end
    if state.paused
        accumulator=0;
        readFigurePose(fig,poseClock(),true,false);
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
        if cfg.runtime.validationMode
            telemetry = recordElapsedTime(telemetry, state, rawFrameDelta);
        end
        accumulator = accumulator + frameDelta;
        substeps = 0;
        while accumulator >= cfg.physics.fixedDt && ...
                substeps < cfg.physics.maxSubsteps
            stepInput = input;
            for playerIndex = 1:2
                stepInput.player(playerIndex).left = ...
                    input.player(playerIndex).left || ...
                    state.input.bufferedLeft(playerIndex);
                stepInput.player(playerIndex).right = ...
                    input.player(playerIndex).right || ...
                    state.input.bufferedRight(playerIndex);
                stepInput.player(playerIndex).jump = input.player(playerIndex).jump || ...
                    state.input.bufferedJumps(playerIndex);
            end
            stepInput.useItem = input.useItem || state.input.bufferedUseItem;
            if input.poseMode
                poseInput=readFigurePose(fig,poseClock(),true,true);
                stepInput.player=poseInput.player;
            end
            state = stepConsumables(state, stepInput, cfg, cfg.physics.fixedDt);
            state = stepPhysics(state, stepInput, level, cfg, cfg.physics.fixedDt);
            state.input.bufferedLeft = [false false];
            state.input.bufferedRight = [false false];
            state.input.bufferedJumps = [false false];
            state.input.bufferedUseItem = false;
            state = stepLevel(state, level, cfg, cfg.physics.fixedDt);
            accumulator = accumulator - cfg.physics.fixedDt;
            substeps = substeps + 1;
            if state.requestReset
                playSoundCue('failure', cfg);
                state = resetToCheckpoint(state, level, cfg);
                flushFigurePose(fig,false);
                accumulator=0;
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

    if nowTime - lastRenderTime >= renderInterval
        if input.poseMode
            state.poseStatus='等待摄像头／校准 · C 重校准 · K 键盘';
            if isappdata(fig,'poseSession')
                session=getappdata(fig,'poseSession');
                state.poseStatus=session.state.reason;
                if strcmp(session.state.phase,'countdown')
                    state.poseStatus=sprintf('稳定恢复：%.0f 秒', ...
                        max(0,ceil(session.state.countdownUntil-poseClock())));
                end
                if ~isempty(session.error), state.poseStatus='摄像头／推理异常 · K 切键盘'; end
            end
        else
            state.poseStatus='';
        end
        state = renderFrame(fig, ax, state, level, cfg);
        % A scheduled gameplay frame must reach the display. MATLAB caps
        % drawnow limitrate at 20 screen updates per second, below our 50 Hz
        % target; use a full update here and reserve limitrate for callback
        % polling between scheduled frames.
        drawnow;
        lastRenderTime = nowTime;
        if cfg.runtime.validationMode && ~state.paused
            telemetry = recordRenderedFrame(telemetry, state);
            if telemetry.liveSeconds >= 1
                liveFps = telemetry.liveFrames / telemetry.liveSeconds;
                set(fig, 'Name', sprintf('%s  |  %.1f FPS', ...
                    cfg.presentation.title, liveFps));
                telemetry.liveSeconds = 0;
                telemetry.liveFrames = 0;
            end
        end
    else
        drawnow limitrate;
    end
    % Park briefly without calling pause. MATLAB documents pause as a full
    % drawnow equivalent, so using it in every polling iteration can flush
    % redundant frames. A short JVM park also avoids a hot busy-wait while
    % preserving sub-millisecond input polling between 60 Hz physics steps.
    java.util.concurrent.locks.LockSupport.parkNanos(int64(250000));
end
if cfg.runtime.validationMode
    saveInteractiveTelemetry(telemetry, state, cfg);
    if isgraphics(fig)
        set(fig, 'Name', cfg.presentation.title);
    end
end
end

function telemetry = initializeTelemetry()
telemetry.names = {'north-lake', 'network-race', 'traffic', 'bicycle', 'campus'};
telemetry.boundaries = [54, 102, 138, 187];
telemetry.seconds = zeros(1, 5);
telemetry.frames = zeros(1, 5);
telemetry.liveSeconds = 0;
telemetry.liveFrames = 0;
end

function telemetry = recordElapsedTime(telemetry, state, elapsed)
index = telemetryPocket(telemetry, state);
telemetry.seconds(index) = telemetry.seconds(index) + elapsed;
telemetry.liveSeconds = telemetry.liveSeconds + elapsed;
end

function telemetry = recordRenderedFrame(telemetry, state)
index = telemetryPocket(telemetry, state);
telemetry.frames(index) = telemetry.frames(index) + 1;
telemetry.liveFrames = telemetry.liveFrames + 1;
end

function index = telemetryPocket(telemetry, state)
centre = mean([state.players(1).pos(1), state.players(2).pos(1)]);
index = 1 + sum(centre >= telemetry.boundaries);
end

function saveInteractiveTelemetry(telemetry, state, cfg)
folder = fullfile(cfg.projectRoot, 'windows-validation-results');
if ~isfolder(folder)
    mkdir(folder);
end
stamp = char(datetime('now', 'Format', 'yyyyMMdd-HHmmss-SSS'));
path = fullfile(folder, ['interactive-', stamp, '.txt']);
file = fopen(path, 'w');
if file < 0
    warning('matlabHi:TelemetryWriteFailed', ...
        '无法写入验收日志：%s', path);
    return;
end
guard = onCleanup(@() fclose(file));
fprintf(file, 'MATLABHI INTERACTIVE PERFORMANCE\n');
fprintf(file, 'Time: %s\nMATLAB: %s\nComputer: %s\n', ...
    char(datetime('now')), version, computer);
fprintf(file, 'ispc: %d\n', ispc);
fprintf(file, 'Scale: %s\n', cfg.runtime.validationScale);
fprintf(file, 'Planned route: %s\n', cfg.runtime.validationPlannedRoute);
fprintf(file, 'Player 2 keys: %s\n', cfg.runtime.validationPlayer2Keys);
fprintf(file, 'Session label: %s\n', cfg.runtime.validationSessionLabel);
fprintf(file, 'Two-person session: %d\n', cfg.runtime.validationTwoPerson);
actualRoute = 'undecided';
if isfield(state.levelState, 'traffic') && ...
        isfield(state.levelState.traffic, 'route')
    actualRoute = state.levelState.traffic.route;
end
fprintf(file, 'Actual route: %s\n', actualRoute);
fprintf(file, 'Window: %d x %d | target render: %.1f Hz | physics: %.1f Hz\n', ...
    cfg.render.windowSize, cfg.render.targetHz, 1 / cfg.physics.fixedDt);
fprintf(file, 'Completed: %d | game seconds: %.1f\n\n', ...
    state.completed, state.stats.elapsed);
for index = 1:numel(telemetry.names)
    if telemetry.seconds(index) > 0
        fps = telemetry.frames(index) / telemetry.seconds(index);
    else
        fps = NaN;
    end
    enough = telemetry.seconds(index) >= 2;
    fprintf(file, '%-12s %6.1f FPS | %.1f s | %d frames | enough sample: %d\n', ...
        telemetry.names{index}, fps, telemetry.seconds(index), ...
        telemetry.frames(index), enough);
end
fprintf(file, ['\nA pocket needs at least 2 seconds of gameplay before its FPS is ', ...
    'usable evidence. This file does not prove keyboard feel or visual quality.\n']);
fprintf('INTERACTIVE PERFORMANCE LOG: %s\n', path);
clear guard;
end

function state = runTestLevel(fig, ax, state, level, cfg)
duration = max(0.18, cfg.runtime.testDuration);
steps = ceil(duration / cfg.physics.fixedDt);
for index = 1:steps
    input = syntheticInput(index);
    state = stepConsumables(state, input, cfg, cfg.physics.fixedDt);
    state = stepPhysics(state, input, level, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, level, cfg, cfg.physics.fixedDt);
    if state.requestReset
        state = resetToCheckpoint(state, level, cfg);
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
