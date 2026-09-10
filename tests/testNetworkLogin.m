function testNetworkLogin()
%TESTNETWORKLOGIN Verify retry loading and the persistent success page.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
network = world.mechanic.network;
state = createInitialState(world, cfg, []);
loginTop = network.loginButton(2) + network.loginButton(4);

state.players(1).pos = [network.loginButton(1) + 0.3, loginTop];
state.players(2).pos = [network.loginButton(1) + ...
    network.loginButton(3) - 0.3, loginTop];
state = stepWorldNetwork(state, world, cfg, 0);
assert(strcmp(state.levelState.network.feedback, 'needCredentials') && ...
    ~state.levelState.network.authenticated, ...
    'Login advanced without the username trigger.');

state.levelState.network.credentialsReady = true;
state.levelState.network.failureSeen = true;
state.levelState.network.pageMode = 'retry';
state.levelState.network.loginPressLatched = false;
state.players(2).pos = [network.pageRect(1) + 1.0, 2.25];
state = stepWorldNetwork(state, world, cfg, 0);
assert(strcmp(state.levelState.network.feedback, 'needPartner'), ...
    'A single pear did not receive the partner requirement on retry.');

state.levelState.network.loginPressLatched = false;
state.players(2).pos = [network.loginButton(1) + ...
    network.loginButton(3) - 0.3, loginTop];
state = stepWorldNetwork(state, world, cfg, 0);
assert(strcmp(state.levelState.network.pageMode, 'loading') && ...
    ~state.levelState.network.authenticated, ...
    'Two pears did not enter the in-place loading phase.');

for index = 1:ceil(network.loadingDuration / cfg.physics.fixedDt) + 1
    state = stepWorldNetwork(state, world, cfg, cfg.physics.fixedDt);
end
assert(strcmp(state.levelState.network.pageMode, 'success') && ...
    state.levelState.network.authenticated, ...
    'Loading did not replace the page with the authenticated state.');
assert(~hasRect(state.levelState.colliders, network.authGate) && ...
    hasRect(state.levelState.colliders, network.successFloor), ...
    'Success did not open the route while preserving a walkable world floor.');

pageRectBefore = state.levelState.dynamicObjects.network.pageRect;
state.players(1).pos(1) = network.pageRect(1) + network.pageRect(3) + 5;
state.players(2).pos(1) = state.players(1).pos(1) + 1.2;
state = stepWorldNetwork(state, world, cfg, 2.0);
assert(strcmp(state.levelState.network.pageMode, 'success') && ...
    isequal(pageRectBefore, state.levelState.dynamicObjects.network.pageRect), ...
    'Walking away hid, moved, or replaced the successful world plane.');
end

function tf = hasRect(rects, target)
tf = any(all(abs(rects - target) < 1e-9, 2));
end
