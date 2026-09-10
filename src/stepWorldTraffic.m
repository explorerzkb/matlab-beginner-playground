function state = stepWorldTraffic(state, world, cfg, dt)
%STEPWORLDTRAFFIC Run the locked North Li Bridge or traffic-light route.

traffic = world.mechanic.traffic;
if ~isfield(state.levelState, 'traffic')
    state.levelState.traffic = initialTrafficState(traffic, state.levelTime);
end
t = state.levelState.traffic;
t = ensureTrafficFields(t, traffic, state.levelTime);
% The physical bridge does not disappear when the pair chooses the road.
% Its underside also prevents a lower-route jump from bypassing the signal.
state.levelState.colliders = [state.levelState.colliders; traffic.upperBridgePlatforms];

jumpNow = [state.players(1).jumpHeld, state.players(2).jumpHeld];
jumpEdge = jumpNow & ~t.climbHeldLast;
t.climbHeldLast = jumpNow;
if strcmp(t.route, 'undecided') || strcmp(t.route, 'upper')
    for playerIndex = 1:2
        deck = traffic.upperBridgePlatforms(1, :);
        inClimbZone = playerOverlaps(state.players(playerIndex), traffic.climbZone);
        if t.climbPresses(playerIndex) == traffic.climbPressesRequired && ...
                inClimbZone && state.players(playerIndex).pos(2) < ...
                deck(2) + deck(4) - 0.1
            % Falling back below the deck starts a fresh ascent.
            t.climbPresses(playerIndex) = 0;
        end
        if jumpEdge(playerIndex) && ...
                inClimbZone && ...
                t.climbPresses(playerIndex) < traffic.climbPressesRequired
            if strcmp(t.route, 'undecided')
                t.route = 'upper';
                state.stats.trafficRoute = '北理桥';
            end
            t.climbPresses(playerIndex) = min( ...
                traffic.climbPressesRequired, ...
                t.climbPresses(playerIndex) + 1);
            climbY = 1.0 + traffic.climbStepHeight * ...
                t.climbPresses(playerIndex);
            state.players(playerIndex).pos(2) = max( ...
                state.players(playerIndex).pos(2), climbY);
            state.players(playerIndex).vel(2) = max( ...
                state.players(playerIndex).vel(2), 3.0);
            if t.climbPresses(playerIndex)==traffic.climbPressesRequired
                % Finish the last rung on the deck, not against its side.
                deck=traffic.upperBridgePlatforms(1,:);
                state.players(playerIndex).pos(1)=max(state.players(playerIndex).pos(1), ...
                    deck(1)+state.players(playerIndex).size(1)/2+0.06);
                state.players(playerIndex).pos(2)=deck(2)+deck(4);
                state.players(playerIndex).vel=[0 0];
                state.players(playerIndex).onGround=true;
            end
        end
    end
end

if strcmp(t.route, 'undecided')
    playerX = [state.players(1).pos(1), state.players(2).pos(1)];
    playerY = [state.players(1).pos(2), state.players(2).pos(2)];
    if all(playerX >= traffic.lowerLockX) && all(playerY < 3.0)
        t.route = 'lower';
        state.stats.trafficRoute = '红绿灯';
    end
end

if strcmp(t.route, 'upper')
    for playerIndex = 1:2
        presses = t.climbPresses(playerIndex);
        if presses > 0 && presses < traffic.climbPressesRequired && ...
                playerOverlaps(state.players(playerIndex), traffic.climbZone)
            % A completed rung remains a foothold while the partner climbs.
            state.players(playerIndex).pos(2) = max( ...
                state.players(playerIndex).pos(2), ...
                1 + traffic.climbStepHeight * presses);
            state.players(playerIndex).vel(2) = max( ...
                state.players(playerIndex).vel(2), 0);
        end
    end
    % Route choice is state, not an invisible obstacle on the road below.
end

t.signalClock = t.signalClock + dt;
[t.signalPhase, t.signalProgress] = signalAtTime( ...
    traffic, t.signalClock);
t.carsMayMove = strcmp(t.signalPhase, 'vehicleGreen') || ...
    strcmp(t.signalPhase, 'yellow');
t.pedestriansMayCross = strcmp(t.signalPhase, 'pedestrianGreen');
if ~t.pedestriansMayCross
    state.levelState.colliders = [state.levelState.colliders; ...
        traffic.pedestrianBarrier];
end
if strcmp(t.route, 'lower') && ~t.pedestriansMayCross && ...
        any(playersInRect(state.players, traffic.waitingZone))
    state.stats.trafficWaitTime = state.stats.trafficWaitTime + dt;
end

cars = t.cars;
previousDepth = t.carDepth;
if t.carsMayMove
    movingTimeLeft = max(0, sum(traffic.signalPhaseDurations(1:2)) - ...
        mod(t.signalClock, sum(traffic.signalPhaseDurations)));
    for carIndex = 1:size(cars, 1)
        row = traffic.carData(carIndex, :);
        direction = t.carDirections(carIndex);
        oldX = t.carDepth(carIndex);
        nextX = oldX + row(5) * direction * dt;
        leftStop = -traffic.depthStop;
        rightStop = traffic.depthStop;
        clearanceTime = (rightStop - leftStop) / row(5);
        % Do not enter unless this phase leaves enough time to clear the
        % entire crossing. Red lights never relocate an existing vehicle.
        if movingTimeLeft < clearanceTime + dt
            if direction > 0 && oldX <= leftStop + 1e-9
                nextX = min(nextX, leftStop);
            elseif direction < 0 && oldX >= rightStop - 1e-9
                nextX = max(nextX, rightStop);
            end
        end
        if nextX > row(8)
            nextX = row(8) - (nextX - row(8));
            t.carDirections(carIndex) = -1;
        elseif nextX < row(7)
            nextX = row(7) + (row(7) - nextX);
            t.carDirections(carIndex) = 1;
        end
        t.carDepth(carIndex) = nextX;
    end
