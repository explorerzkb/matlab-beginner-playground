function testConsumables()
%TESTCONSUMABLES Verify hold-to-drink and shared tropical-tea effects.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
state = createInitialState(continuousCampusWorld(), cfg, []);
state.inventory.teaCount = 2;
state.status.currentHearts = 1;
input = emptyInput();
input.useItem = true;

steps = ceil(cfg.tea.useHoldDuration / cfg.physics.fixedDt);
for index = 1:steps
    state = stepConsumables(state, input, cfg, cfg.physics.fixedDt);
end
assert(state.inventory.teaCount == 1, ...
    'Drinking did not consume exactly one shared tea.');
assert(state.status.currentHearts == 1, ...
    'Tea incorrectly changed the shared-heart count.');
assert(state.inventory.buffTimer > 0 && state.stats.teaUsed == 1, ...
    'Tea did not start the boost or update use statistics.');

for index = 1:(2 * steps)
    state = stepConsumables(state, input, cfg, cfg.physics.fixedDt);
end
assert(state.inventory.teaCount == 1, ...
    'Holding the key consumed more than one tea without release.');

input.useItem = false;
state = stepConsumables(state, input, cfg, cfg.physics.fixedDt);
assert(~state.inventory.useLatched, ...
    'Releasing the use key did not clear its latch.');

normalState = createInitialState(continuousCampusWorld(), cfg, []);
boostedState = normalState;
boostedState.inventory.buffTimer = 1;
moveInput = emptyInput();
moveInput.player(1).right = true;
normalState = stepPhysics(normalState, moveInput, ...
    continuousCampusWorld(), cfg, cfg.physics.fixedDt);
boostedState = stepPhysics(boostedState, moveInput, ...
    continuousCampusWorld(), cfg, cfg.physics.fixedDt);
assert(boostedState.players(1).vel(1) > normalState.players(1).vel(1), ...
    'Active tea boost did not increase run acceleration.');

normalState = createInitialState(continuousCampusWorld(), cfg, []);
boostedState = normalState;
boostedState.inventory.buffTimer = 1;
normalState.players(1).onGround = false;
boostedState.players(1).onGround = false;
normalState = stepPhysics(normalState, moveInput, ...
    continuousCampusWorld(), cfg, cfg.physics.fixedDt);
boostedState = stepPhysics(boostedState, moveInput, ...
    continuousCampusWorld(), cfg, cfg.physics.fixedDt);
assert(boostedState.players(1).vel(1) > normalState.players(1).vel(1), ...
    'Active tea boost did not increase air control.');
end

function input = emptyInput()
input.player(1) = struct('left', false, 'right', false, 'jump', false);
input.player(2) = input.player(1);
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end
