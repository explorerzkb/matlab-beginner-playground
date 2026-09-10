function state = stepConsumables(state, input, cfg, dt)
%STEPCONSUMABLES Update tea use, movement boost, and shared-heart timers.

state.status.hitCooldown = max(0, state.status.hitCooldown - dt);
state.status.respawnProtection = max(0, state.status.respawnProtection - dt);
state.inventory.buffTimer = max(0, state.inventory.buffTimer - dt);
if state.status.deathPending
    state.status.deathTimer = max(0, state.status.deathTimer - dt);
    if state.status.deathTimer == 0
        state.requestReset = true;
    end
end

if input.useItem
    if ~state.inventory.useLatched
        state.inventory.useHeldTime = state.inventory.useHeldTime + dt;
        if state.inventory.useHeldTime >= cfg.tea.useHoldDuration && ...
                state.inventory.teaCount > 0
            state.inventory.teaCount = state.inventory.teaCount - 1;
            state.inventory.buffTimer = cfg.tea.buffDuration;
            state.inventory.useLatched = true;
            state.inventory.useHeldTime = 0;
            state.stats.teaUsed = state.stats.teaUsed + 1;
        end
    end
else
    state.inventory.useHeldTime = 0;
    state.inventory.useLatched = false;
end
end
