function testBicycleLaunch()
%TESTBICYCLELAUNCH Verify the junction warning and unavoidable safe flight.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
data = world.mechanic.bicycle;
state = createInitialState(world, cfg, []);
state = stepWorldBicycle(state, world, cfg, 0);

state.players(1).pos = [data.triggerZone(1) + 1.0, 1.0];
state.players(2).pos = [data.triggerZone(1) - 2.0, 1.0];
state.players(1).vel = [-5.0, 0];
state.players(2).vel = [0, 0];
heartsBefore = state.status.currentHearts;
state = stepWorldBicycle(state, world, cfg, 0);
assert(strcmp(state.levelState.bicycle.phase, 'warning'), ...
    'Entering the junction did not start the bicycle warning.');

% Even reversing or stopping cannot cancel the already-triggered story beat.
state.players(1).vel(1) = -cfg.physics.maxRunSpeed;
state.players(2).vel(1) = 0;
state.players(1).onGround=true;state.players(2).onGround=true;
for tick=1:180
    state = stepWorldBicycle(state, world, cfg, cfg.physics.fixedDt);
    if state.levelState.bicycle.launched, break; end
end
assert(strcmp(state.levelState.bicycle.phase, 'flight') && ...
    state.levelState.bicycle.launched, ...
    'The unavoidable bicycle event did not enter flight.');
for playerIndex = 1:2
    velocity=state.players(playerIndex).vel;
    assert(abs(atan2d(velocity(2),velocity(1))-70)<1e-9 && ...
        norm(velocity)>30, ...
        'Both pears were not launched toward the upper right.');
end
assert(state.status.currentHearts == heartsBefore && ...
    state.stats.damageTaken == 0, ...
    'The story bicycle launch incorrectly consumed a heart.');
assert(state.stats.bicycleLaunches == 1, ...
    'The bicycle launch was not counted exactly once.');
state = stepWorldBicycle(state, world, cfg, 0.1);
assert(state.stats.bicycleLaunches == 1, ...
    'The same bicycle flight was counted more than once.');

landing = data.museumLandingZone;
state.players(1).pos = [landing(1) + 2.0, 1.0];
state.players(2).pos = [landing(1) + 4.0, 1.0];
state = stepWorldBicycle(state, world, cfg, 0);
assert(strcmp(state.levelState.bicycle.phase, 'landed') && ...
    state.levelState.bicycle.landed, ...
    'Landing at the museum did not close the flight state.');
end
