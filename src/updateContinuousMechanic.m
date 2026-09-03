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
    t = linspace(0, 2 * pi, 20);
    x = rect(1) + rect(3) * (0.5 + 0.48 * cos(t));
    y = rect(2) + rect(4) * (0.42 + 0.38 * sin(t));
    set(handles.geese(index), 'XData', x, 'YData', y, 'Visible', 'on');
    neckX = rect(1) + 0.75 * rect(3);
    neckY = rect(2) + 0.60 * rect(4);
    headX = rect(1) + 0.86 * rect(3);
    headY = rect(2) + 1.02 * rect(4);
    set(handles.gooseNecks(index), 'XData', [neckX, headX], ...
        'YData', [neckY, headY], 'Visible', 'on');
    set(handles.gooseHeads(index), 'XData', headX, ...
        'YData', headY, 'Visible', 'on');
    set(handles.gooseBeaks(index), 'XData', headX + 0.10 * rect(3), ...
        'YData', headY, 'Visible', 'on');
end

for index = 1:size(animals.duckRects, 1)
    rect = animals.duckRects(index, :);
    t = linspace(0, 2 * pi, 20);
    x = rect(1) + rect(3) * (0.48 + 0.46 * cos(t));
    y = rect(2) + rect(4) * (0.44 + 0.36 * sin(t));
    set(handles.ducks(index), 'XData', x, 'YData', y, 'Visible', 'on');
    headX = rect(1) + 0.82 * rect(3);
    headY = rect(2) + 0.83 * rect(4);
    set(handles.duckHeads(index), 'XData', headX, ...
        'YData', headY, 'Visible', 'on');
    set(handles.duckBeaks(index), 'XData', headX + 0.12 * rect(3), ...
        'YData', headY, 'Visible', 'on');
end
else
    hideMany(handles.geese, handles.gooseNecks, handles.gooseHeads, ...
        handles.gooseBeaks, handles.ducks, handles.duckHeads, ...
        handles.duckBeaks);
end

if animalDetailVisible
alpaca = animals.alpacaRect;
head = [alpaca(1) + 1.25, alpaca(2) + 0.72, 0.72, 1.18];
theta = linspace(0, 2 * pi, 32);
bodyX = alpaca(1) + alpaca(3) * (0.50 + 0.49 * cos(theta));
bodyY = alpaca(2) + alpaca(4) * (0.46 + 0.43 * sin(theta));
set(handles.continuous.alpacaBody, 'XData', bodyX, 'YData', bodyY, ...
    'Visible', 'on');
neckX = [alpaca(1) + 1.18, alpaca(1) + 1.78, ...
    alpaca(1) + 1.74, alpaca(1) + 1.35];
neckY = [alpaca(2) + 0.48, alpaca(2) + 0.54, ...
    alpaca(2) + 1.62, alpaca(2) + 1.58];
set(handles.continuous.alpacaNeck, 'XData', neckX, 'YData', neckY, ...
    'Visible', 'on');
headX = head(1) + head(3) * (0.50 + 0.49 * cos(theta));
headY = head(2) + head(4) * (0.50 + 0.48 * sin(theta));
set(handles.continuous.alpacaHead, 'XData', headX, 'YData', headY, ...
    'Visible', 'on');
earBaseY = head(2) + 0.96 * head(4);
earCentres = head(1) + head(3) * [0.27, 0.70];
for index = 1:2
    earX = earCentres(index) + head(3) * [-0.13, 0, 0.12];
    earY = earBaseY + head(4) * [0, 0.34, 0.01];
    set(handles.continuous.alpacaEars(index), ...
        'XData', earX, 'YData', earY, 'Visible', 'on');
end
eyeY = head(2) + 0.63 * head(4);
set(handles.continuous.alpacaEyes, ...
    'XData', head(1) + head(3) * [0.31, 0.65], ...
    'YData', [eyeY, eyeY], 'Visible', 'on');
muzzleTheta = linspace(0, 2 * pi, 24);
muzzleX = head(1) + 0.51 * head(3) + 0.27 * head(3) * cos(muzzleTheta);
muzzleY = head(2) + 0.33 * head(4) + 0.17 * head(4) * sin(muzzleTheta);
set(handles.continuous.alpacaMuzzle, 'XData', muzzleX, ...
    'YData', muzzleY, 'Visible', 'on');
set(handles.continuous.alpacaMouth, ...
    'XData', head(1) + head(3) * [0.41, 0.51, 0.61], ...
    'YData', head(2) + head(4) * [0.28, 0.23, 0.28], ...
    'Visible', 'on');
