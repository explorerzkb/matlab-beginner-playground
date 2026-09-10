function handles = updateContinuousMechanic(handles, state, world, cfg)
%UPDATECONTINUOUSMECHANIC Render all dynamic parts of the v3 campus world.

cameraCentre = state.render.cameraCentre;
halfView = cfg.render.viewportWidth / 2 + 1.5;
viewRange = [cameraCentre - halfView, cameraCentre + halfView];

campusOnly=state.levelState.bicycle.landed && ...
    min([state.players(1).pos(1),state.players(2).pos(1)])>=170;
if campusOnly
    updateBuses(handles.continuous,state,world,cfg,viewRange);
    return;
end

active = struct( ...
    'race', cameraCentre > 72 && cameraCentre < 126, ...
    'animals', rangesOverlap(viewRange, [12, 64]), ...
    'tea', rangesOverlap(viewRange, [8, 25]), ...
    'network', rangesOverlap(viewRange, [64, 112]), ...
    'traffic', rangesOverlap(viewRange, [112, 150]), ...
    'bicycle', rangesOverlap(viewRange, [147, 173]), ...
    'bus', rangesOverlap(viewRange, [188, 252]));

if isfield(handles, 'continuousActive')
    preload = false;
else
    preload = true;
end
if active.race || preload
    handles = updateRaceRunners(handles, state, world, cfg, preload);
end
if active.animals
    handles = updateAnimals(handles, state, world, cfg, viewRange);
end
if active.tea
    handles = updateTea(handles, state, world, cfg, viewRange);
end
if active.network
    updateNetwork(handles.continuous, state, cfg);
end
if active.traffic
    updateTraffic(handles.continuous, state, world, cfg, viewRange);
end
if active.bicycle
    updateBicycles(handles.continuous, state, world, cfg, viewRange);
end
if active.bus
    updateBuses(handles.continuous, state, world, cfg, viewRange);
end
handles.continuousActive = active;
end

function handles = updateAnimals(handles, state, ~, cfg, viewRange)
animals = state.levelState.animals;
animalsVisible = rangesOverlap(viewRange, [12, 64]);
if animalsVisible && isfield(handles, 'animalRenderTime') && ...
        state.levelTime - handles.animalRenderTime < 1 / 30
    return;
end
if animalsVisible
    drawGeese(handles, animals, state.levelTime, viewRange);
    drawDucks(handles, animals, state.levelTime, viewRange);
    if rangesOverlap(viewRange, [animals.peacockRect(1), ...
            animals.peacockRect(1) + animals.peacockRect(3)])
        drawPeacock(handles.continuous, animals);
        handles.peacockWasVisible = true;
    elseif isfield(handles, 'peacockWasVisible') && handles.peacockWasVisible
        hideMany(handles.continuous.peacockTail, ...
            handles.continuous.peacockEyespots, ...
            handles.continuous.peacockBody, handles.continuous.peacockNeck, ...
            handles.continuous.peacockHead, handles.continuous.peacockBeak, ...
            handles.continuous.peacockCrest, handles.continuous.peacockFeet, ...
            handles.continuous.peacockLabel);
        handles.peacockWasVisible = false;
    end
    handles.animalRenderTime = state.levelTime;
else
    hideMany(handles.geese, handles.gooseNecks, handles.gooseHeads, ...
        handles.gooseBeaks, handles.gooseWings, handles.gooseEyes, ...
        handles.gooseLegs, handles.gooseShadows, handles.ducks, ...
        handles.duckHeads, handles.duckBeaks, handles.duckWings, ...
        handles.duckEyes, handles.duckLegs, handles.duckShadows, ...
        handles.continuous.peacockTail, ...
        handles.continuous.peacockEyespots, ...
        handles.continuous.peacockBody, handles.continuous.peacockNeck, ...
        handles.continuous.peacockHead, handles.continuous.peacockBeak, ...
        handles.continuous.peacockCrest, handles.continuous.peacockFeet, ...
        handles.continuous.peacockLabel);
end

