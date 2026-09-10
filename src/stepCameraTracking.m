function state = stepCameraTracking(state, world, cfg, dt)
%STEPCAMERATRACKING Move a world camera only when players cross its dead zone.

halfView = cfg.render.viewportWidth / 2;
minimumCentre = halfView;
maximumCentre = world.worldWidth - halfView;
halfViewY = cfg.render.viewportHeight / 2;
minimumCentreY = -0.4 + halfViewY;
maximumCentreY = max(minimumCentreY, world.worldHeight - halfViewY);

if ~isfield(state.render, 'cameraCentre') || ...
        ~isfinite(state.render.cameraCentre)
    state.render.cameraCentre = mean([state.players(1).pos(1), ...
        state.players(2).pos(1)]);
end

centre = min(max(state.render.cameraCentre, minimumCentre), maximumCentre);
leftEdge = centre - halfView;
deadZone = cfg.render.cameraHorizontalDeadZone;
leftThreshold = leftEdge + deadZone(1) * cfg.render.viewportWidth;
rightThreshold = leftEdge + deadZone(2) * cfg.render.viewportWidth;
playerX = [state.players(1).pos(1), state.players(2).pos(1)];
target = centre;

if max(playerX) > rightThreshold
    target = target + max(playerX) - rightThreshold;
end
if min(playerX) < leftThreshold
    target = target + min(playerX) - leftThreshold;
end
target = min(max(target, minimumCentre), maximumCentre);

if dt <= 0
    alpha = 1;
else
    alpha = 1 - exp(-dt / cfg.render.cameraHorizontalResponse);
end
state.render.cameraCentre = centre + alpha * (target - centre);
state.render.cameraCentre = min(max(state.render.cameraCentre, ...
    minimumCentre), maximumCentre);

if ~isfield(state.render, 'cameraCentreY') || ...
        ~isfinite(state.render.cameraCentreY)
    playerCentresY = [state.players(1).pos(2) + ...
        state.players(1).size(2) / 2, state.players(2).pos(2) + ...
        state.players(2).size(2) / 2];
    state.render.cameraCentreY = mean(playerCentresY);
end
centreY = min(max(state.render.cameraCentreY, ...
    minimumCentreY), maximumCentreY);
bottomEdge = centreY - halfViewY;
verticalDeadZone = cfg.render.cameraVerticalDeadZone;
lowerThreshold = bottomEdge + ...
    verticalDeadZone(1) * cfg.render.viewportHeight;
upperThreshold = bottomEdge + ...
    verticalDeadZone(2) * cfg.render.viewportHeight;
playerBottoms = [state.players(1).pos(2), state.players(2).pos(2)];
playerTops = [state.players(1).pos(2) + state.players(1).size(2), ...
    state.players(2).pos(2) + state.players(2).size(2)];
targetY = centreY;
if max(playerTops) > upperThreshold
    targetY = targetY + max(playerTops) - upperThreshold;
end
if min(playerBottoms) < lowerThreshold
    targetY = targetY + min(playerBottoms) - lowerThreshold;
end
targetY = min(max(targetY, minimumCentreY), maximumCentreY);
if dt <= 0
    alphaY = 1;
else
    alphaY = 1 - exp(-dt / cfg.render.cameraVerticalResponse);
end
state.render.cameraCentreY = centreY + alphaY * (targetY - centreY);
state.render.cameraCentreY = min(max(state.render.cameraCentreY, ...
    minimumCentreY), maximumCentreY);
end
