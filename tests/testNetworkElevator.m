function testNetworkElevator()
%TESTNETWORKELEVATOR Verify the self-service platform moves and carries riders.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
base = world.mechanic.network.elevatorBase;
state.levelState.network.elevatorRect = base;
state.players(1).pos = [base(1) + 1.5, base(2) + base(4)];
state.players(2).pos = [60, 1];
state.levelTime = world.mechanic.network.elevatorPeriod / 2;

state = stepWorldNetwork(state, world, cfg, 0);
elevator = state.levelState.network.elevatorRect;
expectedRise = world.mechanic.network.elevatorAmplitude;
assert(abs(elevator(2) - base(2) - expectedRise) < 1e-9, ...
    'Self-service platform did not reach its upper position.');
assert(abs(state.players(1).pos(2) - ...
    (base(2) + base(4) + expectedRise)) < 1e-9, ...
    'Player standing on self-service platform was not carried.');
assert(abs(state.players(2).pos(2) - 1) < 1e-9, ...
    'Distant player was incorrectly moved by the self-service platform.');
assert(any(all(abs(state.levelState.colliders - elevator) < 1e-9, 2)), ...
    'Moving self-service platform was not added to collision geometry.');
end
