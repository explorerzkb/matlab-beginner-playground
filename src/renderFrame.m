function state = renderFrame(fig, ax, state, level, cfg)
%RENDERFRAME Create scene objects once, then update their data in place.

if ~state.render.initialized || state.render.levelId ~= level.id
    state.render.handles = initializeScene(ax, level, cfg);
    state.render.initialized = true;
    state.render.levelId = level.id;
end
handles = state.render.handles;

cameraTarget = mean([state.players(1).pos(1), state.players(2).pos(1)]);
if strcmp(level.mechanic.type, 'continuousCampus') && ...
        isfield(state.levelState, 'activeRegionId') && ...
        strcmp(state.levelState.activeRegionId, 'network')
    page = level.mechanic.network.pageRect;
    cameraTarget = page(1) + page(3) / 2;
elseif strcmp(level.mechanic.type, 'continuousCampus') && ...
        isfield(state.levelState, 'activeRegionId') && ...
        strcmp(state.levelState.activeRegionId, 'lexue') && ...
        isfield(state.levelState, 'lexue')
    if ~state.levelState.lexue.homeActive
        page = level.mechanic.lexue.selectionPageRect;
        cameraTarget = page(1) + page(3) / 2;
    elseif cameraTarget >= level.mechanic.lexue.homePageRect(1) - 1.0
        page = level.mechanic.lexue.homePageRect;
        cameraTarget = page(1) + page(3) / 2;
    end
end
if ~isfield(state.render, 'cameraCentre')
    state.render.cameraCentre = cameraTarget;
else
    state.render.cameraCentre = state.render.cameraCentre + ...
        0.22 * (cameraTarget - state.render.cameraCentre);
end
cameraCentre = state.render.cameraCentre;
halfView = cfg.render.viewportWidth / 2;
cameraCentre = min(max(cameraCentre, halfView), level.worldWidth - halfView);
state.render.cameraCentre = cameraCentre;
xBounds = [cameraCentre - halfView, cameraCentre + halfView];
xlim(ax, xBounds);
ylim(ax, [-0.4, cfg.render.worldHeight]);

for playerIndex = 1:2
    otherIndex = 3 - playerIndex;
    ropeDirection = state.players(otherIndex).pos - ...
        state.players(playerIndex).pos;
    handles.players(playerIndex) = updatePear( ...
        handles.players(playerIndex), state.players(playerIndex), ...
        playerIndex, ropeDirection, state.rope.currentTension, cfg);
end

anchor1 = state.players(1).pos + ...
    [0.46 * state.players(1).size(1), 0.62 * state.players(1).size(2)];
anchor2 = state.players(2).pos + ...
    [-0.46 * state.players(2).size(1), 0.62 * state.players(2).size(2)];
distance = hypot(anchor2(1) - anchor1(1), anchor2(2) - anchor1(2));
sag = max(0, min(0.65, (cfg.rope.length - distance) * 0.22));
midpoint = (anchor1 + anchor2) / 2 - [0, sag];
set(handles.rope, 'XData', [anchor1(1), midpoint(1), anchor2(1)], ...
    'YData', [anchor1(2), midpoint(2), anchor2(2)]);
if state.rope.currentTension > 0
    set(handles.rope, 'LineWidth', 3.2, 'Color', [0.68, 0.23, 0.16]);
else
    set(handles.rope, 'LineWidth', 2.2, 'Color', cfg.presentation.colors.rope);
end

handles = updateMechanic(handles, state, level, cfg);

if isfield(level, 'regions')
    regionLabel = level.regions(state.world.activeRegionIndex).label;
else
    regionLabel = level.name;
end
if state.inventory.buffTimer > 0
    buffLabel = sprintf(' · 强化 %.1fs', state.inventory.buffTimer);
else
    buffLabel = '';
end
hudText = sprintf(['%s   |   当前破防 %d/%d   共同复活 %d   ' ...
    '冰红茶 %d/%d%s   绳力 %.1f'], ...
    regionLabel, state.status.breakValue, cfg.break.maxValue, ...
    state.stats.failures, state.inventory.teaCount, ...
    state.inventory.teaMax, buffLabel, state.rope.currentTension);
set(handles.hud, 'Position', [xBounds(1) + 0.45, 12.45, 0], ...
    'String', hudText);
set(handles.instruction, 'Position', [xBounds(1) + 0.45, 11.75, 0], ...
    'String', currentWorldInstruction(state, level));
set(handles.checkpointText, 'Position', [xBounds(2) - 0.45, 12.45, 0], ...
    'String', sprintf('检查点 %d/%d', state.checkpointIndex, ...
    numel(level.checkpoints)));

