function testNetworkPlatforms()
%TESTNETWORKPLATFORMS Lock the new physical and non-physical page controls.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state = stepWorldNetwork(state, world, cfg, 0);
network = world.mechanic.network;

assert(hasRect(state.levelState.colliders, network.noticePanel), ...
    'The notice panel is not a physical landing object.');
assert(hasRect(state.levelState.colliders, network.loginButton) && ...
    hasRect(state.levelState.colliders, network.selfServiceButton), ...
    'Login and self-service are not both physical platforms.');
successRight = network.successFloor(1) + network.successFloor(3);
assert(network.successFloor(1) <= network.pageRect(1) && ...
    successRight >= network.exitPlatform(1) + network.exitPlatform(3), ...
    'The successful page floor does not reach the named playground exit.');
nonPhysical = [network.usernameField; network.passwordField; ...
    network.rememberCheckbox; network.rechargePads];
for index = 1:size(nonPhysical, 1)
    assert(~hasRect(state.levelState.colliders, nonPhysical(index, :)), ...
        'A trigger or recharge control still blocks/floors the route.');
end
oldHelpers = [71.0, 1.8, 5.0, 0.45; 77.0, 3.0, 4.2, 0.45];
for index = 1:size(oldHelpers, 1)
    assert(~hasRect(world.platforms, oldHelpers(index, :)), ...
        'An obsolete light-blue helper platform remains in the world.');
end

state.levelState.network.failureSeen = true;
state.levelState.network.pageMode = 'retry';
state.levelState.network.credentialsReady = true;
loginTop = network.loginButton(2) + network.loginButton(4);
state.players(1).pos = [network.loginButton(1) + 0.3, loginTop];
state.players(2).pos = [network.loginButton(1) + ...
    network.loginButton(3) - 0.3, loginTop];
state = stepWorldNetwork(state, world, cfg, 0);
for stepIndex = 1:ceil(network.loadingDuration / cfg.physics.fixedDt) + 1
    state = stepWorldNetwork(state, world, cfg, cfg.physics.fixedDt);
end
assert(strcmp(state.levelState.network.pageMode, 'success') && ...
    hasRect(state.levelState.colliders, network.successFloor), ...
    'The successful page did not replace web controls with a road floor.');
assert(~hasRect(state.levelState.colliders, network.noticePanel) && ...
    ~hasRect(state.levelState.colliders, network.loginButton), ...
    'Obsolete login-page platforms survived on the successful page.');
end

function tf = hasRect(rects, target)
tf = any(all(abs(rects - target) < 1e-9, 2));
end
