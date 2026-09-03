function testFountainLaunch()
%TESTFOUNTAINLAUNCH Verify the periodic jet launches only touching players.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
fountain = world.mechanic.traffic.fountainRect;
state = createInitialState(world, cfg, []);
state.players(1).pos = [fountain(1) + 1.2, fountain(2)];
state.players(2).pos = [79, 1];
state.levelTime = 0;

state = stepWorldTraffic(state, world, cfg, 0.01);
assert(state.levelState.traffic.jetActive, ...
    'Fountain did not enter its configured active phase.');
assert(state.players(1).vel(2) >= ...
    world.mechanic.traffic.fountainImpulse(2), ...
    'Active fountain did not launch the touching player.');
assert(all(state.players(2).vel == [0, 0]), ...
    'Fountain incorrectly launched a distant player.');
assert(state.stats.fountainLaunches == 1, ...
    'Fountain launch statistic was not counted once.');

firstVelocity = state.players(1).vel;
state = stepWorldTraffic(state, world, cfg, 0.01);
assert(all(state.players(1).vel == firstVelocity) && ...
    state.stats.fountainLaunches == 1, ...
    'Fountain retriggered during the player cooldown.');

state.levelTime = world.mechanic.traffic.fountainActiveDuration + 0.1;
state.levelState.traffic.fountainClock = state.levelTime;
state.levelState.traffic.fountainCooldowns(:) = 0;
state.players(1).vel = [0, 0];
state = stepWorldTraffic(state, world, cfg, 0.01);
assert(~state.levelState.traffic.jetActive && ...
    all(state.players(1).vel == [0, 0]), ...
    'Inactive fountain applied an impulse.');
end