if state.paused
    set(handles.pauseText, 'Position', [cameraCentre, 7.0, 0], ...
        'Visible', 'on');
else
    set(handles.pauseText, 'Visible', 'off');
end

state.render.handles = handles;
if isgraphics(fig)
    drawnow limitrate;
end
end

function handles = initializeScene(ax, level, cfg)
cla(ax);
hold(ax, 'on');
set(ax, 'Color', cfg.presentation.colors.sky, ...
    'XTick', [], 'YTick', [], ...
    'XGrid', 'off', 'YGrid', 'off', ...
    'Layer', 'top', 'FontName', cfg.render.fontName, ...
    'Box', 'off', 'LineWidth', 1.2);
axis(ax, 'manual');

drawStaticBackground(ax, level, cfg);

handles.platforms = gobjects(size(level.platforms, 1), 1);
for index = 1:size(level.platforms, 1)
    rect = level.platforms(index, :);
    [faceColor, edgeColor] = platformPalette(rect, level, cfg);
    handles.platforms(index) = rectangle(ax, 'Position', rect, ...
        'FaceColor', faceColor, ...
        'EdgeColor', edgeColor, ...
        'LineWidth', 1.8, 'Curvature', 0.04);
    drawPlatformTrim(ax, rect, edgeColor);
end

handles.finish = rectangle(ax, 'Position', level.finish, ...
    'FaceColor', [0.87, 0.96, 0.89], ...
    'EdgeColor', cfg.presentation.colors.safe, ...
    'LineWidth', 2.4, 'LineStyle', '--');
text(ax, level.finish(1) + level.finish(3) / 2, ...
    level.finish(2) + level.finish(4) + 0.25, '两人出口', ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
    'FontName', cfg.render.fontName, ...
    'Color', cfg.presentation.colors.safe);

handles.rope = plot(ax, [0, 0, 0], [0, 0, 0], '-', ...
    'Color', cfg.presentation.colors.rope, 'LineWidth', 2.2);
handles.players = repmat(emptyPlayerHandles(), 1, 2);
for playerIndex = 1:2
    handles.players(playerIndex) = createPear(ax, playerIndex, cfg);
end

gooseCount = 2;
duckCount = 0;
if strcmp(level.mechanic.type, 'continuousCampus')
    gooseCount = size(level.mechanic.animals.geese, 1);
    duckCount = size(level.mechanic.animals.ducks, 1);
elseif strcmp(level.mechanic.type, 'geese')
    gooseCount = size(level.mechanic.geese, 1);
end
handles.geese = gobjects(gooseCount, 1);
handles.gooseNecks = gobjects(gooseCount, 1);
handles.gooseHeads = gobjects(gooseCount, 1);
handles.gooseBeaks = gobjects(gooseCount, 1);
for index = 1:gooseCount
    handles.geese(index) = patch(ax, nan, nan, [0.97, 0.97, 0.93], ...
        'EdgeColor', cfg.presentation.colors.ink, 'LineWidth', 1.2, ...
        'Visible', 'off');
    handles.gooseNecks(index) = plot(ax, nan, nan, '-', ...
        'Color', cfg.presentation.colors.ink, 'LineWidth', 4.0, ...
        'Visible', 'off');
    handles.gooseHeads(index) = plot(ax, nan, nan, 'o', ...
        'MarkerSize', 8, 'MarkerFaceColor', [0.97, 0.97, 0.93], ...
        'MarkerEdgeColor', cfg.presentation.colors.ink, 'Visible', 'off');
    handles.gooseBeaks(index) = plot(ax, nan, nan, '>', ...
        'MarkerSize', 5, 'MarkerFaceColor', [0.96, 0.55, 0.12], ...
        'MarkerEdgeColor', [0.55, 0.26, 0.06], 'Visible', 'off');
end
handles.ducks = gobjects(duckCount, 1);
handles.duckHeads = gobjects(duckCount, 1);
handles.duckBeaks = gobjects(duckCount, 1);
for index = 1:duckCount
    handles.ducks(index) = patch(ax, nan, nan, [0.61, 0.39, 0.20], ...
        'EdgeColor', [0.24, 0.20, 0.13], 'LineWidth', 1.1, ...
        'Visible', 'off');
    handles.duckHeads(index) = plot(ax, nan, nan, 'o', ...
        'MarkerSize', 7, 'MarkerFaceColor', [0.18, 0.46, 0.32], ...
        'MarkerEdgeColor', [0.10, 0.24, 0.18], 'Visible', 'off');
    handles.duckBeaks(index) = plot(ax, nan, nan, '>', ...
        'MarkerSize', 4, 'MarkerFaceColor', [0.95, 0.64, 0.16], ...
        'MarkerEdgeColor', [0.55, 0.31, 0.06], 'Visible', 'off');
