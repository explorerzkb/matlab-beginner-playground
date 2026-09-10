function testPhysics()
%TESTPHYSICS Exercise rope rules, collision, mechanics, and long simulation.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
cfg = gameConfig(projectRoot);
level = level01NorthLake();
state = createInitialState(level, cfg, []);
state = stepLevel(state, level, cfg, 0);

% A slack rope must exert exactly no force.
state.players(1).pos = [2, 4];
state.players(2).pos = [4, 4];
state.players(1).vel = [0, 0];
state.players(2).vel = [0, 0];
state = applyRopeConstraint(state, cfg, cfg.physics.fixedDt);
assert(state.rope.currentTension == 0, ...
    'Slack rope incorrectly produced tension.');
assert(all(state.players(1).vel == 0) && all(state.players(2).vel == 0), ...
    'Slack rope incorrectly changed player velocity.');

% A taut rope must pull inward and reduce the separation.
state.players(1).pos = [2, 4];
state.players(2).pos = [10, 4];
beforeDistance = norm(state.players(2).pos - state.players(1).pos);
state = applyRopeConstraint(state, cfg, cfg.physics.fixedDt);
afterDistance = norm(state.players(2).pos - state.players(1).pos);
assert(state.rope.currentTension > 0, 'Taut rope produced no tension.');
assert(state.players(1).vel(1) > 0 && state.players(2).vel(1) < 0, ...
    'Taut rope did not pull both players toward each other.');
assert(afterDistance < beforeDistance, ...
    'Taut rope positional correction did not reduce separation.');

% A falling player must land on the top of an axis-aligned platform.
player = state.players(1);
player.pos = [3, 5];
player.vel = [0, -10];
player = resolveCollisions(player, [0, 0, 10, 1], 0.41);
assert(abs(player.pos(2) - 1) < 1e-9 && player.onGround, ...
    'Platform landing resolution failed.');

% Both navigation confirmation zones activate a collision route.
nav = level03IbitNavigation();
navState = createInitialState(nav, cfg, []);
navState.players(1).pos = [8.1, 1];
navState.players(2).pos = [11.8, 1];
for index = 1:ceil(nav.mechanic.confirmDuration / cfg.physics.fixedDt) + 1
    navState = stepLevel(navState, nav, cfg, cfg.physics.fixedDt);
end
assert(navState.levelState.routeActive, ...
    'Dual confirmation did not activate the navigation route.');
assert(size(navState.levelState.colliders, 1) > size(nav.platforms, 1), ...
    'Active route platforms were not added to collision data.');

% The network card must visibly enter from above before becoming a platform.
network = level02NetworkBridge();
networkState = createInitialState(network, cfg, []);
networkState = stepLevel(networkState, network, cfg, 0);
startCardY = networkState.levelState.dynamicObjects.loginCard(2);
networkState = stepLevel(networkState, network, cfg, ...
    network.mechanic.fallDuration);
landedCardY = networkState.levelState.dynamicObjects.loginCard(2);
assert(startCardY > landedCardY + 5, ...
    'Network card did not fall from above into the playable scene.');
assert(isfield(networkState.levelState.dynamicObjects, 'loginCardAngle'), ...
    'Network card visual tilt state is missing.');

% Picking up the bottle slows only the environment clock.
storm = level04DeadlineStorm();
stormState = createInitialState(storm, cfg, []);
stormState.players(1).pos = [storm.mechanic.bottle(1) + 0.4, ...
    storm.mechanic.bottle(2)];
stormState = stepLevel(stormState, storm, cfg, cfg.physics.fixedDt);
assert(stormState.levelState.bottleCollected && ...
    stormState.levelState.slowTimer > 0, ...
    'Breakdown-water pickup did not start slow motion.');

% Ten minutes of fixed physics steps must remain finite and bounded.
longState = createInitialState(level, cfg, []);
longState = stepLevel(longState, level, cfg, 0);
input = neutralInput();
for index = 1:round(600 / cfg.physics.fixedDt)
    direction = mod(floor(index / 240), 2) == 0;
    input.player(1).right = direction;
    input.player(1).left = ~direction;
    input.player(2).right = direction;
    input.player(2).left = ~direction;
    input.player(1).jump = mod(index, 181) == 2;
    input.player(2).jump = mod(index, 197) == 2;
    longState = stepPhysics(longState, input, level, cfg, cfg.physics.fixedDt);
    longState = stepLevel(longState, level, cfg, cfg.physics.fixedDt);
    if longState.requestReset
        longState = resetToCheckpoint(longState, level);
    end
end
values = [longState.players(1).pos, longState.players(1).vel, ...
    longState.players(2).pos, longState.players(2).vel, ...
    longState.rope.currentTension];
assert(all(isfinite(values)), 'Long simulation generated non-finite values.');
assert(longState.rope.currentTension <= cfg.rope.maxTension + eps, ...
    'Rope tension exceeded its safety cap.');
end

function input = neutralInput()
for index = 1:2
    input.player(index).left = false;
    input.player(index).right = false;
    input.player(index).jump = false;
end
input.pause = false;
input.reset = false;
input.quit = false;
input.rawKeys = {};
end
