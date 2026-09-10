function state = stepWorldBus(state, world, cfg, dt)
%STEPWORLDBUS Move an eastbound stream of rideable campus buses.

data = world.mechanic.bus;
routeTime=state.levelTime;
if isfield(state.levelState,'busTimeOffset')
    routeTime=max(0,routeTime-state.levelState.busTimeOffset);
end
currentRects = busRectsAtTime(data, routeTime);
if ~isfield(state.levelState, 'bus')
    state.levelState.bus.previousRects = currentRects;
    state.levelState.bus.rects = currentRects;
    state.levelState.bus.lampCooldowns = zeros(1, 2);
    state.levelState.bus.completed = false;
    state.levelState.bus.riderIds = zeros(1,2);
end
bus = state.levelState.bus;
bus.lampCooldowns = max(0, bus.lampCooldowns - dt);
if ~isfield(bus,'boardingTimers'), bus.boardingTimers=zeros(1,2); end
if ~isfield(bus,'boardingIds'), bus.boardingIds=zeros(1,2); end
if ~isfield(bus,'boardingAssisted'), bus.boardingAssisted=false(1,2); end
bus.boardingTimers=max(0,bus.boardingTimers-dt);

if ~isfield(bus,'riderIds'), bus.riderIds = zeros(1,2); end
for playerIndex = 1:2
    supported = false(1,size(currentRects,1));
    for busIndex = 1:size(currentRects,1)
        supported(busIndex) = playerStandingOnRect(state.players(playerIndex), ...
            bus.previousRects(busIndex,:));
    end
    carrier = bus.riderIds(playerIndex);
    if carrier==0 || ~supported(carrier)
        carrier = find(supported,1);
    end
    if isempty(carrier)
        bus.riderIds(playerIndex)=0;
    else
        delta = currentRects(carrier,1:2)-bus.previousRects(carrier,1:2);
        if abs(delta(1)) <= max(1,2*data.speed*max(dt,eps))
            state.players(playerIndex).pos = state.players(playerIndex).pos + delta;
        end
        bus.riderIds(playerIndex)=carrier;
    end
end

% Roofs remain one-way platforms. The body deals damage rather than pushing
% a pear into the floor; sweep moving bodies so fast crossings cannot miss.
if dt>0
    for busIndex=1:size(currentRects,1)
        current=currentRects(busIndex,:);
        previous=bus.previousRects(busIndex,:);
        if current(1)<previous(1)
            % Respawning at the west end is not a sweep through the campus.
            previous=current;
            bus.riderIds(bus.riderIds==busIndex)=0;
            bus.boardingTimers(bus.boardingIds==busIndex)=0;
            bus.boardingIds(bus.boardingIds==busIndex)=0;
        end
        swept=[min(current(1),previous(1)),data.y, ...
            current(3)+abs(current(1)-previous(1)),current(4)-0.12];
        for playerIndex=1:2
            player=state.players(playerIndex);
            nearTail=player.pos(1)>=current(1)-player.size(1) && ...
                player.pos(1)<=current(1)+data.boardingTailWidth;
            % Rising from the rear gives a short grace window on THIS bus.
            % Walking into its middle or front remains dangerous.
            armingRear=player.pos(1)>=current(1)-4.5 && ...
                player.pos(1)<=current(1)+data.boardingTailWidth;
            if armingRear && ~player.onGround && player.vel(2)>1
                if bus.boardingTimers(playerIndex)==0 || bus.boardingIds(playerIndex)~=busIndex
                    bus.boardingAssisted(playerIndex)=false;
                end
                bus.boardingTimers(playerIndex)=data.boardingGrace;
                bus.boardingIds(playerIndex)=busIndex;
            end
            grace=bus.boardingTimers(playerIndex)>0 && ...
                bus.boardingIds(playerIndex)==busIndex && nearTail;
            top=current(2)+current(4);
            overRoof=player.pos(1)+player.size(1)/2>current(1)+.02;
            if grace && overRoof && ~player.onGround && player.vel(2)<0 && ...
                    player.pos(2)<top-data.roofForgiveness && ~bus.boardingAssisted(playerIndex)
                % One small rear catch-up hop for an early jump. Keep position
                % continuous; never teleport a low pear onto a taller roof.
                state.players(playerIndex).vel(2)=sqrt(2*abs(cfg.physics.gravity)* ...
                    (top+.35-player.pos(2)));
                bus.boardingAssisted(playerIndex)=true;
                bus.boardingTimers(playerIndex)=data.boardingGrace;
            end
            if grace && overRoof && player.vel(2)<=0 && ...
                    player.pos(2)>=top-data.roofForgiveness && player.pos(2)<=top+.12
                state.players(playerIndex).pos(2)=top;
                state.players(playerIndex).vel(2)=0;
                state.players(playerIndex).onGround=true;
                bus.riderIds(playerIndex)=busIndex;
            end
            if grace, continue; end
            if playerOverlaps(state.players(playerIndex),swept)
                [state,applied]=applyDamageEvent(state,cfg,'bus');
                if applied
                    state.players(playerIndex).visualImpactTimer=0.4;
                    state.players(playerIndex).visualImpactKind='bus';
                end
            end
        end
    end