end
cars(:,1)=traffic.carData(:,1);
cars(:,2)=1+traffic.depthProjection*t.carDepth;
t.cars = cars;

if t.carsMayMove
    for carIndex = 1:size(cars, 1)
        nearDepth=min(t.carDepth(carIndex),previousDepth(carIndex));
        farDepth=max(t.carDepth(carIndex),previousDepth(carIndex));
        crossing=nearDepth<=traffic.contactDepth && farDepth>=-traffic.contactDepth;
        % Only the shared ground cross-section can collide. Projected cars
        % higher in the picture are farther away, not on the bridge deck.
        hitbox=[cars(carIndex,1),1,cars(carIndex,3),1.5];
        if crossing && any(playersInRect(state.players,hitbox))
            state = applyDamageEvent(state, cfg, 'fatal');
            break;
        end
    end
end

crowd = traffic.crowdData(:, 1:4);
% Count only green-light walking time. Each green phase takes the crowd
% to the opposite pavement; red phases preserve the reached endpoint.
durations = traffic.signalPhaseDurations;
pedIndex = find(strcmp(traffic.signalPhaseNames, 'pedestrianGreen'), 1);
cycleDuration = sum(durations);
cycleTime = mod(t.signalClock, cycleDuration);
walkingTime = floor(t.signalClock / cycleDuration) * durations(pedIndex) + ...
    min(max(cycleTime - sum(durations(1:pedIndex-1)), 0), durations(pedIndex));
walkPhase = mod(walkingTime / durations(pedIndex), 2);
walkFraction = 1 - abs(1 - walkPhase);
for crowdIndex = 1:size(crowd, 1)
    leftX = traffic.crowdData(crowdIndex, 1);
    rightX = traffic.crosswalk(1) + traffic.crosswalk(3) + ...
        0.8 + (crowdIndex - 1) * 0.9;
    crowd(crowdIndex, 1) = leftX + walkFraction * (rightX - leftX);
end
for crowdIndex = 1:size(crowd, 1)
    touchingPlayers = playersInRect(state.players, crowd(crowdIndex, :));
    for playerIndex = find(touchingPlayers)
        direction = sign(state.players(playerIndex).pos(1) - ...
            (crowd(crowdIndex, 1) + crowd(crowdIndex, 3) / 2));
        if direction == 0
            direction = 1;
        end
        currentSpeed = state.players(playerIndex).vel(1);
        % Limit the crowd's shove without erasing the player's own speed.
        speedLimit = max(abs(currentSpeed), traffic.crowdPushSpeedCap);
        state.players(playerIndex).vel(1) = min(max( ...
            currentSpeed + direction * ...
            traffic.crowdPushAcceleration * dt, ...
            -speedLimit), speedLimit);
    end
end
t.crowd = crowd;
state.levelState.traffic = t;

state.levelState.dynamicObjects.traffic.climbZone = traffic.climbZone;
state.levelState.dynamicObjects.traffic.upperBridgePlatforms = ...
    traffic.upperBridgePlatforms;
state.levelState.dynamicObjects.traffic.lowerRouteZone = ...
    traffic.lowerRouteZone;
state.levelState.dynamicObjects.traffic.crosswalk = traffic.crosswalk;
state.levelState.dynamicObjects.traffic.pedestrianBarrier = ...
    traffic.pedestrianBarrier;
state.levelState.dynamicObjects.traffic.cars = cars;
state.levelState.dynamicObjects.traffic.carDirections = t.carDirections;
state.levelState.dynamicObjects.traffic.crowd = crowd;
end

function state = initialTrafficState(traffic, levelTime)
state.route = 'undecided';
state.climbPresses = [0, 0];
state.climbHeldLast = [false, false];
state.signalClock = levelTime;
state.signalPhase = 'vehicleGreen';
state.signalProgress = 0;
state.carsMayMove = true;
state.pedestriansMayCross = false;
state.cars = traffic.carData(:, 1:4);
state.carDepth = traffic.carData(:,2);
state.cars(:,2)=1+traffic.depthProjection*state.carDepth;
state.carDirections = traffic.carData(:, 6);
state.crowd = traffic.crowdData(:, 1:4);
end

function state = ensureTrafficFields(state, traffic, levelTime)
defaults = initialTrafficState(traffic, levelTime);
names = fieldnames(defaults);
for index = 1:numel(names)
    name = names{index};
    if ~isfield(state, name)
        state.(name) = defaults.(name);
    end
end
end

function [phase, progress] = signalAtTime(traffic, time)
durations = traffic.signalPhaseDurations;
cycleTime = mod(time, sum(durations));
phaseIndex = find(cycleTime < cumsum(durations), 1, 'first');
if isempty(phaseIndex)
    phaseIndex = numel(durations);
end
phaseStart = sum(durations(1:phaseIndex - 1));
phase = traffic.signalPhaseNames{phaseIndex};
progress = (cycleTime - phaseStart) / durations(phaseIndex);
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
