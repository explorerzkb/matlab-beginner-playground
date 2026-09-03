function testLexueStartButton()
%TESTLEXUESTARTBUTTON Verify the course-selection button needs both players.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
lexue = world.mechanic.lexue;
button = lexue.startButtonZone;
gate = lexue.selectionGate;
state = createInitialState(world, cfg, []);
state.players(1).pos = pointIn(button, 0.30);
state.players(2).pos = pointIn(button, 0.70);

state = stepWorldLexue(state, world, cfg, 0.8);
assert(~state.levelState.lexue.homeActive && ...
    strcmp(state.levelState.lexue.feedback, 'countdown'), ...
    'Start button opened before the countdown completed.');
assert(state.stats.selectionAttempts == 1 && ...
    hasRect(state.levelState.colliders, gate), ...
    'Early joint attempt was not counted or did not keep the gate closed.');

state.levelState.lexue.selectionOpen = true;
state.players(2).pos = [lexue.selectionPageRect(1) + 0.5, 1.0];
state = stepWorldLexue(state, world, cfg, 0.8);
assert(~state.levelState.lexue.homeActive, ...
    'A single player incorrectly activated course selection.');

state.players(2).pos = pointIn(button, 0.70);
state = stepWorldLexue(state, world, cfg, 0.3);
assert(~state.levelState.lexue.homeActive, ...
    'Course selection opened before the joint hold completed.');
state = stepWorldLexue(state, world, cfg, 0.3);
assert(state.levelState.lexue.homeActive && ...
    strcmp(state.levelState.lexue.feedback, 'success'), ...
    'Joint start-button hold did not enter the Lexue home page.');
assert(~hasRect(state.levelState.colliders, gate), ...
    'Course-selection success did not remove the page gate.');
end

function point = pointIn(rect, fraction)
point = [rect(1) + rect(3) * fraction, rect(2)];
end

function tf = hasRect(rects, target)
tf = any(all(abs(rects - target) < 1e-9, 2));
end