if rangesOverlap(viewRange, [36.5, 43.5])
    alpaca = animals.alpacaRect;
    if ~isgraphics(handles.continuous.alpacaSprite)
        spriteParent = handles.continuous.alpacaLabel.Parent;
        handles.continuous.alpacaSprite = createAlpacaSprite( ...
            spriteParent, cfg.assets.alpacaSprite);
    end
    spriteX = alpaca(1) + [0, alpaca(3); 0, alpaca(3)];
    spriteY = alpaca(2) + [0, 0; alpaca(4), alpaca(4)];
    set(handles.continuous.alpacaSprite, 'XData', spriteX, ...
        'YData', spriteY, 'Visible', 'on');
    set(handles.continuous.alpacaLabel, 'Position', ...
        [alpaca(1) + 0.40 * alpaca(3), ...
        alpaca(2) + alpaca(4) + 0.38, 0], 'Visible', 'on');
    if animals.kickWarning > 0
        kickOrigin = [alpaca(1) + 0.88 * alpaca(3), ...
            alpaca(2) + 0.42 * alpaca(4)];
        set(handles.continuous.alpacaWarning, 'Position', ...
            [kickOrigin(1) + 0.65, kickOrigin(2) + 0.70, 0], ...
            'Visible', 'on');
        lift = 0.10 * sin(20 * animals.kickWarning);
        set(handles.continuous.alpacaKickLines, ...
            'XData', kickOrigin(1) + [0.05, 0.72, nan, 0.15, 0.85], ...
            'YData', kickOrigin(2) + [0.05, 0.32 + lift, nan, ...
            -0.12, 0.03 + lift], 'Visible', 'on');
    else
        hideMany(handles.continuous.alpacaWarning, ...
            handles.continuous.alpacaKickLines);
    end
else
    if isgraphics(handles.continuous.alpacaSprite)
        delete(handles.continuous.alpacaSprite);
        handles.continuous.alpacaSprite = gobjects(1);
    end
    hideMany(handles.continuous.alpacaLabel, ...
        handles.continuous.alpacaWarning, ...
        handles.continuous.alpacaKickLines);
end

% Preserve the state-updated handle after lazy sprite creation/deletion.
end

function drawGeese(handles, animals, levelTime, viewRange)
metadata = get(handles.geese(1), 'UserData');
if isstruct(metadata)
    drawCompoundBirds(handles.geese(1), metadata, animals.geeseRects, ...
        animals.geeseDirections, levelTime, viewRange, 0.025, 8, 0.9);
    return;
end
for index = 1:size(animals.geeseRects, 1)
    rect = animals.geeseRects(index, :);
    if ~rangesOverlap(viewRange, [rect(1), rect(1) + rect(3)])
        set(handles.geese(index), 'Visible', 'off');
        continue;
    end
    direction = animals.geeseDirections(index);
    bob = 0.025 * sin(8 * levelTime + 0.9 * index);
    local = get(handles.geese(index), 'UserData');
    local(:, 1) = 0.5 + direction * (local(:, 1) - 0.5);
    vertices = [rect(1) + rect(3) * local(:, 1), ...
        rect(2) + bob + rect(4) * local(:, 2)];
    set(handles.geese(index), 'Vertices', vertices, 'Visible', 'on');
end
end

function drawDucks(handles, animals, levelTime, viewRange)
metadata = get(handles.ducks(1), 'UserData');
if isstruct(metadata)
    drawCompoundBirds(handles.ducks(1), metadata, animals.duckRects, ...
        animals.duckDirections, levelTime, viewRange, 0.020, 10, 0.7);
    return;
end
for index = 1:size(animals.duckRects, 1)
    rect = animals.duckRects(index, :);
    if ~rangesOverlap(viewRange, [rect(1), rect(1) + rect(3)])
        set(handles.ducks(index), 'Visible', 'off');
        continue;
    end
    direction = animals.duckDirections(index);
    bob = 0.02 * sin(10 * levelTime + 0.7 * index);
    local = get(handles.ducks(index), 'UserData');
    local(:, 1) = 0.5 + direction * (local(:, 1) - 0.5);
    vertices = [rect(1) + rect(3) * local(:, 1), ...
        rect(2) + bob + rect(4) * local(:, 2)];
    set(handles.ducks(index), 'Vertices', vertices, 'Visible', 'on');
end
end

function drawCompoundBirds(object, metadata, rects, directions, ...
        levelTime, viewRange, bobAmount, bobRate, phaseStep)
