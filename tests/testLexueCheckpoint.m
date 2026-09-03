function testLexueCheckpoint()
%TESTLEXUECHECKPOINT Verify My Courses is the Lexue save point.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
state.checkpointIndex = 5;
state.levelState.lexue = initializedLexueState();

state.players(1).pos = [168, 1];
state.players(2).pos = [169, 1];
state = stepLevel(state, world, cfg, 0.1);
assert(state.checkpointIndex == 5, ...
    'Passing Lexue without touching My Courses incorrectly saved progress.');

card = world.mechanic.lexue.courseCardZone;
state.players(1).pos = [card(1) + 1.5, card(2)];
state.players(2).pos = [card(1) + 3.2, card(2)];
state = stepLevel(state, world, cfg, 0.1);
assert(state.levelState.lexue.courseCardReached && ...
    state.checkpointIndex == 6, ...
    'My Courses card did not become the Lexue checkpoint.');

state.players(1).pos = [170, 1];
state.players(2).pos = [171, 1];
state = resetToCheckpoint(state, world);
assert(norm(state.players(1).pos - world.checkpoints(6).spawn(1, :)) < ...
    1e-9, 'Reset did not return to the My Courses checkpoint.');
end

function lexue = initializedLexueState()
lexue.entered = true;
lexue.elapsed = 6;
lexue.lastFlipIndex = 6;
lexue.selectionOpen = true;
lexue.startTimer = 0.6;
lexue.startPressLatched = false;
lexue.homeActive = true;
lexue.feedback = 'success';
lexue.courseCardReached = false;
end
