function state = createInitialState(level, cfg, previousStats)
%CREATEINITIALSTATE Build all mutable state for one level.

if nargin < 3 || isempty(previousStats)
    previousStats = struct( ...
        'elapsed', 0, ...
        'failures', 0, ...
        'ropePulls', 0, ...
        'maxTension', 0, ...
        'maxBreakValue', 0, ...
        'teaCollected', 0, ...
        'teaUsed', 0, ...
        'alpacaBoosts', 0, ...
        'fountainLaunches', 0, ...
        'networkAttempts', 0, ...
        'selectionAttempts', 0, ...
        'trafficWaitTime', 0, ...
        'trafficRoute', '未选择', ...
        'trajectory', zeros(0, 6));
end
previousStats = addMissingStats(previousStats);

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

state.status.breakValue = 0;
state.status.hitCooldown = 0;
state.status.totalBreakdowns = 0;
state.inventory.teaCount = 0;
state.inventory.teaMax = cfg.tea.maxCarried;
state.inventory.collectedTeaIds = strings(0, 1);
state.inventory.buffTimer = 0;
state.inventory.useHeldTime = 0;
state.inventory.useLatched = false;
state.world.activeRegionIndex = 1;
state.world.previousRegionIndex = 1;
state.levelState.network.credentialsTimer = 0;
state.levelState.network.credentialsReady = false;
state.levelState.network.fieldOccupancy = [0, 0];
state.levelState.network.rememberChecked = false;
state.levelState.network.loginTimer = 0;
state.levelState.network.loginPressLatched = false;
state.levelState.network.authenticated = false;
state.levelState.network.feedback = 'idle';

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

function stats = addMissingStats(stats)
defaults = struct( ...
    'maxBreakValue', 0, ...
    'teaCollected', 0, ...
    'teaUsed', 0, ...
    'alpacaBoosts', 0, ...
    'fountainLaunches', 0, ...
    'networkAttempts', 0, ...
    'selectionAttempts', 0, ...
    'trafficWaitTime', 0, ...
    'trafficRoute', '未选择');
names = fieldnames(defaults);
for index = 1:numel(names)
    name = names{index};
    if ~isfield(stats, name)
        stats.(name) = defaults.(name);
    end
end
end
