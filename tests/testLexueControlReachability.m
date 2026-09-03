function testLexueControlReachability()
%TESTLEXUECONTROLREACHABILITY Jump through and land on the source button.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
button = world.mechanic.lexue.startButtonPlatform;
state = createInitialState(world, cfg, []);
state.players(1).pos = [button(1) + 0.30 * button(3), 1];
state.players(2).pos = [button(1) + 0.70 * button(3), 1];
state.players(1).onGround = true;
state.players(2).onGround = true;
state = stepLevel(state, world, cfg, 0);
state.levelState.lexue.selectionOpen = true;

input = neutralInput();
input.player(1).jump = true;
input.player(2).jump = true;
maxHeight = 0;
for stepIndex = 1:round(2.4 / cfg.physics.fixedDt)
    state = stepPhysics(state, input, world, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
    positions = vertcat(state.players.pos);
    maxHeight = max(maxHeight, min(positions(:, 2)));
    input.player(1).jump = false;
    input.player(2).jump = false;
end

buttonTop = button(2) + button(4);
positions = vertcat(state.players.pos);
assert(maxHeight > buttonTop, ...
    'The source-position start button was not vertically reachable.');
assert(all(abs(positions(:, 2) - buttonTop) < 0.05) && ...
    all([state.players.onGround]), ...
    'Players did not land on the one-way start-button control.');
assert(state.levelState.lexue.homeActive, ...
    'A reachable joint landing did not complete the start-button hold.');
end

function input = neutralInput()
for playerIndex = 1:2
    input.player(playerIndex).left = false;
    input.player(playerIndex).right = false;
    input.player(playerIndex).jump = false;
end
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end
