function player = resolveCollisions(player, colliders, dt)
%RESOLVECOLLISIONS Resolve a player AABB against axis-aligned rectangles.
% Player position is bottom-centre; collider rows are [x y width height].

player.hitWall = false;
player.hitCeiling = false;

if isempty(colliders)
    player.pos = player.pos + player.vel * dt;
    player.onGround = false;
    return;
end

halfWidth = player.size(1) / 2;
height = player.size(2);
player.onGround = false;

% Rope correction can leave a very small overlap. Separate it before using
% velocity direction, otherwise a floor contact could be mistaken for a wall.
for index = 1:size(colliders, 1)
    rect = colliders(index, :);
    if overlaps(player.pos, halfWidth, height, rect)
        player = resolveEmbedded(player, rect, halfWidth, height);
    end
end
oldPos = player.pos;

player.pos(1) = player.pos(1) + player.vel(1) * dt;
for index = 1:size(colliders, 1)
    rect = colliders(index, :);
    if overlaps(player.pos, halfWidth, height, rect)
        impactSpeed = abs(player.vel(1));
        if player.vel(1) > 0
            player.pos(1) = rect(1) - halfWidth;
        elseif player.vel(1) < 0
            player.pos(1) = rect(1) + rect(3) + halfWidth;
        end
        if impactSpeed > 1.2
            player.hitWall = true;
        end
        player.vel(1) = 0;
    end
end

player.pos(2) = player.pos(2) + player.vel(2) * dt;
for index = 1:size(colliders, 1)
    rect = colliders(index, :);
    if overlaps(player.pos, halfWidth, height, rect)
        colliderTop = rect(2) + rect(4);
        oldBottom = oldPos(2);
        oldTop = oldPos(2) + height;
        if player.vel(2) <= 0 && oldBottom >= colliderTop - 0.08
            player.pos(2) = colliderTop;
            player.vel(2) = 0;
            player.onGround = true;
        elseif player.vel(2) > 0 && oldTop <= rect(2) + 0.08
            impactSpeed = player.vel(2);
            player.pos(2) = rect(2) - height;
            player.vel(2) = 0;
            if impactSpeed > 1.2
                player.hitCeiling = true;
            end
        else
            player = resolveEmbedded(player, rect, halfWidth, height);
        end
    end
end

% Preserve grounded state when numerical motion is exactly horizontal.
if ~player.onGround && abs(player.vel(2)) < 1e-8
    for index = 1:size(colliders, 1)
        rect = colliders(index, :);
        horizontallyInside = player.pos(1) + halfWidth > rect(1) + 1e-6 && ...
            player.pos(1) - halfWidth < rect(1) + rect(3) - 1e-6;
        onTop = abs(player.pos(2) - (rect(2) + rect(4))) < 1e-5;
        if horizontallyInside && onTop
            player.onGround = true;
            break;
        end
    end
end
end

function player = resolveEmbedded(player, rect, halfWidth, height)
leftPen = player.pos(1) + halfWidth - rect(1);
rightPen = rect(1) + rect(3) - (player.pos(1) - halfWidth);
bottomPen = player.pos(2) + height - rect(2);
topPen = rect(2) + rect(4) - player.pos(2);
[~, side] = min([leftPen, rightPen, bottomPen, topPen]);
switch side
    case 1
        player.pos(1) = rect(1) - halfWidth;
        player.vel(1) = min(player.vel(1), 0);
    case 2
        player.pos(1) = rect(1) + rect(3) + halfWidth;
        player.vel(1) = max(player.vel(1), 0);
    case 3
        player.pos(2) = rect(2) - height;
        player.vel(2) = min(player.vel(2), 0);
    case 4
        player.pos(2) = rect(2) + rect(4);
        player.vel(2) = max(player.vel(2), 0);
        player.onGround = true;
end
end

function tf = overlaps(pos, halfWidth, height, rect)
tf = pos(1) + halfWidth > rect(1) + 1e-9 && ...
     pos(1) - halfWidth < rect(1) + rect(3) - 1e-9 && ...
     pos(2) + height > rect(2) + 1e-9 && ...
     pos(2) < rect(2) + rect(4) - 1e-9;
end