end

handles.cardImage = surface(ax, nan(2), nan(2), zeros(2), ...
    'CData', zeros(2, 2, 3), 'FaceColor', 'texturemap', ...
    'EdgeColor', 'none', 'Visible', 'off');
handles.cardFrame = patch(ax, nan, nan, [1, 1, 1], ...
    'FaceColor', 'none', 'EdgeColor', [0.05, 0.45, 0.72], ...
    'LineWidth', 2.4, 'Visible', 'off');

routeCount = 0;
if strcmp(level.mechanic.type, 'navigation')
    routeCount = size(level.mechanic.routePlatforms, 1);
end
handles.routePlatforms = gobjects(routeCount, 1);
for index = 1:routeCount
    rect = level.mechanic.routePlatforms(index, :);
    handles.routePlatforms(index) = rectangle(ax, 'Position', rect, ...
        'FaceColor', [0.65, 0.68, 0.70], ...
        'EdgeColor', [0.45, 0.48, 0.50], 'LineStyle', '--', ...
        'LineWidth', 1.8);
end
handles.switches = gobjects(2, 1);
for index = 1:2
    handles.switches(index) = rectangle(ax, 'Position', [0, 0, 1, 1], ...
        'Curvature', [1, 1], 'FaceColor', [0.72, 0.76, 0.78], ...
        'EdgeColor', cfg.presentation.colors.ink, 'Visible', 'off');
