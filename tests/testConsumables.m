function testConsumables()
%TESTCONSUMABLES Verify hold-to-drink and shared tropical-tea effects.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
state = createInitialState(continuousCampusWorld(), cfg, []);
state.inventory.teaCount = 2;
state.status.breakValue = 5;
input = emptyInput();
input.useItem = true;

steps = ceil(cfg.tea.useHoldDuration / cfg.physics.fixedDt);
for index = 1:steps
    state = stepConsumables(state, input, cfg, cfg.physics.fixedDt);
end
assert(state.inventory.teaCount == 1, ...
    'Drinking did not consume exactly one shared tea.');
assert(state.status.breakValue == 3, ...
    'Tea did not reduce the current break value by two.');
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
