function handles = updateContinuousMechanic(handles, state, world, cfg)
%UPDATECONTINUOUSMECHANIC Update animals and shared iced-tea pickups.

animals = state.levelState.animals;
cameraCentre = state.render.cameraCentre;
halfView = cfg.render.viewportWidth / 2 + 1.5;
animalRegionVisible = cameraCentre + halfView >= 12 && ...
    cameraCentre - halfView <= 64;
animalDetailVisible = cameraCentre + halfView >= 37 && ...
    cameraCentre - halfView <= 43;
trafficDetailVisible = cameraCentre + halfView >= 96 && ...
    cameraCentre - halfView <= 148;
networkRegionVisible = cameraCentre + halfView >= 64 && ...
    cameraCentre - halfView <= 96;
lexueRegionVisible = cameraCentre + halfView >= 148 && ...
    cameraCentre - halfView <= 194;

if animalRegionVisible
for index = 1:size(animals.geeseRects, 1)
    rect = animals.geeseRects(index, :);
    direction = animals.geeseDirections(index);
    bob = 0.025 * sin(8 * state.levelTime + 0.9 * index);
    centreX = rect(1) + 0.50 * rect(3);
    baseY = rect(2) + bob;
    bodyLocalX = [-0.50, -0.42, -0.20, 0.12, 0.43, 0.50, ...
        0.30, 0.02, -0.27, -0.46];
    bodyLocalY = [0.34, 0.60, 0.72, 0.70, 0.55, 0.34, ...
        0.15, 0.10, 0.13, 0.23];
    set(handles.geese(index), ...
        'XData', centreX + direction * rect(3) * bodyLocalX, ...
        'YData', baseY + rect(4) * bodyLocalY, 'Visible', 'on');
    frontX = centreX + direction * 0.32 * rect(3);
    neckX = frontX + direction * rect(3) * ...
        [-0.06, 0.08, 0.17, 0.24, 0.38, 0.31, 0.17, 0.04];
    neckY = baseY + rect(4) * ...
        [0.48, 0.54, 0.78, 1.13, 1.20, 0.78, 0.51, 0.43];
    set(handles.gooseNecks(index), 'XData', neckX, ...
        'YData', neckY, 'Visible', 'on');
    headCentreX = centreX + direction * 0.69 * rect(3);
    headCentreY = baseY + 1.22 * rect(4);
    [headX, headY] = ellipsePoints(headCentreX, headCentreY, ...
        0.17 * rect(3), 0.20 * rect(4), 22);
    set(handles.gooseHeads(index), 'XData', headX, ...
        'YData', headY, 'Visible', 'on');
    beakX = headCentreX + direction * rect(3) * [0.12, 0.35, 0.13];
    beakY = headCentreY + rect(4) * [0.07, 0.00, -0.08];
    set(handles.gooseBeaks(index), 'XData', beakX, ...
        'YData', beakY, 'Visible', 'on');
    wingX = centreX + direction * rect(3) * ...
        [-0.27, -0.03, 0.28, 0.12, -0.16];
    wingY = baseY + rect(4) * [0.47, 0.62, 0.49, 0.25, 0.24];
    set(handles.gooseWings(index), 'XData', wingX, ...
        'YData', wingY, 'Visible', 'on');
    set(handles.gooseEyes(index), ...
        'XData', headCentreX + direction * 0.08 * rect(3), ...
        'YData', headCentreY + 0.05 * rect(4), 'Visible', 'on');
    footDirection = direction * rect(3);
    legX = centreX + footDirection * ...
        [-0.15, -0.15, -0.26, nan, 0.12, 0.12, 0.01];
    legY = baseY + rect(4) * ...
        [0.15, 0.00, 0.00, nan, 0.15, 0.00, 0.00];
    set(handles.gooseLegs(index), 'XData', legX, ...
        'YData', legY, 'Visible', 'on');
    [shadowX, shadowY] = ellipsePoints(centreX, rect(2) + 0.015, ...
        0.45 * rect(3), 0.045, 18);
    set(handles.gooseShadows(index), 'XData', shadowX, ...
        'YData', shadowY, 'Visible', 'on');