vertices = nan(metadata.vertexCount * metadata.birdCount, 2);
anyVisible = false;
for index = 1:size(rects, 1)
    rect = rects(index, :);
    if ~rangesOverlap(viewRange, [rect(1), rect(1) + rect(3)])
        continue;
    end
    anyVisible = true;
    local = metadata.localVertices;
    local(:, 1) = 0.5 + directions(index) * (local(:, 1) - 0.5);
    rows = (index - 1) * metadata.vertexCount + (1:metadata.vertexCount);
    bob = bobAmount * sin(bobRate * levelTime + phaseStep * index);
    vertices(rows, :) = [rect(1) + rect(3) * local(:, 1), ...
        rect(2) + bob + rect(4) * local(:, 2)];
end
set(object, 'Vertices', vertices, 'Visible', onOff(anyVisible));
end

function value = onOff(condition)
if condition
    value = 'on';
else
    value = 'off';
end
end

function drawPeacock(handles, animals)
rect = animals.peacockRect;
centreX = rect(1) + 0.48 * rect(3);
baseY = rect(2);
if animals.peacockOpen
    theta = linspace(0.06 * pi, 0.94 * pi, 34);
    tailX = [centreX, centreX + 0.52 * rect(3) * cos(theta), centreX];
    tailY = [baseY + 0.23 * rect(4), baseY + 0.20 * rect(4) + ...
        0.76 * rect(4) * sin(theta), baseY + 0.23 * rect(4)];
    spotTheta = linspace(0.16 * pi, 0.84 * pi, 7);
    spotX = centreX + 0.40 * rect(3) * cos(spotTheta);
    spotY = baseY + 0.22 * rect(4) + ...
        0.59 * rect(4) * sin(spotTheta);
else
    % A trailing folded tail plus a long neck reads as a peacock instead of
    % the previous upright shield silhouette.
    tailX = centreX + rect(3) * ...
        [0.02, -0.18, -0.52, -0.43, -0.08, 0.10];
    tailY = baseY + rect(4) * ...
        [0.14, 0.09, 0.17, 0.31, 0.37, 0.22];
    spotX = nan;
    spotY = nan;
end
set(handles.peacockTail, 'XData', tailX, 'YData', tailY, 'Visible', 'on');
set(handles.peacockEyespots, 'XData', spotX, ...
    'YData', spotY, 'Visible', 'on');
[bodyX, bodyY] = ellipsePoints(centreX, baseY + 0.28 * rect(4), ...
    0.16 * rect(3), 0.24 * rect(4), 24);
set(handles.peacockBody, 'XData', bodyX, 'YData', bodyY, 'Visible', 'on');
head = [centreX + 0.17 * rect(3), baseY + 0.77 * rect(4)];
set(handles.peacockNeck, 'XData', ...
    [centreX + 0.08 * rect(3), head(1)], ...
    'YData', [baseY + 0.40 * rect(4), head(2)], 'Visible', 'on');
set(handles.peacockHead, 'XData', head(1), 'YData', head(2), ...
    'Visible', 'on');
set(handles.peacockBeak, ...
    'XData', head(1) + rect(3) * [0.10, 0.28, 0.11], ...
    'YData', head(2) + rect(4) * [0.04, 0.00, -0.05], ...
    'Visible', 'on');
set(handles.peacockCrest, ...
    'XData', head(1) + rect(3) * [-0.05, -0.12, nan, 0, 0, nan, 0.05, 0.12], ...
    'YData', head(2) + rect(4) * [0.11, 0.24, nan, 0.12, 0.27, nan, ...
    0.10, 0.22], 'Visible', 'on');
set(handles.peacockFeet, ...
    'XData', centreX + rect(3) * [-0.08, -0.08, -0.16, nan, ...
    0.08, 0.08, 0.17], ...
    'YData', baseY + rect(4) * [0.11, 0.00, 0.00, nan, ...
    0.11, 0.00, 0.00], 'Visible', 'on');
set(handles.peacockLabel, 'Position', ...
    [centreX, baseY + rect(4) + 0.25, 0], 'Visible', 'on');
end

function handles = updateTea(handles, state, world, cfg, viewRange)
for index = 1:numel(world.mechanic.tea)
    pickup = world.mechanic.tea(index);
    rect = pickup.rect;
    collected = any(state.inventory.collectedTeaIds == string(pickup.id));
    visible = ~collected && rangesOverlap(viewRange, ...
        [rect(1), rect(1) + rect(3)]);
    if visible
        positionTeaSprite(handles.continuous.tea(index), rect, ...
            cfg.tea.visualWidthMultiplier);
        set(handles.continuous.tea(index), 'Visible', 'on');
    else
        set(handles.continuous.tea(index), 'Visible', 'off');
    end
