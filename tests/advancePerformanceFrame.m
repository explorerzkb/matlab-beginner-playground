function state = advancePerformanceFrame(state, level, cfg, centre, index)
%ADVANCEPERFORMANCEFRAME Keep benchmark visuals moving deterministically.

movingCentre = centre + 0.3 * sin(index / 7);
state.players(1).pos = [movingCentre - 1.2, 3.1 + 0.18 * sin(index / 9)];
state.players(2).pos = [movingCentre + 1.2, 3.1 + 0.18 * cos(index / 10)];
state = stepLevel(state, level, cfg, 1 / cfg.render.targetHz);
if centre == 154
    % Keep the densest bicycle view instead of switching to sparse sky.
    state.levelState.bicycle.phase = 'waiting';
    state.levelState.bicycle.timer = 0;
    state.levelState.bicycle.launched = false;
end
end
