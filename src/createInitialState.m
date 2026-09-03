function state = createInitialState(level, cfg, previousStats)
%CREATEINITIALSTATE Build all mutable state for one level.

if nargin < 3 || isempty(previousStats)
    previousStats = struct( ...
        'elapsed', 0, ...
        'failures', 0, ...
        'ropePulls', 0, ...
        'maxTension', 0, ...
        'trajectory', zeros(0, 6));
end

playerTemplate = struct( ...
    'pos', [0, 0], ...
    'vel', [0, 0], ...
    'size', [cfg.player.width, cfg.player.height], ...
    'mass', cfg.player.mass, ...
    'onGround', false, ...
    'jumpHeld', false, ...
    'moveIntent', 0);

state.players = repmat(playerTemplate, 1, 2);
for playerIndex = 1:2
    state.players(playerIndex).pos = level.spawn(playerIndex, :);
end

state.levelId = level.id;
state.levelTime = 0;
state.levelTrajectory = zeros(0, 5);
state.trajectorySampleClock = 0;
state.completed = false;
state.requestReset = false;
state.requestQuit = false;
state.paused = false;
state.checkpointIndex = 1;
state.stats = previousStats;
state.rope.currentTension = 0;
state.rope.tautLast = false;
state.input.previousPause = false;
state.input.previousQuit = false;
state.input.resetHeldTime = 0;

state.levelState.colliders = level.platforms;
state.levelState.dynamicObjects = struct();
state.levelState.routeActive = false;
state.levelState.routeTimer = 0;
state.levelState.confirmTimer = 0;
state.levelState.bottleCollected = false;
state.levelState.slowTimer = 0;
state.levelState.auxCurve = zeros(0, 2);
state.levelState.auxPlatforms = zeros(0, 4);
state.levelState.auxCreated = false;

state.render.initialized = false;
state.render.levelId = 0;
state.render.handles = struct();
end