end

for index = 1:size(animals.duckRects, 1)
    rect = animals.duckRects(index, :);
    direction = animals.duckDirections(index);
    bob = 0.02 * sin(10 * state.levelTime + 0.7 * index);
    centreX = rect(1) + 0.48 * rect(3);
    baseY = rect(2) + bob;
    bodyLocalX = [-0.51, -0.37, -0.10, 0.25, 0.48, 0.40, ...
        0.12, -0.22, -0.43];
    bodyLocalY = [0.43, 0.67, 0.75, 0.67, 0.45, 0.20, ...
        0.11, 0.14, 0.25];
    set(handles.ducks(index), ...
        'XData', centreX + direction * rect(3) * bodyLocalX, ...
        'YData', baseY + rect(4) * bodyLocalY, 'Visible', 'on');
    headCentreX = centreX + direction * 0.37 * rect(3);
    headCentreY = baseY + 0.82 * rect(4);
    [headX, headY] = ellipsePoints(headCentreX, headCentreY, ...
        0.24 * rect(3), 0.34 * rect(4), 22);
    set(handles.duckHeads(index), 'XData', headX, ...
        'YData', headY, 'Visible', 'on');
    beakX = headCentreX + direction * rect(3) * [0.17, 0.45, 0.18];
    beakY = headCentreY + rect(4) * [0.08, 0.00, -0.09];
    set(handles.duckBeaks(index), 'XData', beakX, ...
        'YData', beakY, 'Visible', 'on');
    wingX = centreX + direction * rect(3) * ...
        [-0.28, -0.02, 0.28, 0.12, -0.18];
    wingY = baseY + rect(4) * [0.47, 0.68, 0.52, 0.24, 0.25];
    set(handles.duckWings(index), 'XData', wingX, ...
        'YData', wingY, 'Visible', 'on');
    set(handles.duckEyes(index), ...
        'XData', headCentreX + direction * 0.09 * rect(3), ...
        'YData', headCentreY + 0.09 * rect(4), 'Visible', 'on');
    footDirection = direction * rect(3);
    legX = centreX + footDirection * ...
        [-0.12, -0.12, -0.23, nan, 0.13, 0.13, 0.02];
    legY = baseY + rect(4) * ...
        [0.16, 0.00, 0.00, nan, 0.16, 0.00, 0.00];
    set(handles.duckLegs(index), 'XData', legX, ...
        'YData', legY, 'Visible', 'on');
    [shadowX, shadowY] = ellipsePoints(centreX, rect(2) + 0.012, ...
        0.43 * rect(3), 0.04, 18);
    set(handles.duckShadows(index), 'XData', shadowX, ...
        'YData', shadowY, 'Visible', 'on');
end
else
    % Off-camera animals stay hidden without repeating dozens of graphics
    % property writes on every frame in the later, already-heavy regions.
    if ~isempty(handles.geese) && ...
            strcmp(get(handles.geese(1), 'Visible'), 'on')
        hideMany(handles.geese, handles.gooseNecks, handles.gooseHeads, ...
            handles.gooseBeaks, handles.gooseWings, handles.gooseEyes, ...
            handles.gooseLegs, handles.gooseShadows, handles.ducks, ...
            handles.duckHeads, handles.duckBeaks, handles.duckWings, ...
            handles.duckEyes, handles.duckLegs, handles.duckShadows);
    end
end

if animalDetailVisible
alpaca = animals.alpacaRect;
if ~isgraphics(handles.continuous.alpacaSprite)
    spriteAxes = ancestor(handles.continuous.alpacaLabel, 'axes');
    handles.continuous.alpacaSprite = createAlpacaSprite( ...
        spriteAxes, cfg.assets.alpacaSprite);
