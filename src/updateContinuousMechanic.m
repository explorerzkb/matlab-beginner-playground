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
end