end
end

function updateNetwork(handles, state, cfg)
data = state.levelState.dynamicObjects.network;
mode = data.pageMode;
animationTick = 0;
if strcmp(mode, 'loading')
    animationTick = floor(30 * state.levelTime);
end
cacheKey = sprintf('%s|%s|%d%d|%d|%d|%d', mode, ...
    state.levelState.network.feedback, ...
    state.levelState.network.fieldOccupancy, ...
    state.levelState.network.credentialsReady, ...
    state.levelState.network.rememberChecked, animationTick);
if isequal(get(handles.networkLoadingText, 'UserData'), cacheKey)
    return;
end
hideMany(handles.networkTimeoutPage, handles.networkSuccessPage, ...
    handles.networkLoadingRing, handles.networkLoadingText, ...
    handles.networkSuccessStatus);

if strcmp(mode, 'timeout')
    hideNetworkLoginControls(handles);
    set(handles.networkTimeoutPage, 'Visible', 'on');
    set(handles.networkLoadingText, 'UserData', cacheKey);
    return;
end
if strcmp(mode, 'success')
    hideNetworkLoginControls(handles);
    set(handles.networkSuccessPage, 'Visible', 'on');
    suppliedIds = filledStudentIds(cfg.network.groupStudentIds);
    if isempty(suppliedIds)
        primaryId = '待填写';
    else
        primaryId = suppliedIds{1};
    end
    successText = {['用户名： ', primaryId], ...
        ['IP地址： ', cfg.network.successIp], ...
        ['已用流量： ', cfg.network.successTraffic], ...
        ['已用时长： ', cfg.network.successDuration], ...
        ['账户余额： ', cfg.network.successBalance]};
    page = data.pageRect;
    set(handles.networkSuccessStatus, 'Position', ...
        [page(1) + 0.655 * page(3), page(2) + 0.555 * page(4), 0], ...
        'String', successText, 'Visible', 'on');
    set(handles.networkLoadingText, 'UserData', cacheKey);
    return;
end

fieldRects = [data.usernameField; data.passwordField];
suppliedIds = filledStudentIds(cfg.network.groupStudentIds);
if state.levelState.network.credentialsReady
    fieldTexts = {strjoin(suppliedIds, ' · '), cfg.network.passwordMask};
else
    fieldTexts = {'小梨经过这里自动填写', ''};
end
for index = 1:2
    occupancy = state.levelState.network.fieldOccupancy(index);
    if state.levelState.network.credentialsReady || occupancy == 1
        color = [0.60, 0.88, 0.67];
    elseif occupancy > 1
        color = [0.96, 0.60, 0.55];
    else
        color = [0.90, 0.94, 0.98];
    end
    rect = fieldRects(index, :);
    set(handles.networkFields(index), 'Position', rect, ...
        'FaceColor', color, 'Visible', 'on');
    set(handles.networkFieldLabels(index), 'Position', ...
        [rect(1) + rect(3) / 2, rect(2) + rect(4) / 2, 0], ...
        'String', fieldTexts{index}, 'Visible', 'on');
end
set(handles.networkFieldLabels(1), 'FontSize', 6.0);
set(handles.networkFieldLabels(2), 'FontSize', 9.5);

checkbox = data.rememberCheckbox;
if state.levelState.network.rememberChecked
    checkboxColor = [0.48, 0.82, 0.55];
    checkboxLabel = '✓ 记住密码';
else
    checkboxColor = [0.94, 0.96, 0.98];
    checkboxLabel = '□ 记住密码';
end
set(handles.networkCheckbox, 'Position', checkbox, ...
    'FaceColor', checkboxColor, 'Visible', 'on');
set(handles.networkCheckboxLabel, 'Position', ...
    [checkbox(1) + checkbox(3) / 2, checkbox(2) + checkbox(4) / 2, 0], ...
    'String', checkboxLabel, 'Visible', 'on');