end
spriteX = alpaca(1) + [0, alpaca(3); 0, alpaca(3)];
spriteY = alpaca(2) + [0, 0; alpaca(4), alpaca(4)];
set(handles.continuous.alpacaSprite, 'XData', spriteX, ...
    'YData', spriteY, 'Visible', 'on');
set(handles.continuous.alpacaLabel, 'Position', ...
    [alpaca(1) + 0.40 * alpaca(3), alpaca(2) + alpaca(4) + 0.38, 0], ...
    'Visible', 'on');
if animals.sneezeWarning > 0
    sneezeOrigin = world.mechanic.animals.alpacaSneezeOrigin;
    set(handles.continuous.alpacaWarning, ...
        'Position', [sneezeOrigin(1) + 1.0, sneezeOrigin(2) + 0.85, 0], ...
        'Visible', 'on');
    puffPhase = 0.08 + 0.12 * sin(5 * animals.sneezeWarning);
    set(handles.continuous.alpacaSneezePuffs, ...
        'XData', sneezeOrigin(1) + [0.24, 0.52, 0.84], ...
        'YData', sneezeOrigin(2) + ...
            [0.02, 0.16, -0.03] + puffPhase, ...
        'MarkerSize', 7 + 8 * animals.sneezeWarning, 'Visible', 'on');
else
    set(handles.continuous.alpacaWarning, 'Visible', 'off');
    set(handles.continuous.alpacaSneezePuffs, 'Visible', 'off');
end
else
    if isgraphics(handles.continuous.alpacaSprite)
        delete(handles.continuous.alpacaSprite);
        handles.continuous.alpacaSprite = gobjects(1);
    end
    hideMany(handles.continuous.alpacaLabel, ...
        handles.continuous.alpacaWarning, ...
        handles.continuous.alpacaSneezePuffs);
end

for index = 1:numel(world.mechanic.tea)
    pickup = world.mechanic.tea(index);
    collected = any(state.inventory.collectedTeaIds == string(pickup.id));
    rect = pickup.rect;
    pickupVisible = rect(1) + rect(3) >= cameraCentre - halfView && ...
        rect(1) <= cameraCentre + halfView;
    if collected || ~pickupVisible
        set(handles.continuous.tea(index), 'Visible', 'off');
        set(handles.continuous.teaLabel(index), 'Visible', 'off');
    else
        set(handles.continuous.tea(index), 'Position', rect, 'Visible', 'on');
        set(handles.continuous.teaLabel(index), 'Position', ...
            [rect(1) + rect(3) / 2, rect(2) + rect(4) + 0.18, 0], ...
            'Visible', 'on');
    end
end

if networkRegionVisible
networkData = state.levelState.dynamicObjects.network;
fieldRects = [networkData.usernameField; networkData.passwordField];
if state.levelState.network.credentialsReady
    fieldTexts = {strjoin(cfg.network.groupStudentIds, ' · '), ...
        cfg.network.passwordMask};
else
    fieldTexts = {'小梨经过这里自动填写', ''};
end
for index = 1:2
    occupancy = state.levelState.network.fieldOccupancy(index);
    if state.levelState.network.credentialsReady
        color = [0.60, 0.88, 0.67];
    elseif occupancy == 1
        color = [0.60, 0.88, 0.67];
    elseif occupancy > 1
        color = [0.96, 0.60, 0.55];
    else
        color = [0.90, 0.94, 0.98];
    end
    rect = fieldRects(index, :);
    set(handles.continuous.networkFields(index), 'Position', rect, ...
        'FaceColor', color, 'Visible', 'on');
    set(handles.continuous.networkFieldLabels(index), 'Position', ...
        [rect(1) + rect(3) / 2, rect(2) + rect(4) / 2, 0], ...
        'String', fieldTexts{index}, 'Visible', 'on');
