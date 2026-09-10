function testNetworkCredentials()
%TESTNETWORKCREDENTIALS Verify one pear brushing username autofills both fields.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
username = world.mechanic.network.usernameField;
halfWidth = state.players(1).size(1) / 2;
state.players(1).pos = [username(1) - halfWidth - 0.02, username(2)];
state = stepWorldNetwork(state, world, cfg, 0.1);
assert(~state.levelState.network.credentialsReady, ...
    'Credentials filled before a pear body entered the username field.');

state.players(1).pos(1) = username(1) - halfWidth + 0.02;
state = stepWorldNetwork(state, world, cfg, 0.01);
assert(state.levelState.network.credentialsReady, ...
    'A pear body crossing username did not autofill the credentials.');
assert(state.levelState.network.fieldOccupancy(1) == 1, ...
    'Body-overlap occupancy was not exposed for rendering feedback.');
assert(numel(cfg.network.groupStudentIds) == 3 && ...
    strcmp(cfg.network.groupStudentIds{1}, '1120250036') && ...
    strcmp(cfg.network.passwordMask, '**********'), ...
    'Autofill configuration lost the supplied ID or ten-star mask.');
end
