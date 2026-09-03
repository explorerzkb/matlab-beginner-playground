function testNetworkRecharge()
%TESTNETWORKRECHARGE Verify both page controls act as bounded launch pads.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
network = world.mechanic.network;

for padIndex = 1:size(network.rechargePads, 1)
    state = createInitialState(world, cfg, []);
    pad = network.rechargePads(padIndex, :);
    state.players(1).pos = [pad(1) + pad(3) / 2, pad(2)];
    state.players(1).vel = [20 * (-1) ^ padIndex, -20];
    state = stepWorldNetwork(state, world, cfg, 0.01);
    assert(state.players(1).vel(2) >= ...
        network.rechargeImpulses(padIndex, 2), ...
        'Recharge control did not launch the touching player upward.');
    assert(abs(state.players(1).vel(1)) <= ...
        network.rechargeMaxHorizontal + eps, ...
        'Recharge control exceeded its horizontal velocity cap.');
    firstVelocity = state.players(1).vel;
    state = stepWorldNetwork(state, world, cfg, 0.01);
    assert(all(state.players(1).vel == firstVelocity), ...
        'Recharge control retriggered during its cooldown.');
end
end