end
set(handles.continuous.networkFieldLabels(1), 'FontSize', 6.0);
set(handles.continuous.networkFieldLabels(2), 'FontSize', 9.5);

checkbox = networkData.rememberCheckbox;
if state.levelState.network.rememberChecked
    checkboxColor = [0.48, 0.82, 0.55];
    checkboxLabel = '✓ 记住密码';
else
    checkboxColor = [0.94, 0.96, 0.98];
    checkboxLabel = '□ 记住密码';
end
set(handles.continuous.networkCheckbox, 'Position', checkbox, ...
    'FaceColor', checkboxColor, 'Visible', 'on');
set(handles.continuous.networkCheckboxLabel, 'Position', ...
    [checkbox(1) + checkbox(3) / 2, checkbox(2) + checkbox(4) / 2, 0], ...
    'String', checkboxLabel, 'Visible', 'on');

login = networkData.loginButton;
switch state.levelState.network.feedback
    case 'needCredentials'
        loginColor = [0.87, 0.31, 0.27];
        loginLabel = '先蹭用户名';
    case 'ready'
        loginColor = [0.49, 0.70, 0.84];
        loginLabel = '双梨登录';
    case 'needPartner'
        loginColor = [0.91, 0.68, 0.22];
        loginLabel = '还差一梨';
    case 'lagWarning'
        loginColor = [0.95, 0.72, 0.18];
        loginLabel = '网络卡顿…';
    case 'lagOutage'
        loginColor = [0.67, 0.76, 0.82];
        loginLabel = '';
    case 'success'
        loginColor = [0.35, 0.75, 0.45];
        loginLabel = '已登录';
    otherwise
        loginColor = [0.67, 0.76, 0.82];
        loginLabel = '登录';
end
set(handles.continuous.networkLogin, 'Position', login, ...
    'FaceColor', loginColor, 'Visible', 'on');
set(handles.continuous.networkLoginLabel, 'Position', ...
    [login(1) + login(3) / 2, login(2) + login(4) / 2, 0], ...
    'String', loginLabel, 'Visible', 'on');

if state.levelState.network.authenticated
    set(handles.continuous.networkGate, 'Visible', 'off');
else
    set(handles.continuous.networkGate, 'Position', networkData.authGate, ...
        'Visible', 'on');
end
selfService = networkData.selfServiceButton;
if strcmp(state.levelState.network.lagPhase, 'outage')
    hideMany(handles.continuous.networkLogin, ...
        handles.continuous.networkLoginLabel, ...
        handles.continuous.networkSelfService, ...
        handles.continuous.networkSelfServiceLabel);
    outageRects = [login; selfService];
    for index = 1:2
        set(handles.continuous.networkOutageMasks(index), ...
            'Position', outageRects(index, :), 'Visible', 'on');
    end
    lagText = '校园网卡了！登录和自助服务掉线';
elseif strcmp(state.levelState.network.lagPhase, 'warning')
    hideMany(handles.continuous.networkOutageMasks);
    set(handles.continuous.networkSelfService, 'Position', selfService, ...
        'FaceColor', [0.95, 0.72, 0.18], 'Visible', 'on');
    set(handles.continuous.networkSelfServiceLabel, 'Position', ...
        [selfService(1) + selfService(3) / 2, ...
        selfService(2) + selfService(4) / 2, 0], ...
        'String', '网络卡顿…', 'Visible', 'on');
    lagText = '校园网卡了……按钮要掉线！';
else
    hideMany(handles.continuous.networkOutageMasks);
    set(handles.continuous.networkSelfService, 'Position', selfService, ...
        'FaceColor', [0.20, 0.66, 0.83], 'Visible', 'on');
    set(handles.continuous.networkSelfServiceLabel, 'Position', ...
        [selfService(1) + selfService(3) / 2, ...
        selfService(2) + selfService(4) / 2, 0], ...
        'String', '自助服务', 'Visible', 'on');
    lagText = '';
