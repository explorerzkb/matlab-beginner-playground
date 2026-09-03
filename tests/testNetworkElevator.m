function testNetworkElevator()
%TESTNETWORKELEVATOR Verify self-service stays on its source-page pixels.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
selfService = world.mechanic.network.selfServiceButton;
state.players(1).pos = [selfService(1) + selfService(3) / 2, ...
    selfService(2) + selfService(4)];
state.players(2).pos = [66, 1];
originalPlayerY = state.players(1).pos(2);
state.levelTime = 99;

state = stepWorldNetwork(state, world, cfg, 0);
renderedButton = state.levelState.dynamicObjects.network.selfServiceButton;
assert(all(abs(renderedButton - selfService) < 1e-12), ...
    'Self-service moved away from its original page position.');
assert(abs(state.players(1).pos(2) - originalPlayerY) < 1e-12, ...
    'The fixed self-service control incorrectly carried its rider.');
assert(abs(state.players(2).pos(2) - 1) < 1e-9, ...
    'A distant player was incorrectly moved by the page control.');
assert(any(all(abs(state.levelState.colliders - selfService) < 1e-9, 2)), ...
    'The fixed self-service control was not added to collision geometry.');
end