set(handles.continuous.alpacaBlush, ...
    'XData', head(1) + head(3) * [0.23, 0.77], ...
    'YData', head(2) + head(4) * [0.38, 0.38], 'Visible', 'on');
nose = world.mechanic.animals.alpacaNose;
set(handles.continuous.alpacaNose, ...
    'XData', head(1) + 0.51 * head(3), ...
    'YData', head(2) + 0.38 * head(4), 'MarkerSize', 4.5, ...
    'Visible', 'on');
legX = alpaca(1) + [0.35, 0.35, nan, 1.45, 1.45];
legY = alpaca(2) + [0.20, -0.32, nan, 0.20, -0.32];
set(handles.continuous.alpacaLegs, 'XData', legX, ...
    'YData', legY, 'Visible', 'on');
set(handles.continuous.alpacaLabel, 'Position', ...
    [alpaca(1) + alpaca(3) / 2, alpaca(2) + alpaca(4) + 0.45, 0], ...
    'Visible', 'on');
if animals.sneezeWarning > 0
    set(handles.continuous.alpacaWarning, ...
        'Position', [alpaca(1) + alpaca(3) / 2, ...
        alpaca(2) + alpaca(4) + 1.0, 0], 'Visible', 'on');
    puffPhase = 0.08 + 0.12 * sin(5 * animals.sneezeWarning);
    set(handles.continuous.alpacaSneezePuffs, ...
        'XData', nose(1) + nose(3) * [0.75, 1.05, 1.38], ...
        'YData', nose(2) + nose(4) * ([0.52, 0.68, 0.43] + puffPhase), ...
        'MarkerSize', 7 + 8 * animals.sneezeWarning, 'Visible', 'on');
else
    set(handles.continuous.alpacaWarning, 'Visible', 'off');
    set(handles.continuous.alpacaSneezePuffs, 'Visible', 'off');
end
else
    set(handles.continuous.alpacaBody, 'Visible', 'off');
    set(handles.continuous.alpacaNeck, 'Visible', 'off');
    set(handles.continuous.alpacaHead, 'Visible', 'off');
    set(handles.continuous.alpacaEars, 'Visible', 'off');
    set(handles.continuous.alpacaEyes, 'Visible', 'off');
    set(handles.continuous.alpacaMuzzle, 'Visible', 'off');
    set(handles.continuous.alpacaMouth, 'Visible', 'off');
    set(handles.continuous.alpacaBlush, 'Visible', 'off');
    set(handles.continuous.alpacaNose, 'Visible', 'off');
    set(handles.continuous.alpacaLegs, 'Visible', 'off');
    set(handles.continuous.alpacaLabel, 'Visible', 'off');
    set(handles.continuous.alpacaWarning, 'Visible', 'off');
    set(handles.continuous.alpacaSneezePuffs, 'Visible', 'off');
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
for index = 1:2
    occupancy = state.levelState.network.fieldOccupancy(index);
    if occupancy == 1
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
        'Visible', 'on');
end

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
        loginLabel = '请先双人填写';
    case 'ready'
        loginColor = [0.49, 0.70, 0.84];
        loginLabel = '两人站稳登录';
    case 'holding'
        loginColor = [0.91, 0.68, 0.22];
        progress = state.levelState.network.loginTimer / ...
            world.mechanic.network.loginHoldDuration;
        loginLabel = sprintf('登录 %.0f%%', 100 * progress);
    case 'success'
        loginColor = [0.35, 0.75, 0.45];
        loginLabel = '认证成功';
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
set(handles.continuous.networkSelfService, 'Position', selfService, ...
    'Visible', 'on');
set(handles.continuous.networkSelfServiceLabel, 'Position', ...
    [selfService(1) + selfService(3) / 2, ...
    selfService(2) + selfService(4) / 2, 0], ...
    'Visible', 'on');
for index = 1:2
    rect = networkData.rechargePads(index, :);
    if state.levelState.network.rechargeFlash(index) > 0
        color = [0.95, 0.80, 0.24];
    else
        color = [0.31, 0.75, 0.86];
    end
    set(handles.continuous.rechargePads(index), 'Position', rect, ...
        'FaceColor', color, 'Visible', 'on');
    set(handles.continuous.rechargeLabels(index), 'Position', ...
        [rect(1) + rect(3) / 2, rect(2) + rect(4) / 2, 0], ...
        'Visible', 'on');
end
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
