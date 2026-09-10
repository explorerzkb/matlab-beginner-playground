function player = resolveOneWayPlatforms(player, oldPosition, ...
        platforms, epsilon)
%RESOLVEONEWAYPLATFORMS Let players rise through controls and land on top.

if isempty(platforms)
    return;
end

halfWidth = player.size(1) / 2;
for index = 1:size(platforms, 1)
    rect = platforms(index, :);
    platformTop = rect(2) + rect(4);
    horizontal = player.pos(1) + halfWidth > rect(1) + epsilon && ...
        player.pos(1) - halfWidth < rect(1) + rect(3) - epsilon;
    descendingAcrossTop = player.vel(2) <= 0 && ...
        oldPosition(2) >= platformTop - 0.08 && ...
        player.pos(2) <= platformTop + epsilon;
    alreadyStanding = abs(player.pos(2) - platformTop) <= epsilon && ...
        player.vel(2) <= 0;
    if horizontal && (descendingAcrossTop || alreadyStanding)
        player.pos(2) = platformTop;
        player.vel(2) = 0;
        player.onGround = true;
    end
end
end
