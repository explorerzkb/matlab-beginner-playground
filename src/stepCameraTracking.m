function state = stepCameraTracking(state, world, cfg, dt)
%STEPCAMERATRACKING Move a world camera only when players cross its dead zone.

targetScale=1;
if isfield(state.levelState,'bicycle')
    b=state.levelState.bicycle;
    if b.landed || (b.launched && ...
            min([state.players(1).pos(2),state.players(2).pos(2)])>cfg.render.campusZoomAltitude)
        state.render.campusZoomStarted=true;
    end
end
if isfield(state.render,'campusZoomStarted') && state.render.campusZoomStarted
    targetScale=cfg.render.campusCameraScale;
end
if ~isfield(state.render,'cameraScale'), state.render.cameraScale=1; end
if dt<=0
    state.render.cameraScale=targetScale;
else
    state.render.cameraScale=state.render.cameraScale+ ...
        (1-exp(-dt/cfg.render.campusZoomResponse))*(targetScale-state.render.cameraScale);
end
[viewWidth,viewHeight]=cameraViewport(state,cfg);
halfView = viewWidth / 2;
minimumCentre = halfView;
maximumCentre = world.worldWidth - halfView;
halfViewY = viewHeight / 2;
minimumCentreY = -0.4 + halfViewY;
maximumCentreY = max(minimumCentreY, ...
    max(world.worldHeight,cfg.render.flightCameraCeiling) - halfViewY);

if ~isfield(state.render, 'cameraCentre') || ...
        ~isfinite(state.render.cameraCentre)
    state.render.cameraCentre = mean([state.players(1).pos(1), ...
        state.players(2).pos(1)]);
end

centre = min(max(state.render.cameraCentre, minimumCentre), maximumCentre);
leftEdge = centre - halfView;
deadZone = cfg.render.cameraHorizontalDeadZone;
leftThreshold = leftEdge + deadZone(1) * viewWidth;
rightThreshold = leftEdge + deadZone(2) * viewWidth;
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
    verticalDeadZone(1) * viewHeight;
upperThreshold = bottomEdge + ...
    verticalDeadZone(2) * viewHeight;
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
responseY = cfg.render.cameraVerticalResponse;
if isfield(state.levelState,'bicycle') && ...
        strcmp(state.levelState.bicycle.phase,'flight')
    targetY = mean((playerBottoms+playerTops)/2);
    responseY = cfg.render.flightCameraResponse;
end
targetY = min(max(targetY, minimumCentreY), maximumCentreY);
if dt <= 0
    alphaY = 1;
else
    alphaY = 1 - exp(-dt / responseY);
end
state.render.cameraCentreY = centreY + alphaY * (targetY - centreY);
state.render.cameraCentreY = min(max(state.render.cameraCentreY, ...
    minimumCentreY), maximumCentreY);
end
