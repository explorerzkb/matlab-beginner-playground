function [state, applied] = applyDamageEvent(state, cfg, severity)
%APPLYDAMAGEEVENT Update the three shared hearts from one damage event.

applied = false;
if state.status.deathPending
    return;
end

switch severity
    case 'minor'
        if state.status.hitCooldown > 0
            return;
        end
        damage = cfg.health.minorDamage;
    case 'fatal'
        damage = state.status.currentHearts;
    case 'bus'
        damage = cfg.health.busDamage;
    otherwise
        error('matlabHi:UnknownDamageSeverity', ...
            '未知伤害事件级别：%s', severity);
end

previousHearts = state.status.currentHearts;
state.status.currentHearts = max(0, previousHearts - damage);
lostHearts = previousHearts - state.status.currentHearts;
if lostHearts <= 0
    return;
end

state.status.hitCooldown = cfg.health.hitInvulnerability;
state.stats.damageTaken = state.stats.damageTaken + lostHearts;
applied = true;

if state.status.currentHearts == 0
    state.status.deathPending = true;
    state.status.deathTimer = cfg.health.deathDelay;
    if isfield(state.levelState,'network') && ...
            strcmp(state.levelState.network.pageMode,'timeout')
        state.status.deathTimer = cfg.network.failureDeathDelay;
    end
    state.stats.knockouts = state.stats.knockouts + 1;
end
end
