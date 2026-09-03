function state = stepPhysics(state, input, level, cfg, dt)
%STEPPHYSICS Fixed-step two-player movement, collision, and rope dynamics.

colliders = state.levelState.colliders;
oneWayPlatforms = zeros(0, 4);
if isfield(state.levelState, 'oneWayPlatforms')
    oneWayPlatforms = state.levelState.oneWayPlatforms;
end
runMultiplier = 1;
jumpMultiplier = 1;
if state.inventory.buffTimer > 0
    runMultiplier = cfg.tea.runAccelerationMultiplier;
    jumpMultiplier = cfg.tea.jumpMultiplier;
end
for playerIndex = 1:2
    player = state.players(playerIndex);
    player.visualImpactTimer = max(0, player.visualImpactTimer - dt);
    if player.visualImpactTimer == 0
        player.visualImpactKind = 'none';
    end
    actions = input.player(playerIndex);
    moveIntent = double(actions.right) - double(actions.left);
    player.moveIntent = moveIntent;

    if player.onGround
        acceleration = cfg.physics.runAcceleration;
    else
        acceleration = cfg.physics.airAcceleration;
    end

    if moveIntent ~= 0
        player.vel(1) = player.vel(1) + ...
            moveIntent * acceleration * runMultiplier * dt;
    elseif player.onGround
        player.vel(1) = approachZero(player.vel(1), cfg.physics.groundFriction * dt);
    else
        player.vel(1) = player.vel(1) * max(0, 1 - cfg.physics.airDrag * dt);
    end
    player.vel(1) = min(max(player.vel(1), -cfg.physics.maxRunSpeed), ...
        cfg.physics.maxRunSpeed);

    jumpPressed = actions.jump && ~player.jumpHeld;
    if jumpPressed && player.onGround
        player.vel(2) = cfg.physics.jumpSpeed * jumpMultiplier;
        player.onGround = false;
    end
    player.jumpHeld = actions.jump;

    player.vel(2) = max(player.vel(2) + cfg.physics.gravity * dt, ...
        cfg.physics.maxFallSpeed);
    oldPosition = player.pos;
    player = resolveCollisions(player, colliders, dt);
    player = resolveOneWayPlatforms(player, oldPosition, ...
        oneWayPlatforms, cfg.physics.collisionEpsilon);
    if player.hitCeiling
        player.visualImpactTimer = 0.30;
        player.visualImpactKind = 'head';
    elseif player.hitWall
        player.visualImpactTimer = 0.24;
        player.visualImpactKind = 'wall';
    end
    player.pos(1) = min(max(player.pos(1), player.size(1) / 2), ...
        level.worldWidth - player.size(1) / 2);
    state.players(playerIndex) = player;
end

state = applyRopeConstraint(state, cfg, dt);

% The positional rope correction is small, but clamp it to world bounds.
for playerIndex = 1:2
    halfWidth = state.players(playerIndex).size(1) / 2;
    state.players(playerIndex).pos(1) = min(max( ...
        state.players(playerIndex).pos(1), halfWidth), ...
        level.worldWidth - halfWidth);
end
end

function value = approachZero(value, amount)
if value > 0
    value = max(0, value - amount);
elseif value < 0
    value = min(0, value + amount);
end
end
