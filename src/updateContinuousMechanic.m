function handles = updateContinuousMechanic(handles, state, world, ~)
%UPDATECONTINUOUSMECHANIC Update animals and shared iced-tea pickups.

animals = state.levelState.animals;
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

alpaca = animals.alpacaRect;
head = [alpaca(1) + 1.25, alpaca(2) + 0.72, 0.72, 1.18];
set(handles.continuous.alpacaBody, 'Position', alpaca, 'Visible', 'on');
set(handles.continuous.alpacaHead, 'Position', head, 'Visible', 'on');
nose = world.mechanic.animals.alpacaNose;
set(handles.continuous.alpacaNose, ...
    'XData', nose(1) + 0.76 * nose(3), ...
    'YData', nose(2) + 0.52 * nose(4), 'Visible', 'on');
legX = alpaca(1) + [0.35, 0.35, nan, 1.45, 1.45];
legY = alpaca(2) + [0.20, -0.32, nan, 0.20, -0.32];
set(handles.continuous.alpacaLegs, 'XData', legX, ...
    'YData', legY, 'Visible', 'on');
if animals.sneezeWarning > 0
    set(handles.continuous.alpacaWarning, ...
        'Position', [alpaca(1) + alpaca(3) / 2, ...
        alpaca(2) + alpaca(4) + 1.0, 0], 'Visible', 'on');
else
    set(handles.continuous.alpacaWarning, 'Visible', 'off');
end

for index = 1:numel(world.mechanic.tea)
    pickup = world.mechanic.tea(index);
    collected = any(state.inventory.collectedTeaIds == string(pickup.id));
    if collected
        set(handles.continuous.tea(index), 'Visible', 'off');
        set(handles.continuous.teaLabel(index), 'Visible', 'off');
    else
        rect = pickup.rect;
        set(handles.continuous.tea(index), 'Position', rect, 'Visible', 'on');
        set(handles.continuous.teaLabel(index), 'Position', ...
            [rect(1) + rect(3) / 2, rect(2) + rect(4) + 0.18, 0], ...
            'Visible', 'on');
    end
end

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
elevator = networkData.elevator;
set(handles.continuous.networkElevator, 'Position', elevator, ...
    'Visible', 'on');
set(handles.continuous.networkElevatorLabel, 'Position', ...
    [elevator(1) + elevator(3) / 2, elevator(2) + elevator(4) + 0.18, 0], ...
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
end
