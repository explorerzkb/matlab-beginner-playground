function testFlightRecovery()
%TESTFLIGHTRECOVERY Exercise the story flight through the real fixed-step loop.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'config'), fullfile(root, 'src'), fullfile(root, 'levels'));
cfg = gameConfig(root);
world = continuousCampusWorld();
for launchHeights = [1 1; 7 7; 12 12; 1 7; 7 1; 12 1; 1 12]'
for intent = [-1, 0, 1]
    state = createInitialState(world, cfg, []);
    state.players(1).pos = [154, launchHeights(1)];
    state.players(2).pos = [156, launchHeights(2)];
    state.levelState.network.authenticated = true;
    state.levelState.network.pageMode = 'success';
    state.checkpointIndex = 5;
    state = stepLevel(state, world, cfg, 0);
    input.useItem = false;
    for p = 1:2
        input.player(p).left = false;
        input.player(p).right = false;
        input.player(p).jump = false;
    end
    for tick = 1:600
        if strcmp(state.levelState.bicycle.phase, 'flight')
            for p = 1:2
                input.player(p).left = intent < 0;
                input.player(p).right = intent > 0;
            end
        end
        state = stepConsumables(state, input, cfg, cfg.physics.fixedDt);
        state = stepPhysics(state, input, world, cfg, cfg.physics.fixedDt);
        state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
        assert(~state.requestReset && state.stats.damageTaken == 0, ...
            'Story flight killed the pair (intent %d, x %.2f / %.2f).', ...
            intent, state.players(1).pos(1), state.players(2).pos(1));
        if state.levelState.bicycle.landed
            break;
        end
    end
    assert(state.levelState.bicycle.landed, ...
        'Story flight never landed (intent %d, x %.2f / %.2f).', ...
        intent, state.players(1).pos(1), state.players(2).pos(1));
end
end
fprintf('FLIGHT RECOVERY PASSED: 7 height pairs x neutral/left/right inputs\n');
end
