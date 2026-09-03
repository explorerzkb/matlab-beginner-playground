function [state, applied] = applyBreakEvent(state, cfg, severity)
%APPLYBREAKEVENT Raise current break value without rewriting failure history.

applied = false;
switch severity
    case 'minor'
        if state.status.hitCooldown > 0
            return;
        end
        increase = cfg.break.minorIncrease;
        state.status.hitCooldown = cfg.break.hitCooldown;
    case 'major'
        increase = cfg.break.majorIncrease;
        state.status.hitCooldown = cfg.break.hitCooldown;
    otherwise
        error('matlabHi:UnknownBreakSeverity', ...
            '未知破防事件级别：%s', severity);
end

state.status.breakValue = min(cfg.break.maxValue, ...
    state.status.breakValue + increase);
state.stats.maxBreakValue = max(state.stats.maxBreakValue, ...
    state.status.breakValue);
applied = true;

if strcmp(severity, 'major')
    state.requestReset = true;
end
if state.status.breakValue >= cfg.break.maxValue
    state.status.totalBreakdowns = state.status.totalBreakdowns + 1;
    state.status.breakValue = cfg.break.respawnValue;
    state.requestReset = true;
end
end