end
state.levelState.oneWayPlatforms = [state.levelState.oneWayPlatforms; currentRects];
state.levelState.colliders = [state.levelState.colliders; data.lampColliders];
for playerIndex = 1:2
    if bus.lampCooldowns(playerIndex) > 0
        continue;
    end
    for lampIndex = 1:size(data.lampColliders, 1)
        if playerTouchesLamp(state.players(playerIndex), ...
                data.lampColliders(lampIndex, :))
            state.players(playerIndex).vel = data.lampKnockback;
            state.players(playerIndex).visualImpactTimer = 0.32;
            state.players(playerIndex).visualImpactKind = 'lamp';
            bus.lampCooldowns(playerIndex) = data.lampCooldown;
            state.stats.lampHits = state.stats.lampHits + 1;
            break;
        end
    end
end

for busIndex = 1:size(currentRects, 1)
    rect = currentRects(busIndex, :);
    bothOnSameBus = playerStandingOnRect(state.players(1), rect) && ...
        playerStandingOnRect(state.players(2), rect);
    if ~bus.completed && bothOnSameBus && ...
            rect(1) + rect(3) >= data.finishX && ...
            min([state.players(1).pos(1),state.players(2).pos(1)]) >= ...
            data.sportsFinish(1)
        bus.completed = true;
        state.stats.busFinishes = state.stats.busFinishes + 1;
        break;
    end
end

bus.previousRects = currentRects;
bus.rects = currentRects;
state.levelState.bus = bus;
state.levelState.dynamicObjects.bus.rects = currentRects;
state.levelState.dynamicObjects.bus.lamps = data.lampColliders;
state.levelState.dynamicObjects.bus.completed = bus.completed;
end

function rects = busRectsAtTime(data, levelTime)
routeLength = data.loopEnd - data.loopStart;
count = numel(data.phaseOffsets);
rects = zeros(count, 4);
for index = 1:count
    travelled = mod(data.phaseOffsets(index) + ...
        data.speed * levelTime, routeLength);
    x = data.loopStart + travelled;
    rects(index, :) = [x, data.y, data.size];
end
end

function tf = playerTouchesLamp(player, rect)
halfWidth = player.size(1) / 2;
vertical = player.pos(2) + player.size(2) > rect(2) + 0.02 && ...
    player.pos(2) < rect(2) + rect(4) - 0.02;
leftGap = abs(player.pos(1) + halfWidth - rect(1));
rightGap = abs(player.pos(1) - halfWidth - (rect(1) + rect(3)));
tf = vertical && (leftGap <= 0.10 || rightGap <= 0.10 || ...
    playerOverlaps(player, rect));
end

function tf = playerStandingOnRect(player, rect)
halfWidth = player.size(1) / 2;
horizontal = player.pos(1) + halfWidth > rect(1) + 0.02 && ...
    player.pos(1) - halfWidth < rect(1) + rect(3) - 0.02;
tf = horizontal && abs(player.pos(2) - (rect(2) + rect(4))) <= 0.10;
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
