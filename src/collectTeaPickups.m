function state = collectTeaPickups(state, world)
%COLLECTTEAPICKUPS Add unique tropical teas to the shared inventory.

pickups = world.mechanic.tea;
for index = 1:numel(pickups)
    id = string(pickups(index).id);
    alreadyCollected = any(state.inventory.collectedTeaIds == id);
    if alreadyCollected || state.inventory.teaCount >= state.inventory.teaMax
        continue;
    end
    touched = playerOverlaps(state.players(1), pickups(index).rect) || ...
        playerOverlaps(state.players(2), pickups(index).rect);
    if touched
        state.inventory.collectedTeaIds(end + 1, 1) = id;
        state.inventory.teaCount = state.inventory.teaCount + 1;
        state.stats.teaCollected = state.stats.teaCollected + 1;
    end
end
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
