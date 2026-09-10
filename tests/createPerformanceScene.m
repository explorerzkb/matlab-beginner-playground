function state = createPerformanceScene(level, cfg, centre)
%CREATEPERFORMANCESCENE Place both players in a stable benchmark pocket.

state = createInitialState(level, cfg, []);
state = stepLevel(state, level, cfg, 0);
if centre >= 220
    state.levelState.network.authenticated = true;
    state.levelState.network.pageMode = 'success';
    state.levelState.network.failureSeen = true;
    state.levelState.bicycle.phase = 'landed';
    state.levelState.bicycle.landed = true;
    state.levelState.traffic.route = 'upper';
    state.levelState.traffic.climbPresses = [4, 4];
end
state.players(1).pos = [centre - 1.2, 3.1];
state.players(2).pos = [centre + 1.2, 3.1];
state.render.cameraCentre = centre;
state.render.cameraCentreY = -0.4 + cfg.render.viewportHeight / 2;
state = stepLevel(state, level, cfg, 0);
end
