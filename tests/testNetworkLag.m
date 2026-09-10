function testNetworkLag()
%TESTNETWORKLAG Verify the deterministic full-page timeout and recovery.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
network = world.mechanic.network;
state = createInitialState(world, cfg, []);
state.checkpointIndex = 3;
state.levelState.network.credentialsReady = true;
loginTop = network.loginButton(2) + network.loginButton(4);
state.players(1).pos = [network.loginButton(1) + 0.30, loginTop];
state.players(2).pos = [network.noticePanel(1) + 1.0, ...
    network.noticePanel(2) + network.noticePanel(4)];

heartsBefore = state.status.currentHearts;
state = stepWorldNetwork(state, world, cfg, 0);
assert(strcmp(state.levelState.network.pageMode, 'timeout') && ...
    state.levelState.network.failureSeen && ...
    state.stats.networkAttempts == 1, ...
    'The first login contact did not deterministically open the timeout page.');
assert(~hasPageSupports(state.levelState.colliders, network), ...
    'The timeout page still supported a pear with login-page geometry.');
assert(hasRect(state.levelState.colliders, network.authGate), ...
    'The timeout page lost the gate that prevents skipping the retry.');

input = neutralInput();
for index = 1:round(2.5 / cfg.physics.fixedDt)
    state = stepPhysics(state, input, world, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
    if state.requestReset
        break;
    end
end
assert(state.requestReset && ...
    state.status.currentHearts == heartsBefore, ...
    'Timeout falling did not reset harmlessly.');

state = resetToCheckpoint(state, world);
state = stepLevel(state, world, cfg, 0);
positions = vertcat(state.players.pos);
noticeTop = network.noticePanel(2) + network.noticePanel(4);
assert(strcmp(state.levelState.network.pageMode, 'retry') && ...
    state.levelState.network.failureSeen && ...
    all(abs(positions(:, 2) - noticeTop) < 1e-9) && ...
    hasPageSupports(state.levelState.colliders, network), ...
    'Timeout reset did not restore one safe, non-repeating login route.');
end

function tf = hasPageSupports(rects, network)
tf = hasRect(rects, network.noticePanel) || ...
    hasRect(rects, network.loginButton) || ...
    hasRect(rects, network.selfServiceButton);
end

function tf = hasRect(rects, target)
tf = any(all(abs(rects - target) < 1e-9, 2));
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