end
if isempty(lagText)
    set(handles.continuous.networkLagNotice, 'Visible', 'off');
else
    warningX = mean([login(1) + login(3) / 2, ...
        selfService(1) + selfService(3) / 2]);
    warningY = fieldRects(1, 2) + fieldRects(1, 4) + 0.52;
    set(handles.continuous.networkLagNotice, ...
        'Position', [warningX, warningY, 0], ...
        'String', lagText, 'Visible', 'on');
end
hideMany(handles.continuous.rechargePads, ...
    handles.continuous.rechargeLabels);
else
    hideMany(handles.continuous.networkFields, ...
        handles.continuous.networkFieldLabels, ...
        handles.continuous.networkCheckbox, ...
        handles.continuous.networkCheckboxLabel, ...
        handles.continuous.networkLogin, ...
        handles.continuous.networkLoginLabel, ...
        handles.continuous.networkGate, ...
        handles.continuous.networkSelfService, ...
        handles.continuous.networkSelfServiceLabel, ...
        handles.continuous.networkLagNotice, ...
        handles.continuous.networkOutageMasks, ...
        handles.continuous.rechargePads, ...
        handles.continuous.rechargeLabels);
end

if trafficDetailVisible
traffic = state.levelState.traffic;
fountain = state.levelState.dynamicObjects.traffic.fountain;
base = [fountain(1), fountain(2), fountain(3), 0.45];
set(handles.continuous.fountainBase, 'Position', base, 'Visible', 'on');
jetX = fountain(1) + fountain(3) / 2;
if traffic.jetActive
    jetTop = fountain(2) + fountain(4);
    jetColor = [0.66, 0.94, 1.0];
else
    jetTop = fountain(2) + 1.0;
    jetColor = [0.35, 0.68, 0.80];
end
set(handles.continuous.fountainJet, 'XData', [jetX, jetX], ...
    'YData', [fountain(2) + 0.2, jetTop], 'Color', jetColor, ...
    'Visible', 'on');
set(handles.continuous.fountainLabel, 'Position', ...
    [jetX, fountain(2) + fountain(4) + 0.28, 0], 'Visible', 'on');

set(handles.continuous.signalHousing, 'Visible', 'on');
lightPositions = [7.15, 6.08, 5.02];
lightColors = repmat([0.27, 0.29, 0.30], 3, 1);
switch traffic.signalPhase
    case 'vehicleGreen'
        lightColors(3, :) = [0.22, 0.84, 0.36];
        signalLabel = '车行绿灯';
    case 'yellow'
        lightColors(2, :) = [0.96, 0.76, 0.16];
        signalLabel = '黄灯';
    case 'pedestrianGreen'
        lightColors(1, :) = [0.86, 0.22, 0.20];
        signalLabel = '行人绿灯';
    otherwise
        lightColors(1, :) = [0.86, 0.22, 0.20];
        signalLabel = '全红';
end
signalX = world.mechanic.traffic.crosswalk(1) + ...
    0.43 * world.mechanic.traffic.crosswalk(3);
for index = 1:3
    set(handles.continuous.signalLights(index), ...
        'XData', signalX, 'YData', lightPositions(index), ...
        'MarkerFaceColor', lightColors(index, :), 'Visible', 'on');
end
set(handles.continuous.signalLabel, 'String', signalLabel, 'Visible', 'on');

barrier = state.levelState.dynamicObjects.traffic.pedestrianBarrier;
if traffic.pedestriansMayCross
    set(handles.continuous.pedestrianBarrier, 'Visible', 'off');
    set(handles.continuous.pedestrianBarrierLabel, 'Visible', 'off');
else
    set(handles.continuous.pedestrianBarrier, 'Position', barrier, ...
        'Visible', 'on');
    set(handles.continuous.pedestrianBarrierLabel, 'Position', ...
        [barrier(1) - 0.18, barrier(2) + barrier(4) + 0.18, 0], ...
        'Visible', 'on');
