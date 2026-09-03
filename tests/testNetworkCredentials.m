function testNetworkCredentials()
%TESTNETWORKCREDENTIALS Verify two players must occupy distinct fields.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
username = world.mechanic.network.usernameField;
password = world.mechanic.network.passwordField;

state.players(1).pos = [username(1) + 0.6, username(2)];
state.players(2).pos = [username(1) + 1.4, username(2)];
state = stepWorldNetwork(state, world, cfg, 1.1);
assert(~state.levelState.network.credentialsReady, ...
    'Two players in the same field incorrectly completed credentials.');

state.players(2).pos = [password(1) + 1.0, password(2)];
state = stepWorldNetwork(state, world, cfg, 0.45);
assert(~state.levelState.network.credentialsReady, ...
    'Credentials completed before the configured cooperative hold.');
state = stepWorldNetwork(state, world, cfg, 0.55);
assert(state.levelState.network.credentialsReady, ...
    'Distinct players did not complete the cooperative credentials.');
assert(all(state.levelState.network.fieldOccupancy == [1, 1]), ...
    'Field occupancy was not exposed for rendering feedback.');
end
