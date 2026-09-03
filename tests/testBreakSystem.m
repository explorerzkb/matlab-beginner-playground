function testBreakSystem()
%TESTBREAKSYSTEM Verify current break value, cooldown, and full breakdown.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);

[state, applied] = applyBreakEvent(state, cfg, 'minor');
assert(applied && state.status.breakValue == 1, ...
    'Minor event did not add one break point.');
[state, applied] = applyBreakEvent(state, cfg, 'minor');
assert(~applied && state.status.breakValue == 1, ...
    'Hit cooldown did not prevent repeated break damage.');

input = emptyInput();
state = stepConsumables(state, input, cfg, cfg.break.hitCooldown);
[state, applied] = applyBreakEvent(state, cfg, 'major');
assert(applied && state.status.breakValue == 3 && state.requestReset, ...
    'Major event did not add two points and request recovery.');

state.requestReset = false;
state.status.breakValue = 5;
state.status.hitCooldown = 0;
[state, applied] = applyBreakEvent(state, cfg, 'minor');
assert(applied && state.status.totalBreakdowns == 1, ...
    'Maximum break value did not trigger a full breakdown.');
assert(state.status.breakValue == cfg.break.respawnValue && ...
    state.requestReset, 'Full breakdown did not restore the configured value.');
assert(state.stats.maxBreakValue == cfg.break.maxValue, ...
    'Peak break statistic did not preserve the reached maximum.');

failuresBefore = state.stats.failures;
state = resetToCheckpoint(state, world);
assert(state.stats.failures == failuresBefore + 1, ...
    'Recovery did not preserve a separate cumulative failure count.');
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