end
handles.routeProgress = text(ax, 0, 0, '', 'Visible', 'off', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');
handles.auxCurve = plot(ax, nan, nan, 'o-', ...
    'Color', [0.65, 0.20, 0.72], 'MarkerFaceColor', [0.90, 0.62, 0.95], ...
    'LineWidth', 2.0, 'Visible', 'off');

handles.taskCards = gobjects(4, 1);
handles.taskTexts = gobjects(4, 1);
taskLabels = {'未交报告', '还有一章', '马上答辩', '小组消息 99+'};
for index = 1:4
    handles.taskCards(index) = rectangle(ax, 'Position', [0, 0, 1, 1], ...
        'FaceColor', [0.94, 0.35, 0.32], 'EdgeColor', [0.42, 0.08, 0.08], ...
        'LineWidth', 2.0, 'Curvature', 0.08, 'Visible', 'off');
    handles.taskTexts(index) = text(ax, 0, 0, taskLabels{index}, ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
        'FontName', cfg.render.fontName, 'Color', 'white', ...
        'Visible', 'off');
end
handles.bottle = rectangle(ax, 'Position', [0, 0, 1, 1], ...
    'FaceColor', [0.58, 0.86, 1.0], 'EdgeColor', [0.08, 0.32, 0.58], ...
    'LineWidth', 2.0, 'Curvature', 0.2, 'Visible', 'off');
handles.bottleText = text(ax, 0, 0, '破防水', ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
    'FontName', cfg.render.fontName, 'Color', [0.08, 0.26, 0.48], ...
    'Visible', 'off');
if strcmp(level.mechanic.type, 'continuousCampus')
    handles.continuous = initializeContinuousHandles(ax, level, cfg);
else
    handles.continuous = struct();
end

handles.hud = text(ax, 0, 0, '', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 12, ...
    'Color', cfg.presentation.colors.ink, ...
    'BackgroundColor', [1, 1, 1], 'Margin', 5);
handles.instruction = text(ax, 0, 0, '', 'FontName', cfg.render.fontName, ...
    'FontSize', 10.5, 'Color', cfg.presentation.colors.ink, ...
    'BackgroundColor', [1, 1, 1], 'Margin', 4);
handles.checkpointText = text(ax, 0, 0, '', ...
    'HorizontalAlignment', 'right', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'Color', cfg.presentation.colors.ink);
handles.pauseText = text(ax, 0, 0, ...
    {'已暂停', 'Esc 继续   ·   Q 退出'}, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'FontSize', 20, 'Color', cfg.presentation.colors.ink, ...
    'BackgroundColor', [1, 1, 1], 'Margin', 16, ...
    'Visible', 'off');

% Dynamic screenshots and route blocks must remain behind the characters.
uistack(handles.rope, 'top');
for playerIndex = 1:2
    uistack(handles.players(playerIndex).shadow, 'top');
    uistack(handles.players(playerIndex).body, 'top');
    uistack(handles.players(playerIndex).highlight, 'top');
    uistack(handles.players(playerIndex).speckles, 'top');
    uistack(handles.players(playerIndex).blush, 'top');
    uistack(handles.players(playerIndex).eyeWhites, 'top');
    uistack(handles.players(playerIndex).pupils, 'top');
    uistack(handles.players(playerIndex).eyeLines, 'top');
    uistack(handles.players(playerIndex).brows, 'top');
    uistack(handles.players(playerIndex).mouth, 'top');
    uistack(handles.players(playerIndex).badge, 'top');
    uistack(handles.players(playerIndex).ring, 'top');
end
uistack(handles.hud, 'top');
uistack(handles.instruction, 'top');
uistack(handles.checkpointText, 'top');
uistack(handles.pauseText, 'top');
end

function [faceColor, edgeColor] = platformPalette(rect, level, cfg)
faceColor = cfg.presentation.colors.platform;
edgeColor = cfg.presentation.colors.platformEdge;
if ~strcmp(level.mechanic.type, 'continuousCampus')
    return;
end

centreX = rect(1) + rect(3) / 2;
if centreX < 64
    faceColor = [0.61, 0.47, 0.28];
    edgeColor = [0.18, 0.29, 0.16];
elseif centreX < 96
    faceColor = [0.74, 0.84, 0.88];
    edgeColor = [0.20, 0.38, 0.50];
elseif centreX < 148
    faceColor = [0.66, 0.62, 0.53];
    edgeColor = [0.25, 0.27, 0.25];
else
    faceColor = [0.66, 0.77, 0.87];
    edgeColor = [0.18, 0.34, 0.55];
end
end

function drawPlatformTrim(ax, rect, edgeColor)
topY = rect(2) + rect(4);
centreX = rect(1) + rect(3) / 2;
if centreX < 64 && rect(2) < 1.2
    plot(ax, [rect(1), rect(1) + rect(3)], [topY, topY], '-', ...
        'Color', [0.20, 0.38, 0.16], 'LineWidth', 5.0);
    dots = linspace(rect(1) + 0.12, rect(1) + rect(3) - 0.12, ...
        max(3, round(rect(3) * 1.7)));
    plot(ax, dots, topY + 0.035 + 0.025 * sin(3.1 * dots), '.', ...
        'Color', [0.46, 0.65, 0.25], 'MarkerSize', 8);
else
    trimColor = min(1, edgeColor + 0.34);
    plot(ax, [rect(1) + 0.05, rect(1) + rect(3) - 0.05], ...
        [topY - 0.035, topY - 0.035], '-', ...
        'Color', trimColor, 'LineWidth', 2.0);
end
end

function drawStaticBackground(ax, level, cfg)
switch level.background
    case 'continuousCampus'
        drawContinuousBackground(ax, level, cfg);

    case 'northLake'
        patch(ax, [0, 44, 44, 0], [0.25, 0.25, 5.2, 5.2], ...
            cfg.presentation.colors.water, 'EdgeColor', 'none', ...
            'FaceAlpha', 0.34);
        drawDetailedCampusLayer(ax, level.background, cfg);
        % Distant red bridge: one supported west-bank landing, piers, far end muted.
        patch(ax, [1.0, 5.5, 9.0, 14.0, 14.0, 8.8, 5.3, 1.0], ...
            [5.4, 5.4, 6.25, 6.25, 6.55, 6.55, 5.72, 5.72], ...
            [0.67, 0.18, 0.12], 'EdgeColor', [0.43, 0.10, 0.08], ...
            'LineWidth', 1.4, 'FaceAlpha', 0.78);
        plot(ax, [1.0, 5.5, 9.0, 14.0], [6.05, 6.05, 6.90, 6.90], ...
            '-', 'Color', [0.46, 0.09, 0.07], 'LineWidth', 2.0);
        for x = 1.2:1.0:13.8
            if x <= 5.5
                deckY = 5.55;
            elseif x <= 9.0
                deckY = 5.55 + (x - 5.5) * (0.85 / 3.5);
            else
                deckY = 6.40;
            end
            plot(ax, [x, x], [deckY, deckY + 0.50], '-', ...
                'Color', [0.46, 0.09, 0.07], 'LineWidth', 1.0);
        end
        for x = [2.0, 5.4, 8.9, 12.6]
            plot(ax, [x, x], [4.2, 5.55], '-', 'Color', [0.40, 0.18, 0.12], ...
                'LineWidth', 2.0);
        end
        patch(ax, [0, 2.0, 2.0, 0], [4.2, 4.2, 6.0, 6.0], ...
            [0.36, 0.55, 0.31], 'EdgeColor', 'none');
        for x = 17:4:41
            plot(ax, x, 6.3 + 0.25 * mod(x, 3), 'o', ...
                'MarkerSize', 30, 'MarkerFaceColor', [0.28, 0.54, 0.31], ...
                'MarkerEdgeColor', [0.18, 0.38, 0.22]);
        end
        text(ax, 3.0, 8.3, '北湖红桥 · 远景不可踩', ...
            'FontName', cfg.render.fontName, 'Color', [0.37, 0.18, 0.15], ...
            'FontWeight', 'bold');

    case 'networkBridge'
        patch(ax, [0, 22.5, 22.5, 0], [0, 0, 9.5, 9.5], ...
            [0.77, 0.88, 0.82], 'EdgeColor', 'none', 'FaceAlpha', 0.52);
        patch(ax, [22.5, 46, 46, 22.5], [0, 0, 9.5, 9.5], ...
            [0.78, 0.84, 0.94], 'EdgeColor', 'none', 'FaceAlpha', 0.52);
        drawDetailedCampusLayer(ax, level.background, cfg);
        plot(ax, [0, 46], [5.9, 5.9], '-', 'Color', [0.70, 0.58, 0.33], ...
            'LineWidth', 7);
        plot(ax, [5, 41], [5.9, 5.9], '--', 'Color', [1, 1, 1], ...
            'LineWidth', 1.5);
        text(ax, 6, 8.6, '北区', 'FontName', cfg.render.fontName, ...
            'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.15, 0.38, 0.28]);
        text(ax, 36, 8.6, '南区', 'FontName', cfg.render.fontName, ...
            'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.18, 0.30, 0.52]);
        text(ax, 21.5, 6.6, '道路／桥的章节转场（非精确复刻）', ...
            'FontName', cfg.render.fontName, 'HorizontalAlignment', 'center', ...
            'Color', cfg.presentation.colors.muted);

    case 'navigation'
        drawDetailedCampusLayer(ax, level.background, cfg);
        for y = [4.3, 6.3, 8.3]
            plot(ax, [2, 43], [y, y], ':', 'Color', [0.34, 0.52, 0.68], ...
                'LineWidth', 2.0);
        end
        text(ax, 4, 8.9, 'i 北理 / 艾比特', 'FontName', cfg.render.fontName, ...
            'FontSize', 20, 'FontWeight', 'bold', ...
            'Color', cfg.presentation.colors.uiBlue);
        text(ax, 4, 7.8, '路线状态会直接改变道路状态', ...
            'FontName', cfg.render.fontName, 'Color', cfg.presentation.colors.muted);

    case 'deadlineStorm'
        patch(ax, [0, 48, 48, 0], [0, 0, 10, 10], [0.95, 0.82, 0.75], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.30);
        drawDetailedCampusLayer(ax, level.background, cfg);
        for x = 2:5:46
            plot(ax, [x, x + 2.2], [8.5, 9.5], '-', ...
                'Color', [0.72, 0.32, 0.28], 'LineWidth', 1.4);
        end
        patch(ax, [43, 48, 48, 43], [0.2, 0.2, 4.4, 4.4], ...
            [0.38, 0.75, 0.92], 'EdgeColor', [0.12, 0.44, 0.66], ...
            'FaceAlpha', 0.46);
        text(ax, 45.5, 5.0, 'Lucy 河补给点', ...
            'FontName', cfg.render.fontName, 'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', 'Color', [0.08, 0.34, 0.54]);
end
end

function handles = updateMechanic(handles, state, level, cfg)
switch level.mechanic.type
    case 'continuousCampus'
        handles = updateContinuousMechanic(handles, state, level, cfg);

    case 'geese'
        rects = state.levelState.dynamicObjects.geese;
        for index = 1:size(rects, 1)
            rect = rects(index, :);
            t = linspace(0, 2 * pi, 20);
            x = rect(1) + rect(3) * (0.5 + 0.48 * cos(t));
            y = rect(2) + rect(4) * (0.42 + 0.38 * sin(t));
            set(handles.geese(index), 'XData', x, 'YData', y, 'Visible', 'on');
            neckX = rect(1) + 0.75 * rect(3);
            neckY = rect(2) + 0.60 * rect(4);
            headX = rect(1) + 0.86 * rect(3);
            headY = rect(2) + 1.02 * rect(4);
            set(handles.gooseNecks(index), ...
                'XData', [neckX, headX], 'YData', [neckY, headY], ...
                'Visible', 'on');
            set(handles.gooseHeads(index), 'XData', headX, ...
                'YData', headY, 'Visible', 'on');
            set(handles.gooseBeaks(index), 'XData', headX + 0.10 * rect(3), ...
                'YData', headY, 'Visible', 'on');
        end

    case 'loginCard'
        card = state.levelState.dynamicObjects.loginCard;
        angle = state.levelState.dynamicObjects.loginCardAngle;
        visualHeight = 4.0;
        centre = [card(1) + card(3) / 2, card(2) + 0.55 + visualHeight / 2];
        localX = [-card(3) / 2, card(3) / 2; ...
                  -card(3) / 2, card(3) / 2];
        localY = [-visualHeight / 2, -visualHeight / 2; ...
                   visualHeight / 2,  visualHeight / 2];
        rotatedX = centre(1) + localX * cos(angle) - localY * sin(angle);
        rotatedY = centre(2) + localX * sin(angle) + localY * cos(angle);
        set(handles.cardImage, 'XData', rotatedX, 'YData', rotatedY, ...
            'Visible', 'on');
        frameX = [rotatedX(1, 1), rotatedX(1, 2), ...
            rotatedX(2, 2), rotatedX(2, 1)];
        frameY = [rotatedY(1, 1), rotatedY(1, 2), ...
            rotatedY(2, 2), rotatedY(2, 1)];
        set(handles.cardFrame, 'XData', frameX, 'YData', frameY, ...
            'Visible', 'on');
        if isequal(size(get(handles.cardImage, 'CData')), [2, 2, 3])
            [rgb, ~, alpha] = imread(cfg.assets.loginImage);
            stride = max(1, round(cfg.render.loginTextureStride));
            rgb = rgb(1:stride:end, 1:stride:end, :);
            set(handles.cardImage, 'CData', flipud(rgb));
            if ~isempty(alpha)
                alpha = alpha(1:stride:end, 1:stride:end);
                set(handles.cardImage, 'AlphaData', flipud(alpha), ...
                    'AlphaDataMapping', 'none', 'FaceAlpha', 'texturemap');
            end
        end

    case 'navigation'
        zones = level.mechanic.switches;
        for index = 1:2
            set(handles.switches(index), 'Position', zones(index, :), ...
                'Visible', 'on');
        end
        if state.levelState.routeActive
            routeColor = [0.28, 0.75, 0.46];
            edgeColor = [0.08, 0.42, 0.22];
            lineStyle = '-';
            label = sprintf('路线已启用 %.1f s', state.levelState.routeTimer);
        else
            routeColor = [0.65, 0.68, 0.70];
            edgeColor = [0.45, 0.48, 0.50];
            lineStyle = '--';
            progress = state.levelState.confirmTimer / level.mechanic.confirmDuration;
            label = sprintf('双人确认 %.0f%%', 100 * progress);
        end
        for index = 1:numel(handles.routePlatforms)
            set(handles.routePlatforms(index), 'FaceColor', routeColor, ...
                'EdgeColor', edgeColor, 'LineStyle', lineStyle);
        end
        centre = mean(zones(:, 1) + zones(:, 3) / 2);
        set(handles.routeProgress, 'Position', [centre, 2.0, 0], ...
            'String', label, 'Visible', 'on', 'Color', edgeColor);
        if ~isempty(state.levelState.auxCurve)
            set(handles.auxCurve, ...
                'XData', state.levelState.auxCurve(:, 1), ...
                'YData', state.levelState.auxCurve(:, 2), ...
                'Visible', 'on');
        end

    case 'deadlineStorm'
        cards = state.levelState.dynamicObjects.taskCards;
        for index = 1:size(cards, 1)
            rect = cards(index, :);
            set(handles.taskCards(index), 'Position', rect, 'Visible', 'on');
            set(handles.taskTexts(index), 'Position', ...
                [rect(1) + rect(3) / 2, rect(2) + rect(4) / 2, 0], ...
                'Visible', 'on');
        end
        bottle = level.mechanic.bottle;
        if state.levelState.bottleCollected
            set(handles.bottle, 'Visible', 'off');
            set(handles.bottleText, 'Visible', 'off');
        else
            set(handles.bottle, 'Position', bottle, 'Visible', 'on');
            set(handles.bottleText, 'Position', ...
                [bottle(1) + bottle(3) / 2, bottle(2) + bottle(4) + 0.25, 0], ...
                'Visible', 'on');
        end
end
end

function handles = emptyPlayerHandles()
handles = struct('shadow', gobjects(1), 'body', gobjects(1), ...
    'highlight', gobjects(1), 'speckles', gobjects(1), ...
    'blush', gobjects(1), 'eyeWhites', gobjects(1), ...
    'pupils', gobjects(1), 'eyeLines', gobjects(1), ...
    'brows', gobjects(1), 'mouth', gobjects(1), ...
    'badge', gobjects(1), 'ring', gobjects(1));
end

function handles = createPear(ax, playerIndex, cfg)
handles = emptyPlayerHandles();
handles.shadow = patch(ax, nan, nan, [0.10, 0.14, 0.15], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.20);
if playerIndex == 1
    bodyColor = cfg.presentation.colors.player1;
    badgeMarker = 'o';
else
    bodyColor = cfg.presentation.colors.player2;
    badgeMarker = 'd';
end
handles.body = patch(ax, nan, nan, bodyColor, ...
    'EdgeColor', cfg.presentation.colors.ink, 'LineWidth', 2.2, ...
    'LineJoin', 'round');
handles.highlight = patch(ax, nan, nan, [1, 1, 1], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.18);
handles.speckles = plot(ax, nan, nan, '.', ...
    'Color', 0.58 * bodyColor, 'MarkerSize', 7);
handles.blush = plot(ax, nan, nan, '.', 'Color', [0.93, 0.39, 0.39], ...
    'MarkerSize', 16);
handles.eyeWhites = plot(ax, nan, nan, 'o', ...
    'MarkerFaceColor', [1.00, 0.98, 0.91], ...
    'MarkerEdgeColor', cfg.presentation.colors.ink, ...
    'MarkerSize', 6.4, 'LineWidth', 1.0);
handles.pupils = plot(ax, nan, nan, '.', 'Color', cfg.presentation.colors.ink, ...
    'MarkerSize', 11);
handles.eyeLines = plot(ax, nan, nan, '-', ...
    'Color', cfg.presentation.colors.ink, 'LineWidth', 1.8);
handles.brows = plot(ax, nan, nan, '-', ...
    'Color', cfg.presentation.colors.ink, 'LineWidth', 1.5);
handles.mouth = plot(ax, nan, nan, '-', 'Color', cfg.presentation.colors.ink, ...
    'LineWidth', 1.3);
handles.badge = plot(ax, nan, nan, badgeMarker, ...
    'MarkerFaceColor', 'white', 'MarkerEdgeColor', cfg.presentation.colors.ink, ...
    'MarkerSize', 7, 'LineWidth', 1.2);
handles.ring = plot(ax, nan, nan, 'o', 'MarkerFaceColor', 'none', ...
    'MarkerEdgeColor', cfg.presentation.colors.ink, 'MarkerSize', 5, ...
    'LineWidth', 1.2);
end

function handles = updatePear(handles, player, playerIndex, ...
        ropeDirection, ropeTension, ~)
height = player.size(2);
width = player.size(1);
stretch = 1 + min(0.12, abs(player.vel(2)) * 0.009);
if player.onGround && abs(player.vel(1)) > 1.0
    stretch = 0.96;
end
squash = 1 / sqrt(stretch);
tilt = max(-0.18, min(0.18, -player.vel(1) * 0.018));

yNorm = linspace(0, 1, 44)';
halfWidth = 0.06 + ...
    0.42 * sin(pi * yNorm) .^ 0.70 .* (1.15 - 0.45 * yNorm) + ...
    0.23 * (1 - yNorm) .^ 5;
left = [-flipud(halfWidth), flipud(yNorm)];
right = [halfWidth(2:end), yNorm(2:end)];
local = [left; right];
local(:, 1) = local(:, 1) * width * squash;
local(:, 2) = local(:, 2) * height * stretch;
rotation = [cos(tilt), -sin(tilt); sin(tilt), cos(tilt)];
points = local * rotation' + player.pos;
set(handles.body, 'XData', points(:, 1), 'YData', points(:, 2));

highlightLocal = [-0.29, 0.30; -0.34, 0.48; -0.25, 0.72; ...
    -0.11, 0.88; -0.03, 0.76; -0.14, 0.54; -0.14, 0.34];
highlightLocal(:, 1) = highlightLocal(:, 1) * width * squash;
highlightLocal(:, 2) = highlightLocal(:, 2) * height * stretch;
highlightPoints = highlightLocal * rotation' + player.pos;
set(handles.highlight, 'XData', highlightPoints(:, 1), ...
    'YData', highlightPoints(:, 2));
set(handles.speckles, ...
    'XData', player.pos(1) + [-0.27, 0.22, 0.31, -0.18] * width, ...
    'YData', player.pos(2) + [0.29, 0.37, 0.24, 0.18] * height);

t = linspace(0, 2 * pi, 20);
airHeight = max(0, min(3, player.pos(2) - 1));
shadowWidth = width * (0.48 + 0.06 * double(player.onGround) - 0.04 * airHeight);
set(handles.shadow, 'XData', player.pos(1) + shadowWidth * cos(t), ...
    'YData', player.pos(2) - 0.07 - 0.03 * airHeight + 0.075 * sin(t), ...
    'FaceAlpha', 0.24 - 0.04 * airHeight);

face = pearExpressionState(player, ropeDirection, ropeTension);
eyeCentresX = player.pos(1) + [-0.17, 0.17] * width;
eyeY = player.pos(2) + 0.69 * height;
set(handles.eyeWhites, 'XData', eyeCentresX, 'YData', [eyeY, eyeY]);
set(handles.pupils, 'XData', eyeCentresX + face.gaze(1) * width, ...
    'YData', [eyeY, eyeY] + face.gaze(2) * height);
set(handles.eyeLines, 'XData', nan, 'YData', nan);
set(handles.brows, 'XData', nan, 'YData', nan);
set(handles.blush, 'XData', nan, 'YData', nan);

mouthY = player.pos(2) + 0.45 * height;
mouthX = player.pos(1) + [-0.13, -0.06, 0, 0.06, 0.13] * width;
switch face.name
    case 'pain'
        set(handles.eyeWhites, 'XData', nan, 'YData', nan);
        set(handles.pupils, 'XData', nan, 'YData', nan);
        eyeX = player.pos(1) + [-0.25, -0.11, nan, 0.11, 0.25] * width;
        eyeLineY = eyeY + [0.05, -0.04, nan, -0.04, 0.05] * height;
        set(handles.eyeLines, 'XData', eyeX, 'YData', eyeLineY);
        set(handles.brows, 'XData', player.pos(1) + ...
            [-0.28, -0.11, nan, 0.11, 0.28] * width, ...
            'YData', eyeY + [0.13, 0.08, nan, 0.08, 0.13] * height);
        mouthCurve = mouthY + [0.01, 0.05, 0.00, 0.05, 0.01] * height;
    case 'pulled'
        pullSign = sign(face.gaze(1));
        if pullSign == 0
            pullSign = 1;
        end
        set(handles.brows, 'XData', player.pos(1) + ...
            [-0.27, -0.10, nan, 0.10, 0.27] * width, ...
            'YData', eyeY + [0.11, 0.05, nan, 0.05, 0.11] * height);
        mouthCurve = mouthY + [0, 0.025, -0.015, 0.025, 0] * height;
        mouthX = mouthX + 0.035 * pullSign * width;
    case 'joy'
        set(handles.blush, 'XData', player.pos(1) + [-0.31, 0.31] * width, ...
            'YData', [mouthY + 0.08 * height, mouthY + 0.08 * height]);
        set(handles.eyeWhites, 'XData', nan, 'YData', nan);
        set(handles.pupils, 'XData', nan, 'YData', nan);
        set(handles.eyeLines, 'XData', player.pos(1) + ...
            [-0.27, -0.18, -0.09, nan, 0.09, 0.18, 0.27] * width, ...
            'YData', eyeY + [0.00, 0.055, 0.00, nan, ...
            0.00, 0.055, 0.00] * height);
        mouthX = player.pos(1) + [-0.18, -0.09, 0, 0.09, 0.18] * width;
        mouthCurve = mouthY + [0.08, 0.005, -0.07, 0.005, 0.08] * height;
    case 'surprised'
        mouthX = player.pos(1) + 0.075 * width * cos(t);
        mouthCurve = mouthY + 0.085 * height * sin(t);
    case 'playful'
        set(handles.blush, 'XData', player.pos(1) + [-0.31, 0.31] * width, ...
            'YData', [mouthY + 0.07 * height, mouthY + 0.07 * height]);
        mouthCurve = mouthY + [0.025, -0.015, -0.045, -0.01, 0.04] * height;
    otherwise
        set(handles.blush, 'XData', player.pos(1) + [-0.31, 0.31] * width, ...
            'YData', [mouthY + 0.07 * height, mouthY + 0.07 * height]);
        mouthCurve = mouthY + [0.035, -0.005, -0.025, -0.005, 0.035] * height;
end
set(handles.mouth, 'XData', mouthX, 'YData', mouthCurve);
set(handles.badge, 'XData', player.pos(1), ...
    'YData', player.pos(2) + 0.28 * height);
ringSide = -1;
if playerIndex == 1
    ringSide = 1;
end
set(handles.ring, 'XData', player.pos(1) + ringSide * 0.46 * width, ...
    'YData', player.pos(2) + 0.62 * height);
end
