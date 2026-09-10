function testNetworkCheckpoint()
%TESTNETWORKCHECKPOINT Verify the retry point is reached on page entry.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
network = world.mechanic.network;
state = createInitialState(world, cfg, []);
state.checkpointIndex = 2;

beforeEntry = world.checkpoints(3).x - 0.2;
state.players(1).pos = [beforeEntry, 1];
state.players(2).pos = [beforeEntry + 0.05, 1];
state = stepLevel(state, world, cfg, 0.1);
assert(state.checkpointIndex == 2, ...
    'The network retry checkpoint activated before both pears entered.');

afterEntry = world.checkpoints(3).x + 0.2;
state.players(1).pos = [afterEntry, 1];
state.players(2).pos = [afterEntry + 0.1, 1];
state = stepLevel(state, world, cfg, 0.1);
assert(state.checkpointIndex == 2, ...
    'Passing underneath the page incorrectly teleported progress upstairs.');
noticeTop = network.noticePanel(2) + network.noticePanel(4);
state.players(1).pos(2) = noticeTop;
state.players(2).pos(2) = noticeTop;
state = stepLevel(state, world, cfg, 0.1);
assert(state.checkpointIndex == 3, ...
    'Entering the embedded page did not establish its retry checkpoint.');

state = resetToCheckpoint(state, world);
noticeTop = network.noticePanel(2) + network.noticePanel(4);
positions = vertcat(state.players.pos);
assert(all(abs(positions(:, 2) - noticeTop) < 1e-9) && ...
    all(positions(:, 1) > network.noticePanel(1)) && ...
    all(positions(:, 1) < network.noticePanel(1) + ...
    network.noticePanel(3)), ...
    'The network retry checkpoint is not safely on the notice panel.');
end