login = data.loginButton;
switch state.levelState.network.feedback
    case 'needCredentials'
        loginColor = [0.87, 0.31, 0.27];
        loginLabel = '先经过用户名';
    case 'needPartner'
        loginColor = [0.91, 0.68, 0.22];
        loginLabel = '还差一梨';
    case 'loading'
        loginColor = [0.29, 0.67, 0.88];
        loginLabel = '连接中…';
    otherwise
        loginColor = [0.49, 0.70, 0.84];
        loginLabel = '登录';
end
set(handles.networkLogin, 'Position', login, ...
    'FaceColor', loginColor, 'Visible', 'on');
set(handles.networkLoginLabel, 'Position', ...
    [login(1) + login(3) / 2, login(2) + login(4) / 2, 0], ...
    'String', loginLabel, 'Visible', 'on');
set(handles.networkGate, 'Position', data.authGate, 'Visible', 'on');
selfService = data.selfServiceButton;
set(handles.networkSelfService, 'Position', selfService, 'Visible', 'on');
set(handles.networkSelfServiceLabel, 'Position', ...
    [selfService(1) + selfService(3) / 2, ...
    selfService(2) + selfService(4) / 2, 0], 'Visible', 'on');

if strcmp(mode, 'loading')
    theta = linspace(0, 2 * pi, 9);
    theta(end) = [];
    theta = theta + 5.5 * state.levelTime;
    centre = [login(1) + login(3) / 2, login(2) + login(4) + 0.68];
    set(handles.networkLoadingRing, ...
        'XData', centre(1) + 0.32 * cos(theta), ...
        'YData', centre(2) + 0.32 * sin(theta), 'Visible', 'on');
    set(handles.networkLoadingText, 'Position', ...
        [centre(1), centre(2) + 0.58, 0], 'Visible', 'on');
end
set(handles.networkLoadingText, 'UserData', cacheKey);
end

function updateTraffic(handles, state, world, ~, viewRange)
if ~rangesOverlap(viewRange, [112, 150])
    hideMany(handles.climbRungs, handles.climbProgress, ...
        handles.upperBridgePlatforms, handles.signalHousing, ...
        handles.signalLights, handles.signalLabel, handles.routeLabel, ...
        handles.pedestrianBarrier, handles.pedestrianBarrierLabel, ...
        handles.cars, handles.carWindows, handles.carWheels, ...
        handles.crowd, handles.crowdHeads, handles.crowdLegs);
    return;
end
lastRenderTime = get(handles.signalHousing, 'UserData');
if ~isempty(lastRenderTime) && state.levelTime - lastRenderTime < 1 / 30
    return;
end
traffic = state.levelState.traffic;
data = world.mechanic.traffic;

rungX = data.climbZone(1) + 1.6;
for index = 1:numel(handles.climbRungs)
    rungY = 1.5 + index * data.climbStepHeight;
    completed = all(traffic.climbPresses >= index);
    if completed
        color = [0.35, 0.85, 0.50];
    else
        color = [0.87, 0.87, 0.80];
    end
    set(handles.climbRungs(index), 'XData', rungX + [-0.55, 0.55], ...
        'YData', [rungY, rungY], 'Color', color, 'Visible', 'on');
end
set(handles.climbProgress, 'Position', [rungX, 6.45, 0], ...
    'String', sprintf('攀爬 P1 %d/4 · P2 %d/4', ...
    traffic.climbPresses(1), traffic.climbPresses(2)), 'Visible', 'on');

for index = 1:numel(handles.upperBridgePlatforms)
    % The checked bridge sprite now carries the visible physical deck.
    set(handles.upperBridgePlatforms(index), 'Visible', 'off');
end

set(handles.signalHousing, 'Visible', 'on');
lightPositions = [7.0, 5.95, 4.90];
lightColors = repmat([0.27, 0.29, 0.30], 3, 1);
% The visible signal addresses the players as pedestrians, so its colour
% and label must express the same permission as the crossing barrier.
if traffic.pedestriansMayCross
    lightColors(3, :) = [0.22, 0.84, 0.36];
    signalLabel = '行人绿灯';
else
    lightColors(1, :) = [0.86, 0.22, 0.20];
    signalLabel = '行人红灯';
end
signalX = data.crosswalk(1) + 0.43 * data.crosswalk(3);
for index = 1:3
    set(handles.signalLights(index), 'XData', signalX, ...
        'YData', lightPositions(index), ...
        'MarkerFaceColor', lightColors(index, :), 'Visible', 'on');
