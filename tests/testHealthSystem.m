function testHealthSystem()
%TESTHEALTHSYSTEM Verify shared hearts, invulnerability, and delayed recovery.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);

[state, applied] = applyDamageEvent(state, cfg, 'minor');
assert(applied && state.status.currentHearts == 2, ...
    'A minor hit did not remove exactly one shared heart.');
[state, applied] = applyDamageEvent(state, cfg, 'minor');
assert(~applied && state.status.currentHearts == 2, ...
    'Hit invulnerability did not prevent repeated heart loss.');

input = emptyInput();
state = stepConsumables(state, input, cfg, ...
    cfg.health.hitInvulnerability);
[state, applied] = applyDamageEvent(state, cfg, 'minor');
assert(applied && state.status.currentHearts == 1 && ...
    ~state.status.deathPending, ...
    'The second separated hit did not leave one heart.');

state = stepConsumables(state, input, cfg, ...
    cfg.health.hitInvulnerability);
[state, applied] = applyDamageEvent(state, cfg, 'minor');
assert(applied && state.status.currentHearts == 0 && ...
    state.status.deathPending && ~state.requestReset, ...
    'The third hit did not start the delayed knockout state.');

state = stepConsumables(state, input, cfg, ...
    cfg.health.deathDelay * 0.5);
assert(~state.requestReset, ...
    'Knockout reset before the feedback delay elapsed.');
state = stepConsumables(state, input, cfg, ...
    cfg.health.deathDelay * 0.5);
assert(state.requestReset, ...
    'Knockout did not request reset after the feedback delay.');

failuresBefore = state.stats.failures;
state = resetToCheckpoint(state, world);
assert(state.status.currentHearts == cfg.health.maxHearts && ...
    ~state.status.deathPending && state.stats.failures == failuresBefore + 1, ...
    'Checkpoint recovery did not restore all three hearts once.');

state.status.currentHearts = 2;
state.status.hitCooldown = cfg.health.hitInvulnerability;
[state, applied] = applyDamageEvent(state, cfg, 'fatal');
assert(applied && state.status.currentHearts == 0 && ...
    state.status.deathPending, ...
    'A fatal event did not clear hearts through invulnerability.');
assert(state.stats.damageTaken == 5 && state.stats.knockouts == 2, ...
    'Heart-loss statistics did not record actual damage and knockouts.');
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
