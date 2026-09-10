function state = stepPhysics(state, input, level, cfg, dt)
%STEPPHYSICS Fixed-step two-player movement, collision, and rope dynamics.

colliders = state.levelState.colliders;
oneWayPlatforms = zeros(0, 4);
if isfield(state.levelState, 'oneWayPlatforms')
    oneWayPlatforms = state.levelState.oneWayPlatforms;
end
groundAccelerationMultiplier = 1;
airAccelerationMultiplier = 1;
maxRunSpeedMultiplier = 1;
jumpMultiplier = 1;
if state.inventory.buffTimer > 0
    groundAccelerationMultiplier = ...
        cfg.tea.groundAccelerationMultiplier;
    airAccelerationMultiplier = cfg.tea.airAccelerationMultiplier;
    maxRunSpeedMultiplier = cfg.tea.maxRunSpeedMultiplier;
    jumpMultiplier = cfg.tea.jumpMultiplier;
end
for playerIndex = 1:2
    player = state.players(playerIndex);
    player.environmentBoostTime = max(0, player.environmentBoostTime - dt);
    player.visualImpactTimer = max(0, player.visualImpactTimer - dt);
    if player.visualImpactTimer == 0
        player.visualImpactKind = 'none';
    end
    actions = input.player(playerIndex);
    incomingHorizontalSpeed = abs(player.vel(1));
    moveIntent = double(actions.right) - double(actions.left);
    player.moveIntent = moveIntent;

    if player.onGround
        acceleration = cfg.physics.runAcceleration * ...
            groundAccelerationMultiplier;
    else
        acceleration = cfg.physics.airAcceleration * ...
            airAccelerationMultiplier;
    end

    storyFlight = strcmp(level.mechanic.type, 'continuousCampus') && ...
        isfield(state.levelState, 'bicycle') && ...
        strcmp(state.levelState.bicycle.phase, 'flight');
    if storyFlight
        % This short story arc owns horizontal momentum until both pears
        % reach the landing zone; normal air drag must not cancel the throw.
        if isfield(state.levelState.bicycle, 'flightVelocityX')
            player.vel(1) = state.levelState.bicycle.flightVelocityX(playerIndex);
        else
            player.vel(1) = level.mechanic.bicycle.launchImpulse(1);
        end
        if player.onGround && player.pos(1) >= ...
                level.mechanic.bicycle.museumLandingZone(1)
            player.vel(1) = 0;
        end
    elseif moveIntent ~= 0
        player.vel(1) = player.vel(1) + ...
            moveIntent * acceleration * dt;
    elseif player.onGround
        player.vel(1) = approachZero(player.vel(1), cfg.physics.groundFriction * dt);
    else
        player.vel(1) = player.vel(1) * max(0, 1 - cfg.physics.airDrag * dt);
    end
    maxRunSpeed = cfg.physics.maxRunSpeed * maxRunSpeedMultiplier;
    if player.environmentBoostTime > 0
        % A movement speed limit must not erase a kick's external momentum.
        maxRunSpeed = max(maxRunSpeed, incomingHorizontalSpeed);
    end
    if ~storyFlight
        player.vel(1) = min(max(player.vel(1), -maxRunSpeed), maxRunSpeed);
    end

    jumpPressed = actions.jump && ~player.jumpHeld;
    if jumpPressed && player.onGround && ~storyFlight
        player.vel(2) = cfg.physics.jumpSpeed * jumpMultiplier;
        player.onGround = false;
    end
    player.jumpHeld = actions.jump;

    player.vel(2) = max(player.vel(2) + cfg.physics.gravity * dt, ...
        cfg.physics.maxFallSpeed);
    player.preCollisionVelocityX = player.vel(1);
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

beforeRope = vertcat(state.players.pos);
state = applyRopeConstraint(state, cfg, dt);

% Rope shortening is also motion. Resolve it against the same surfaces;
% otherwise a grounded partner can be pulled through the floor in one tick.
for playerIndex = 1:2
    player = state.players(playerIndex);
    physicalVelocity = player.vel;
    requestedPosition = player.pos;
    correction = requestedPosition - beforeRope(playerIndex,:);
    if any(abs(correction) > 1e-12)
        player.pos = beforeRope(playerIndex,:);
        player.vel = correction;
        player = resolveCollisions(player, colliders, 1);
        player = resolveOneWayPlatforms(player, beforeRope(playerIndex,:), ...
            oneWayPlatforms, cfg.physics.collisionEpsilon);
        blocked = requestedPosition - player.pos;
        for axisIndex = 1:2
            if blocked(axisIndex)*physicalVelocity(axisIndex) > 0
                physicalVelocity(axisIndex) = 0;
            end
        end
        player.vel = physicalVelocity;
        state.players(playerIndex) = player;
    end
end

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