end
set(handles.signalLabel, 'String', signalLabel, 'Visible', 'on');

barrier = state.levelState.dynamicObjects.traffic.pedestrianBarrier;
if traffic.pedestriansMayCross
    hideMany(handles.pedestrianBarrier, handles.pedestrianBarrierLabel);
else
    set(handles.pedestrianBarrier, 'Position', barrier, 'Visible', 'on');
    set(handles.pedestrianBarrierLabel, 'Position', ...
        [barrier(1) - 0.18, barrier(2) + barrier(4) + 0.18, 0], ...
        'Visible', 'on');
end

switch traffic.route
    case 'upper'
        routeLabel = '路线锁定：北理桥';
        routeColor = [0.10, 0.45, 0.68];
    case 'lower'
        routeLabel = '路线锁定：红绿灯';
        routeColor = [0.60, 0.25, 0.13];
    otherwise
        routeLabel = '↑ 四次攀爬 / → 地面过街';
        routeColor = [0.24, 0.29, 0.31];
end
set(handles.routeLabel, 'String', routeLabel, ...
    'Color', routeColor, 'Visible', 'on');

carCount = size(traffic.cars, 1);
carBodiesX = zeros(4, carCount);
carBodiesY = zeros(4, carCount);
carWindowsX = zeros(4, carCount);
carWindowsY = zeros(4, carCount);
carWheelX = zeros(1, 2 * carCount);
carWheelY = zeros(1, 2 * carCount);
for index = 1:carCount
    rect = traffic.cars(index, :);
    carBodiesX(:, index) = rect(1) + rect(3) * [0; 1; 1; 0];
    carBodiesY(:, index) = rect(2) + rect(4) * [0; 0; 1; 1];
    direction = traffic.carDirections(index);
    windowX = rect(1) + rect(3) * [0.29, 0.72, 0.64, 0.38];
    if direction < 0
        windowX = fliplr(2 * (rect(1) + rect(3) / 2) - windowX);
    end
    carWindowsX(:, index) = windowX(:);
    carWindowsY(:, index) = rect(2) + rect(4) * [0.62; 0.62; 0.88; 0.88];
    wheelColumns = 2 * index - 1:2 * index;
    carWheelX(wheelColumns) = rect(1) + rect(3) * [0.24, 0.77];
    carWheelY(wheelColumns) = rect(2) + rect(4) * [0.05, 0.05];
end
set(handles.cars, 'XData', carBodiesX, 'YData', carBodiesY, 'Visible', 'on');
set(handles.carWindows, 'XData', carWindowsX, ...
    'YData', carWindowsY, 'Visible', 'on');
set(handles.carWheels, 'XData', carWheelX, ...
    'YData', carWheelY, 'Visible', 'on');

crowdCount = size(traffic.crowd, 1);
crowdVertices = zeros(4 * crowdCount, 2);
crowdHeadX = zeros(24, crowdCount);
crowdHeadY = zeros(24, crowdCount);
crowdLegX = cell(crowdCount, 1);
crowdLegY = cell(crowdCount, 1);
for index = 1:crowdCount
    rect = traffic.crowd(index, :);
    body = [rect(1)+0.19*rect(3), rect(2)+0.28*rect(4), ...
        0.62*rect(3), 0.47*rect(4)];
    rows = 4 * index - 3:4 * index;
    crowdVertices(rows, :) = [body(1), body(2); ...
        body(1)+body(3), body(2); body(1)+body(3), body(2)+body(4); ...
        body(1), body(2)+body(4)];
    [headX,headY]=ellipsePoints(rect(1)+0.5*rect(3),rect(2)+0.87*rect(4), ...
        0.22*rect(3),0.13*rect(4),24);
    crowdHeadX(:, index) = headX(:);
    crowdHeadY(:, index) = headY(:);
    crowdLegX{index} = [rect(1)+rect(3)*[0.32 0.38 0.4 nan 0.67 0.62 0.6], nan];
    crowdLegY{index} = [rect(2)+rect(4)*[0 0.12 0.29 nan 0 0.12 0.29], nan];
end
set(handles.crowd, 'Vertices', crowdVertices, 'Visible', 'on');
set(handles.crowdHeads, 'XData', crowdHeadX, ...
    'YData', crowdHeadY, 'Visible', 'on');
