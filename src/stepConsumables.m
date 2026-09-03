function state = stepConsumables(state, input, cfg, dt)
%STEPCONSUMABLES Update shared tea use, boost time, and hit immunity.

state.status.hitCooldown = max(0, state.status.hitCooldown - dt);
state.inventory.buffTimer = max(0, state.inventory.buffTimer - dt);

if input.useItem
    if ~state.inventory.useLatched
        state.inventory.useHeldTime = state.inventory.useHeldTime + dt;
        if state.inventory.useHeldTime >= cfg.tea.useHoldDuration && ...
                state.inventory.teaCount > 0
            state.inventory.teaCount = state.inventory.teaCount - 1;
            state.inventory.buffTimer = cfg.tea.buffDuration;
            state.inventory.useLatched = true;
            state.inventory.useHeldTime = 0;
            state.status.breakValue = max(0, ...
                state.status.breakValue - cfg.tea.breakReduction);
            state.stats.teaUsed = state.stats.teaUsed + 1;
        end
    end
else
    state.inventory.useHeldTime = 0;
    state.inventory.useLatched = false;
end
end