end

switch traffic.route
    case 'upper'
        routeLabel = '路线：北理桥';
        routeColor = [0.16, 0.48, 0.69];
    case 'lower'
        routeLabel = '路线：红绿灯';
        routeColor = [0.56, 0.28, 0.16];
    otherwise
        routeLabel = '两人共同选择上桥或过街';
        routeColor = [0.28, 0.32, 0.35];
end
set(handles.continuous.routeLabel, 'String', routeLabel, ...
    'Color', routeColor, 'Visible', 'on');

for index = 1:size(traffic.cars, 1)
    rect = traffic.cars(index, :);
    set(handles.continuous.cars(index), 'Position', rect, ...
        'Visible', 'on');
    if trafficDetailVisible
        direction = world.mechanic.traffic.carData(index, 6);
        if direction > 0
            windowX = rect(1) + rect(3) * [0.35, 0.73, 0.66, 0.43];
        else
            windowX = rect(1) + rect(3) * [0.27, 0.65, 0.57, 0.34];
        end
        windowY = rect(2) + rect(4) * [0.62, 0.62, 0.88, 0.88];
        set(handles.continuous.carWindows(index), ...
            'XData', windowX, 'YData', windowY, 'Visible', 'on');
        set(handles.continuous.carWheels(index), ...
            'XData', rect(1) + rect(3) * [0.24, 0.77], ...
            'YData', rect(2) + rect(4) * [0.05, 0.05], 'Visible', 'on');
    else
        set(handles.continuous.carWindows(index), 'Visible', 'off');
        set(handles.continuous.carWheels(index), 'Visible', 'off');
    end
end
for index = 1:size(traffic.crowd, 1)
    rect = traffic.crowd(index, :);
    colors = [0.56, 0.48, 0.76; 0.30, 0.61, 0.67; 0.83, 0.51, 0.38];
    set(handles.continuous.crowd(index), 'Position', rect, ...
        'FaceColor', colors(mod(index - 1, 3) + 1, :), 'Visible', 'on');
    if trafficDetailVisible
        set(handles.continuous.crowdHeads(index), ...
            'XData', rect(1) + rect(3) / 2, ...
            'YData', rect(2) + 0.88 * rect(4), 'Visible', 'on');
    else
        set(handles.continuous.crowdHeads(index), 'Visible', 'off');
    end
end
else
    hideMany(handles.continuous.fountainBase, ...
        handles.continuous.fountainJet, handles.continuous.fountainLabel, ...
        handles.continuous.signalHousing, handles.continuous.signalLights, ...
        handles.continuous.signalLabel, handles.continuous.routeLabel, ...
        handles.continuous.pedestrianBarrier, ...
        handles.continuous.pedestrianBarrierLabel, ...
        handles.continuous.cars, handles.continuous.carWindows, ...
        handles.continuous.carWheels, handles.continuous.crowd, ...
        handles.continuous.crowdHeads);
end

if lexueRegionVisible
lexue = state.levelState.lexue;
lexueObjects = state.levelState.dynamicObjects.lexue;
remainingDigits = sprintf('%06d', min(999999, lexue.remaining));
if lexue.selectionOpen
    countdownColor = [0.35, 0.74, 0.47];
elseif lexue.flipWarning
    countdownColor = [0.91, 0.57, 0.18];
else
    countdownColor = [0.48, 0.66, 0.90];
end
for index = 1:numel(handles.continuous.countdownPlatforms)
    rect = lexueObjects.countdownPlatforms(index, :);
    set(handles.continuous.countdownPlatforms(index), 'Position', rect, ...
        'FaceColor', countdownColor, 'Visible', 'on');
    set(handles.continuous.countdownLabels(index), 'Position', ...
        [rect(1) + rect(3) / 2, rect(2) + rect(4) / 2, 0], ...
        'String', remainingDigits(index), 'Visible', 'on');