set(handles.crowdLegs, 'XData', [crowdLegX{:}], ...
    'YData', [crowdLegY{:}], 'Visible', 'on');
set(handles.signalHousing, 'UserData', state.levelTime);
end

function updateBicycles(handles, state, world, ~, viewRange)
data = world.mechanic.bicycle;
bicycle = state.levelState.bicycle;
visible = rangesOverlap(viewRange, [147, 173]) || ...
    strcmp(bicycle.phase, 'flight');
if ~visible
    if strcmp(get(handles.bicycleFrames,'Visible'),'off')
        return;
    end
    hideMany(handles.bicycleFrames, handles.bicycleWheels, ...
        handles.bicycleRiders, handles.bicycleRiderBodies, handles.bicycleWarning, ...
        handles.bicycleImpact);
    return;
end
lastRenderTime = get(handles.bicycleWarning, 'UserData');
if ~isempty(lastRenderTime) && state.levelTime - lastRenderTime < 1 / 30
    return;
end
bikeCount = size(bicycle.bikeRects, 1);
theta = linspace(0, 2 * pi, 26)';
wheelFacesX = zeros(numel(theta), 2 * bikeCount);
wheelFacesY = zeros(numel(theta), 2 * bikeCount);
headFacesX = zeros(24, bikeCount);
headFacesY = zeros(24, bikeCount);
framePartsX = cell(bikeCount, 1);
framePartsY = cell(bikeCount, 1);
bodyPartsX = cell(bikeCount, 1);
bodyPartsY = cell(bikeCount, 1);
for index = 1:bikeCount
    rect = bicycle.bikeRects(index, :);
    wheelX = rect(1) + rect(3) * [0.20, 0.78];
    wheelY = rect(2) + 0.18 * rect(4) * [1, 1];
    radius = 0.18 * rect(4);
    crank = [rect(1) + 0.48 * rect(3), rect(2) + 0.48 * rect(4)];
    frameX = [wheelX(1), crank(1), wheelX(2), ...
        rect(1) + 0.34 * rect(3), wheelX(1), nan, ...
        crank(1), rect(1) + 0.62 * rect(3)];
    frameY = [wheelY(1), crank(2), wheelY(2), ...
        rect(2) + 0.72 * rect(4), wheelY(1), nan, ...
        crank(2), rect(2) + 0.77 * rect(4)];
    if ~strcmp(bicycle.phase,'waiting')
        frameX=[frameX nan rect(1)-1.1 rect(1)-.15 nan rect(1)-.8 rect(1)-.1]; %#ok<AGROW>
        frameY=[frameY nan rect(2)+.45 rect(2)+.45 nan rect(2)+.75 rect(2)+.75]; %#ok<AGROW>
    end
    [headX,headY]=ellipsePoints(rect(1)+0.50*rect(3), ...
        rect(2)+1.25*rect(4),0.12*rect(4),0.14*rect(4),24);
    bodyX = rect(1) + rect(3) * ...
        [0.49 0.4 0.36 0.50 0.48 nan 0.46 0.61 0.65];
    bodyY = rect(2) + rect(4) * ...
        [1.11 0.91 0.76 0.60 0.4 nan 1.03 0.85 0.78];
    if data.bikeSpeeds(index)<0
        mirror = 2 * (rect(1) + rect(3) / 2);
        wheelX = mirror - wheelX;
        frameX = mirror - frameX;
        headX = mirror - headX;
        bodyX = mirror - bodyX;
    end
    wheelColumns = 2 * index - 1:2 * index;
    wheelFacesX(:, wheelColumns) = wheelX + radius * cos(theta);
    wheelFacesY(:, wheelColumns) = wheelY + radius * sin(theta);
    headFacesX(:, index) = headX(:);
    headFacesY(:, index) = headY(:);
    framePartsX{index} = [frameX, nan];
    framePartsY{index} = [frameY, nan];
    bodyPartsX{index} = [bodyX, nan];
    bodyPartsY{index} = [bodyY, nan];
end
set(handles.bicycleWheels, 'XData', wheelFacesX, 'YData', wheelFacesY, ...
    'Visible', 'on');
set(handles.bicycleFrames, 'XData', [framePartsX{:}], ...
    'YData', [framePartsY{:}], 'Visible', 'on');
