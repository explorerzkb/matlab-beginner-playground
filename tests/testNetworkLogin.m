function testNetworkLogin()
%TESTNETWORKLOGIN Verify credentials, joint confirmation, and auth gate.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
button = world.mechanic.network.loginButton;
buttonTop = button(2) + button(4);
gate = world.mechanic.network.authGate;

state.players(1).pos = [button(1) + 0.3, buttonTop];
state.players(2).pos = [button(1) + button(3) - 0.3, buttonTop];
state = stepWorldNetwork(state, world, cfg, 0.7);
assert(~state.levelState.network.authenticated && ...
    strcmp(state.levelState.network.feedback, 'needCredentials'), ...
    'Login succeeded without completing the credential fields.');
assert(state.stats.networkAttempts == 1 && hasRect( ...
    state.levelState.colliders, gate), ...
    'Blocked login did not count once or did not keep the auth gate.');

state.levelState.network.credentialsReady = true;
state.players(2).pos = [world.mechanic.network.pageRect(1) + 1, 2.25];
state = stepWorldNetwork(state, world, cfg, 0.7);
assert(~state.levelState.network.authenticated, ...
    'A single player incorrectly completed login confirmation.');

state.players(2).pos = [button(1) + button(3) - 0.3, buttonTop];
state = stepWorldNetwork(state, world, cfg, 0.01);
assert(state.levelState.network.authenticated && ...
    strcmp(state.levelState.network.feedback, 'success'), ...
    'Two pears standing on login did not authenticate immediately.');
assert(~hasRect(state.levelState.colliders, gate), ...
    'Authentication did not remove the physical exit gate.');
end

function tf = hasRect(rects, target)
tf = any(all(abs(rects - target) < 1e-9, 2));
end
