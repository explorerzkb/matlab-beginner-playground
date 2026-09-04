function testNetworkLag()
%TESTNETWORKLAG Force the random gag and verify recovery is deterministic.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state.levelState.network.credentialsReady = true;
state.levelState.network.lagEligible = true;
state.levelState.network.lagDelay = 0;

state = stepWorldNetwork(state, world, cfg, cfg.physics.fixedDt);
assert(strcmp(state.levelState.network.lagPhase, 'warning'), ...
    'Forced network lag did not show its warning phase first.');
assert(hasButtons(state.levelState.colliders, world.mechanic.network), ...
    'The lag warning removed platforms before the warning elapsed.');

warningSteps = ceil(world.mechanic.network.lagWarningDuration / ...
    cfg.physics.fixedDt) + 1;
for index = 1:warningSteps
    state = stepWorldNetwork(state, world, cfg, cfg.physics.fixedDt);
end
assert(strcmp(state.levelState.network.lagPhase, 'outage'), ...
    'The lag warning did not advance to the outage.');
assert(~hasButtons(state.levelState.colliders, world.mechanic.network), ...
    'Login or self-service remained physical during the outage.');

outageSteps = ceil(world.mechanic.network.lagOutageDuration / ...
    cfg.physics.fixedDt) + 1;
for index = 1:outageSteps
    state = stepWorldNetwork(state, world, cfg, cfg.physics.fixedDt);
end
assert(strcmp(state.levelState.network.lagPhase, 'spent') && ...
    hasButtons(state.levelState.colliders, world.mechanic.network), ...
    'The outage did not restore both platforms exactly once.');

dropState = createInitialState(world, cfg, []);
dropState.checkpointIndex = 3;
dropState.levelState.network.rememberChecked = true;
dropState.levelState.network.credentialsReady = true;
dropState.levelState.network.lagPhase = 'outage';
dropState.levelState.network.lagPhaseTimer = ...
    world.mechanic.network.lagOutageDuration;
login = world.mechanic.network.loginButton;
loginTop = login(2) + login(4);
dropState.players(1).pos = [login(1) + 0.30, loginTop];
dropState.players(2).pos = [login(1) + login(3) - 0.30, loginTop];
dropState.players(1).onGround = true;
dropState.players(2).onGround = true;
dropState = stepLevel(dropState, world, cfg, 0);
input = neutralInput();
for index = 1:round(1.8 / cfg.physics.fixedDt)
    dropState = stepPhysics(dropState, input, world, cfg, ...
        cfg.physics.fixedDt);
    dropState = stepLevel(dropState, world, cfg, cfg.physics.fixedDt);
    if dropState.requestReset
        break;
    end
end
assert(dropState.requestReset, ...
    'Removing both button platforms did not make their riders fall.');
dropState = resetToCheckpoint(dropState, world);
dropState = stepLevel(dropState, world, cfg, 0);
positions = vertcat(dropState.players.pos);
notice = world.mechanic.network.noticePanel;
assert(strcmp(dropState.levelState.network.lagPhase, 'spent') && ...
    all(abs(positions(:, 2) - (notice(2) + notice(4))) < 1e-9) && ...
    hasButtons(dropState.levelState.colliders, world.mechanic.network), ...
    'Outage respawn did not restore a safe, retryable route.');
end

function tf = hasButtons(rects, network)
loginPresent = any(all(abs(rects - network.loginButton) < 1e-9, 2));
selfPresent = any(all(abs(rects - network.selfServiceButton) < 1e-9, 2));
tf = loginPresent && selfPresent;
end

function input = neutralInput()
for playerIndex = 1:2
    input.player(playerIndex).left = false;
    input.player(playerIndex).right = false;
    input.player(playerIndex).jump = false;
end
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end
