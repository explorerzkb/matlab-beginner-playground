function testCameraTracking()
%TESTCAMERATRACKING Verify dead-zone following without page locks.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);

page = world.mechanic.network.pageRect;
initialCentre = page(1) + page(3) / 2;
state.render.cameraCentre = initialCentre;
leftEdge = initialCentre - cfg.render.viewportWidth / 2;
rightThreshold = leftEdge + cfg.render.cameraHorizontalDeadZone(2) * ...
    cfg.render.viewportWidth;
state.players(1).pos(1) = rightThreshold - 0.4;
state.players(2).pos(1) = rightThreshold - 0.1;
state = stepCameraTracking(state, world, cfg, cfg.physics.fixedDt);
assert(abs(state.render.cameraCentre - initialCentre) < 1e-9, ...
    'The camera moved while both pears were inside the horizontal dead zone.');

state.players(2).pos(1) = rightThreshold + 1.0;
state = stepCameraTracking(state, world, cfg, cfg.physics.fixedDt);
assert(state.render.cameraCentre > initialCentre, ...
    'Crossing the right-third threshold did not start camera following.');

state.levelState.activeRegionId = 'network';
state.levelState.network.pageMode = 'success';
state.players(1).pos(1) = page(1) + page(3) + 5.0;
state.players(2).pos(1) = state.players(1).pos(1) + 1.2;
for index = 1:120
    state = stepCameraTracking(state, world, cfg, cfg.physics.fixedDt);
end
assert(state.render.cameraCentre > page(1) + page(3) / 2 + 3.0, ...
    'The successful campus-network page still locks the world camera.');

state.render.cameraCentreY = -0.4 + cfg.render.viewportHeight / 2;
initialY = state.render.cameraCentreY;
state.players(1).pos(2) = 12.0;
state.players(2).pos(2) = 11.1;
for index = 1:90
    state = stepCameraTracking(state, world, cfg, cfg.physics.fixedDt);
end
assert(state.render.cameraCentreY > initialY + 2.0, ...
    'The camera did not follow the bicycle flight upward.');
upperBound = state.render.cameraCentreY + cfg.render.viewportHeight / 2;
assert(max([state.players(1).pos(2) + state.players(1).size(2), ...
    state.players(2).pos(2) + state.players(2).size(2)]) <= ...
    upperBound + 1e-6, 'The upward camera lost a flying pear.');

state.players(1).pos(2) = 1.0;
state.players(2).pos(2) = 1.0;
for index = 1:120
    state = stepCameraTracking(state, world, cfg, cfg.physics.fixedDt);
end
assert(abs(state.render.cameraCentreY - ...
    (-0.4 + cfg.render.viewportHeight / 2)) < 0.05, ...
    'The camera did not settle back to the ground view after landing.');
end
