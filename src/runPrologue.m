function state = runPrologue(fig, ax, state, world, cfg)
%RUNPROLOGUE Animate in the existing figure without replacing the world.
state = stepPrologue(state, world, cfg, 0);
gameFrameWait();
clock = tic; previous = toc(clock); accumulator = 0;
lastRender = -inf; previousPause = false;
while ~state.prologue.complete && isgraphics(fig)
    if getappdata(fig,'closeRequested')
        state.requestQuit = true;
        return;
    end
    now = toc(clock); delta = min(now-previous,cfg.runtime.maxFrameDelta);
    previous = now;
    input = readInputSnapshot(fig,cfg.input);
    if input.quit
        state.requestQuit = true;
        return;
    end
    if input.pause && ~previousPause, state.paused = ~state.paused; end
    previousPause = input.pause;
    if ~state.paused
        accumulator = accumulator + delta;
        while accumulator >= cfg.physics.fixedDt
            state = stepPrologue(state,world,cfg,cfg.physics.fixedDt);
            accumulator = accumulator-cfg.physics.fixedDt;
        end
    end
    if now-lastRender >= 1/cfg.render.targetHz
        state = renderPrologueFrame(fig,ax,state,world,cfg);
        drawnow;
        lastRender = now;
    end
    gameFrameWait();
end
state.input.previousPause = previousPause;
end
