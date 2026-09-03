function testLevelData()
%TESTLEVELDATA Validate the frozen four-level contract and runtime asset.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
cfg = gameConfig(projectRoot);
loaders = {@level01NorthLake, @level02NetworkBridge, ...
    @level03IbitNavigation, @level04DeadlineStorm};
expectedMechanics = {'geese', 'loginCard', 'navigation', 'deadlineStorm'};

for index = 1:numel(loaders)
    level = loaders{index}();
    assert(level.id == index, 'Level IDs must be sequential.');
    assert(strcmp(level.mechanic.type, expectedMechanics{index}), ...
        'Each level must retain its one frozen primary mechanic.');
    assert(size(level.spawn, 1) == 2 && size(level.spawn, 2) == 2, ...
        'Each level requires two spawn positions.');
    assert(size(level.platforms, 2) == 4 && ...
        all(level.platforms(:, 3) > 0) && all(level.platforms(:, 4) > 0), ...
        'Platform rectangles must have positive dimensions.');
    assert(numel(level.checkpoints) >= 1, ...
        'Every level requires at least one checkpoint.');
    assert(all(level.finish(3:4) > 0), 'Finish rectangle must be non-empty.');
    assert(level.finish(1) + level.finish(3) <= level.worldWidth + eps, ...
        'Finish must remain inside the world bounds.');

    state = createInitialState(level, cfg, []);
    state.players(1).pos = level.finish(1:2) + [0.8, 0.05];
    state.players(2).pos = level.finish(1:2) + [1.8, 0.05];
    state = stepLevel(state, level, cfg, 0);
    assert(state.completed, ...
        'A level did not require and accept both players at its exit.');
end

assert(isfile(cfg.assets.loginImage), ...
    'The privacy-checked login image is missing from assets/game.');
imageInfo = imfinfo(cfg.assets.loginImage);
assert(imageInfo.Width == 1293 && imageInfo.Height == 740, ...
    'The runtime login screenshot dimensions changed unexpectedly.');
end