end

button = lexueObjects.startButton;
switch lexue.feedback
    case 'countdown'
        startColor = [0.50, 0.58, 0.67];
        startLabel = sprintf('等待倒计时 %ds', lexue.remaining);
    case 'holding'
        startColor = [0.91, 0.62, 0.18];
        progress = lexue.startTimer / world.mechanic.lexue.startHoldDuration;
        startLabel = sprintf('开始选课 %.0f%%', 100 * progress);
    case 'success'
        startColor = [0.30, 0.72, 0.44];
        startLabel = '已进入乐学';
    otherwise
        startColor = [0.20, 0.50, 0.84];
        startLabel = '两人共同开始选课';
end
set(handles.continuous.lexueStartButton, 'Position', button, ...
    'FaceColor', startColor, 'Visible', 'on');
set(handles.continuous.lexueStartLabel, 'Position', ...
    [button(1) + button(3) / 2, button(2) + button(4) / 2, 0], ...
    'String', startLabel, 'Visible', 'on');

if lexue.homeActive
    set(handles.continuous.lexueGate, 'Visible', 'off');
else
    set(handles.continuous.lexueGate, 'Position', ...
        lexueObjects.selectionGate, 'Visible', 'on');
end
courseCard = lexueObjects.courseCard;
if lexue.courseCardReached
    courseColor = [0.55, 0.86, 0.63];
else
    courseColor = [0.84, 0.91, 0.99];
end
set(handles.continuous.courseCard, 'Position', courseCard, ...
    'FaceColor', courseColor, 'Visible', 'on');
set(handles.continuous.courseCardLabel, 'Position', ...
    [courseCard(1) + 0.18, ...
    courseCard(2) + courseCard(4) / 2, 0], 'Visible', 'on');

taskCards = lexueObjects.taskCards;
for index = 1:numel(handles.taskCards)
    if index <= size(taskCards, 1)
        rect = taskCards(index, :);
        set(handles.taskCards(index), 'Position', rect, 'Visible', 'on');
        set(handles.taskTexts(index), 'Position', ...
            [rect(1) + rect(3) / 2, rect(2) + rect(4) / 2, 0], ...
            'Visible', 'on');
    else
        set(handles.taskCards(index), 'Visible', 'off');
        set(handles.taskTexts(index), 'Visible', 'off');
    end
end
else
    hideMany(handles.continuous.countdownPlatforms, ...
        handles.continuous.countdownLabels, ...
        handles.continuous.lexueStartButton, ...
        handles.continuous.lexueStartLabel, ...
        handles.continuous.lexueGate, handles.continuous.courseCard, ...
        handles.continuous.courseCardLabel, handles.taskCards, ...
        handles.taskTexts);
end
end

function hideMany(varargin)
for groupIndex = 1:nargin
    objects = varargin{groupIndex};
    if ~isempty(objects)
        set(objects, 'Visible', 'off');
    end
end
end

function [x, y] = ellipsePoints(centreX, centreY, radiusX, radiusY, count)
theta = linspace(0, 2 * pi, count);
x = centreX + radiusX * cos(theta);
y = centreY + radiusY * sin(theta);
end

function sprite = createAlpacaSprite(ax, imagePath)
[rgb, ~, alpha] = imread(imagePath);
spriteStride = 4;
rgb = rgb(1:spriteStride:end, 1:spriteStride:end, :);
alpha = double(alpha(1:spriteStride:end, 1:spriteStride:end)) / 255;
sprite = surface(ax, nan(2), nan(2), zeros(2), ...
    'CData', flipud(rgb), 'FaceColor', 'texturemap', ...
    'AlphaData', flipud(alpha), 'FaceAlpha', 'texturemap', ...
    'AlphaDataMapping', 'none', 'EdgeColor', 'none', 'Visible', 'off');
end
