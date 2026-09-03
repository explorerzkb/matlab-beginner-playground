function testLexueCountdown()
%TESTLEXUECOUNTDOWN Verify warning, bounded flip, and selection opening.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
lexue = world.mechanic.lexue;
state = createInitialState(world, cfg, []);
lexueStart = world.regions(5).xRange(1);
state.players(1).pos = [lexueStart + 1, 1];
state.players(2).pos = [lexueStart + 2, 1];

state = stepWorldLexue(state, world, cfg, 0.82);
assert(state.levelState.lexue.flipWarning, ...
    'Countdown did not warn before its next page flip.');
platform = lexue.countdownPlatforms(1, :);
state.players(1).pos = [platform(1) + 1.2, platform(2) + platform(4)];
state.players(1).vel = [0, 0];
state = stepWorldLexue(state, world, cfg, 0.18);
assert(state.levelState.lexue.flipNow && ...
    abs(state.players(1).vel(2) - lexue.flipImpulse) < 1e-9, ...
    'Countdown flip did not apply its bounded upward impulse.');

state = stepWorldLexue(state, world, cfg, lexue.countdownDuration);
assert(state.levelState.lexue.selectionOpen && ...
    state.levelState.lexue.remaining == 0, ...
    'Countdown completion did not open course selection.');
assert(size(state.levelState.colliders, 1) >= ...
    size(world.platforms, 1) + size(lexue.countdownPlatforms, 1), ...
    'Countdown digits were not added as physical platforms.');
end
