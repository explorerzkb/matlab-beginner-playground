function testLucyRiver()
%TESTLUCYRIVER Verify water clears current break and gates final completion.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state.status.breakValue = 5;
state.players(1).pos = world.finish(1:2) + [0.8, 0];
state.players(2).pos = world.finish(1:2) + [-2.0, 0];

state = stepLevel(state, world, cfg, 0);
assert(state.status.breakValue == 0 && ...
    state.levelState.lucy.touched, ...
    'Touching Lucy River did not clear current break value.');
assert(~state.completed, ...
    'A single player incorrectly completed the continuous journey.');

state.players(2).pos = world.finish(1:2) + [1.8, 0];
state = stepLevel(state, world, cfg, 0);
assert(~state.completed, ...
    'Lucy River bypassed the cooperative Lexue interaction.');
state.levelState.lexue.homeActive = true;
state.levelState.lexue.courseCardReached = true;
state = stepLevel(state, world, cfg, 0);
assert(state.completed, ...
    'Both players could not finish after completing Lexue.');
end
