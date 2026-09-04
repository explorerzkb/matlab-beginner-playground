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
assert(hasRect(world.platforms, network.exitPlatform), ...
    'The named network exit is not part of the static world geometry.');
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
end

function tf = hasRect(rects, target)
tf = any(all(abs(rects - target) < 1e-9, 2));
end
