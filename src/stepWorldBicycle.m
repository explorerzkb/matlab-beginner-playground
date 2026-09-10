function state = stepWorldBicycle(state, world, cfg, dt)
%STEPWORLDBICYCLE Run the unavoidable up-right bicycle launch.

data = world.mechanic.bicycle;
if ~isfield(state.levelState, 'bicycle')
    state.levelState.bicycle.phase = 'waiting';
    state.levelState.bicycle.timer = 0;
    state.levelState.bicycle.bikeRects = data.bikeRects;
    state.levelState.bicycle.launched = false;
    state.levelState.bicycle.landed = false;
    state.levelState.bicycle.disappeared = false;
end
bicycle = state.levelState.bicycle;

% This is a route crossing, not a low rectangular hitbox: a boosted jump
% must not skip the compulsory event and leave later checkpoints locked.
playerX = [state.players(1).pos(1), state.players(2).pos(1)];
atJunction = playerX >= data.triggerZone(1) & ...
    playerX < data.museumLandingZone(1);
if strcmp(bicycle.phase, 'waiting') && any(atJunction)
    bicycle.phase = 'warning';
    bicycle.timer = data.warningDuration;
end

if strcmp(bicycle.phase, 'warning')
    bicycle.timer = max(0, bicycle.timer - dt);
    % Keep the pair inside the junction until the incoming swarm reaches
    % them; stopping or reversing cannot avoid the scripted collision.
    state.levelState.colliders = [state.levelState.colliders; ...
        data.triggerZone(1) + data.triggerZone(3) - 0.2, 1.0, 0.25, 3.2];
    if bicycle.timer == 0
        for playerIndex = 1:2
            % Solve the arc from the actual launch height (including a jump
            % during the warning). Both targets lie inside the safe plaza.
            rise = max(0, state.players(playerIndex).pos(2) - 1);
            gravity = abs(cfg.physics.gravity);
            targetX = data.museumLandingZone(1) + data.landingInset + 2*(playerIndex-1);
            distance = max(1,targetX-state.players(playerIndex).pos(1));
            slope = tand(data.launchAngleDegrees);
            speedX = sqrt(gravity*distance^2/(2*(rise+distance*slope)));
            speedY = speedX*slope;
            bicycle.flightVelocityX(playerIndex) = speedX;
            state.players(playerIndex).vel = ...
                [bicycle.flightVelocityX(playerIndex), speedY];
            state.players(playerIndex).onGround = false;
            state.players(playerIndex).visualImpactTimer = 0.38;
            state.players(playerIndex).visualImpactKind = 'bicycle';
        end
        bicycle.phase = 'flight';
        bicycle.launchTime = state.levelTime;
        bicycle.launched = true;
        state.stats.bicycleLaunches = state.stats.bicycleLaunches + 1;
    end
elseif strcmp(bicycle.phase, 'flight')
    if min([state.players(1).pos(2),state.players(2).pos(2)])>=data.disappearAltitude
        bicycle.disappeared=true;
    end
    inLanding = playersInRect(state.players, data.museumLandingZone);
    lowEnough = [state.players(1).pos(2), state.players(2).pos(2)] <= 1.15;
    if all(inLanding & lowEnough)
        bicycle.phase = 'landed';
        bicycle.landed = true;
    end
end

% The stream keeps moving through the impact instead of freezing mid-road.
if any(strcmp(bicycle.phase,{'warning','flight'})) && ~bicycle.disappeared
    bicycle.bikeRects(:,1)=bicycle.bikeRects(:,1)+data.bikeSpeeds*dt;
end

state.levelState.bicycle = bicycle;
for playerIndex=1:2
    state.players(playerIndex).storyFlight=strcmp(bicycle.phase,'flight');
end
state.levelState.dynamicObjects.bicycle.phase = bicycle.phase;
state.levelState.dynamicObjects.bicycle.timer = bicycle.timer;
state.levelState.dynamicObjects.bicycle.bikeRects = bicycle.bikeRects;
state.levelState.dynamicObjects.bicycle.triggerZone = data.triggerZone;
end

function occupancy = playersInRect(players, rect)
occupancy = false(1, 2);
for playerIndex = 1:2
    occupancy(playerIndex) = playerOverlaps(players(playerIndex), rect);
end
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
