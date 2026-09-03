function state = applyRopeConstraint(state, cfg, dt)
%APPLYROPECONSTRAINT Apply capped spring-damper tension only when taut.

anchor1 = state.players(1).pos + ...
    [0.46 * state.players(1).size(1), 0.62 * state.players(1).size(2)];
anchor2 = state.players(2).pos + ...
    [-0.46 * state.players(2).size(1), 0.62 * state.players(2).size(2)];
delta = anchor2 - anchor1;
distance = hypot(delta(1), delta(2));
state.rope.currentTension = 0;

if distance <= cfg.rope.length || distance < eps
    state.rope.tautLast = false;
    return;
end

direction = delta / distance;
relativeVelocity = dot(state.players(2).vel - state.players(1).vel, direction);
extension = distance - cfg.rope.length;
tension = cfg.rope.stiffness * extension + ...
    cfg.rope.damping * max(relativeVelocity, 0);
tension = min(max(tension, 0), cfg.rope.maxTension);

impulse = tension * dt;
state.players(1).vel = state.players(1).vel + ...
    direction * impulse / state.players(1).mass;
state.players(2).vel = state.players(2).vel - ...
    direction * impulse / state.players(2).mass;

correction = direction * extension * cfg.rope.positionCorrection * 0.5;
state.players(1).pos = state.players(1).pos + correction;
state.players(2).pos = state.players(2).pos - correction;

state.rope.currentTension = tension;
state.stats.maxTension = max(state.stats.maxTension, tension);
isStrongPull = tension >= cfg.rope.pullCountThreshold;
if isStrongPull && ~state.rope.tautLast
    state.stats.ropePulls = state.stats.ropePulls + 1;
end
state.rope.tautLast = isStrongPull;
end