set(handles.bicycleRiders, 'XData', headFacesX, 'YData', headFacesY, ...
    'Visible', 'on');
set(handles.bicycleRiderBodies, 'XData', [bodyPartsX{:}], ...
    'YData', [bodyPartsY{:}], 'Visible', 'on');

switch bicycle.phase
    case 'warning'
        label = sprintf('车流涌来！ %.1f', bicycle.timer);
        set(handles.bicycleWarning, 'Position', ...
            [data.triggerZone(1) + data.triggerZone(3) / 2, ...
            8.0, 0], 'String', label, 'Visible', 'on');
        set(handles.bicycleImpact, 'Visible', 'off');
    case 'flight'
        hideMany(handles.bicycleWarning);
        centre = mean([state.players(1).pos; state.players(2).pos], 1);
        rays = [-1.1, -0.25, nan, -1.4, -0.5, nan, -1.0, -0.2];
        set(handles.bicycleImpact, 'XData', centre(1) + rays, ...
            'YData', centre(2) + [0.2, 0.45, nan, 0.65, 0.75, nan, ...
            -0.25, -0.05], 'Visible', 'on');
    otherwise
        hideMany(handles.bicycleWarning, handles.bicycleImpact);
end
set(handles.bicycleWarning, 'UserData', state.levelTime);
end

function updateBuses(handles, state, ~, ~, viewRange)
if ~rangesOverlap(viewRange, [188, 252])
    hideMany(handles.buses, handles.busSprites, handles.busWhiteBands, handles.busWindows, ...
        handles.busWheels, handles.busLabels, handles.busDetails, ...
        handles.busHubs, handles.lampPoles, ...
        handles.lampArms, handles.lampHeads, handles.finishNotice);
    return;
end
bus = state.levelState.bus;
for index = 1:size(bus.rects, 1)
    rect = bus.rects(index, :);
    set(handles.buses(index), 'Position', rect);
    localVertices = handles.busLocalVertices;
    vertices = [rect(1) + rect(3) * localVertices(:, 1), ...
        rect(2) + rect(4) * localVertices(:, 2)];
    set(handles.busSprites(index), 'Vertices', vertices, 'Visible', 'on');
end

set(handles.lampPoles, 'Visible', 'on');
set(handles.lampArms, 'Visible', 'on');
set(handles.lampHeads, 'Visible', 'on');

if bus.completed
    label = '两只梨同乘校车抵达体育馆！';
else
    label = '同乘一辆车进入终点';
end
set(handles.finishNotice, 'String', label, 'Visible', 'on');
end

function hideNetworkLoginControls(handles)
hideMany(handles.networkFields, handles.networkFieldLabels, ...
    handles.networkCheckbox, handles.networkCheckboxLabel, ...
    handles.networkLogin, handles.networkLoginLabel, ...
    handles.networkGate, handles.networkSelfService, ...
    handles.networkSelfServiceLabel);
end

function ids = filledStudentIds(configuredIds)
labels = string(configuredIds);
labels = labels(~startsWith(labels, "待填"));
ids = cellstr(labels);
end

function hideMany(varargin)
for groupIndex = 1:nargin
    objects = varargin{groupIndex};
    objects = objects(isgraphics(objects));
    if ~isempty(objects)
        visibility=get(objects,'Visible');
        shown=strcmp(visibility,'on');
        if any(shown)
            set(objects(shown),'Visible','off');
        end
    end
end
end

function tf = rangesOverlap(first, second)
tf = first(2) >= second(1) && first(1) <= second(2);
end

function [x, y] = ellipsePoints(centreX, centreY, radiusX, radiusY, count)
theta = linspace(0, 2 * pi, count);
x = centreX + radiusX * cos(theta);
y = centreY + radiusY * sin(theta);
end

function sprite = createAlpacaSprite(parent, imagePath)
stride = 4;
[rgb, ~, alpha] = readGameImage(imagePath, stride);
alpha = double(alpha) / 255;
sprite = surface('Parent', parent, 'XData', nan(2), 'YData', nan(2), ...
    'ZData', zeros(2), ...
    'CData', rot90(rgb, 2), 'FaceColor', 'texturemap', ...
    'AlphaData', rot90(alpha, 2), 'FaceAlpha', 'texturemap', ...
    'AlphaDataMapping', 'none', 'EdgeColor', 'none', 'Visible', 'off');
end
