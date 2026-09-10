function state = carryPlayersWithPlatform(state, previousRect, currentRect)
%CARRYPLAYERSWITHPLATFORM Move riders by a kinematic platform displacement.

delta = currentRect(1:2) - previousRect(1:2);
if all(abs(delta) < 1e-12)
    return;
end
previousTop = previousRect(2) + previousRect(4);
for playerIndex = 1:2
    player = state.players(playerIndex);
    halfWidth = player.size(1) / 2;
    horizontallyOnPlatform = ...
        player.pos(1) + halfWidth > previousRect(1) + 1e-6 && ...
        player.pos(1) - halfWidth < ...
            previousRect(1) + previousRect(3) - 1e-6;
    standingOnPlatform = abs(player.pos(2) - previousTop) <= 0.08;
    if horizontallyOnPlatform && standingOnPlatform
        player.pos = player.pos + delta;
        state.players(playerIndex) = player;
    end
end
end
