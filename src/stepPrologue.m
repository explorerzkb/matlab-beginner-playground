function state = stepPrologue(state, world, cfg, dt)
%STEPPROLOGUE Keep the two curves and falling pears in the actual world.
if ~isfield(state, 'prologue')
    state.prologue.elapsed = 0;
    state.prologue.complete = false;
    state.prologue.soundPlayed = false;
    sampleX=linspace(1.4,10.3,36)';
    basis=[ones(size(sampleX)),sin(0.65*sampleX),cos(0.65*sampleX)];
    for p = 1:2
        sampleY=4.5+0.8*(p-1)+sin(0.65*sampleX+0.45*p)+ ...
            0.035*cos(3.1*sampleX+0.4*p);
        coefficients=basis\sampleY;
        residual=sampleY-basis*coefficients;
        state.prologue.fitCoefficients(:,p)=coefficients;
        state.prologue.fitR2(p)=1-sum(residual.^2)/sum((sampleY-mean(sampleY)).^2);
        state.prologue.fitRmse(p)=sqrt(mean(residual.^2));
        state.players(p).pos = [5+2*(p-1), 5];
        state.players(p).vel = [0 0];
        state.players(p).onGround = false;
    end
end
state.prologue.elapsed = state.prologue.elapsed + dt;
if state.prologue.elapsed >= 2 && ~state.prologue.soundPlayed
    playSoundCue('pop', cfg);
    state.prologue.soundPlayed = true;
end
if state.prologue.elapsed >= 2.7
    input.useItem = false;
    for p = 1:2
        targetX = 10.5 + 1.5*(p-1);
        steering = 4*(targetX-state.players(p).pos(1)) - state.players(p).vel(1);
        input.player(p).left = state.players(p).onGround && steering < -0.2;
        input.player(p).right = state.players(p).onGround && steering > 0.2;
        input.player(p).jump = false;
    end
    state = stepPhysics(state, input, world, cfg, dt);
    state = stepLevel(state, world, cfg, dt);
end
state.prologue.complete = state.prologue.elapsed >= cfg.runtime.prologueDuration;
end
