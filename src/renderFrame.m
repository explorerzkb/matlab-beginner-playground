function state = renderFrame(~, ax, state, level, cfg)
%RENDERFRAME Create scene objects once, then update their data in place.

mode = campusRenderMode(state,level);
if ~isfield(state.render,'viewMode') || ~strcmp(state.render.viewMode,mode)
    if isfield(state.render, 'handles') && ...
            isfield(state.render.handles, 'campusBackgroundAxes') && ...
            isgraphics(state.render.handles.campusBackgroundAxes)
        delete(state.render.handles.campusBackgroundAxes);
    end
    state.render.initialized = false;
    state.render.viewMode = mode;
    if isfield(state.render,'labelsClipped')
        state.render = rmfield(state.render,'labelsClipped');
    end
end

if ~state.render.initialized || state.render.levelId ~= level.id
    renderCfg = cfg;
    renderCfg.render.activeSegment = mode;
    state.render.handles = initializeScene(ax, level, renderCfg,strcmp(mode,'campus'));
    state.render.initialized = true;
    state.render.levelId = level.id;
    state.render.backgroundVisibilityCache = [];
end
handles = state.render.handles;

if ~isfield(state.render, 'cameraCentre')
    state.render.cameraCentre = mean([state.players(1).pos(1), ...
        state.players(2).pos(1)]);
end
cameraCentre = state.render.cameraCentre;
[viewWidth,viewHeight,cameraScale]=cameraViewport(state,cfg);
halfView = viewWidth / 2;
cameraCentre = min(max(cameraCentre, halfView), level.worldWidth - halfView);
state.render.cameraCentre = cameraCentre;
halfViewY = viewHeight / 2;
minimumCentreY = -0.4 + halfViewY;
maximumCentreY = max(minimumCentreY, ...
    max(level.worldHeight,cfg.render.flightCameraCeiling) - halfViewY);
if ~isfield(state.render, 'cameraCentreY') || ...
        ~isfinite(state.render.cameraCentreY)
    state.render.cameraCentreY = minimumCentreY;
end
cameraCentreY = min(max(state.render.cameraCentreY, ...
    minimumCentreY), maximumCentreY);
state.render.cameraCentreY = cameraCentreY;
xBounds = [cameraCentre - halfView, cameraCentre + halfView];
yBounds = [cameraCentreY - halfViewY, cameraCentreY + halfViewY];
if isfield(handles, 'cameraCulledBackgrounds') && ...
        ~isempty(handles.cameraCulledBackgrounds)
    backgrounds = handles.cameraCulledBackgrounds;
    visibility = false(size(backgrounds));
    for backgroundIndex = 1:numel(backgrounds)
        range = get(backgrounds(backgroundIndex), 'UserData');
        visibility(backgroundIndex) = range(2) >= xBounds(1) - 1 && ...
            range(1) <= xBounds(2) + 1;
    end
    if ~isequal(state.render.backgroundVisibilityCache, visibility)
        set(backgrounds(~visibility), 'Visible', 'off');
        set(backgrounds(visibility), 'Visible', 'on');
        state.render.backgroundVisibilityCache = visibility;
    end
end
if isfield(handles, 'worldTransform') && isgraphics(handles.worldTransform)
    % Keep the axes fixed and move the entire world with one matrix.  Updating
    % XLim/YLim makes MATLAB rebuild its interaction manager on every camera
    % tick, which was the largest measured render cost.
    matrix = makehgtform('scale',[cameraScale cameraScale 1]) * ...
        makehgtform('translate', [-xBounds(1), -yBounds(1), 0]);
    set(handles.worldTransform, 'Matrix', matrix);
    xBounds = [0, cfg.render.viewportWidth];
    yBounds = [0, cfg.render.viewportHeight];
    cameraCentre = cfg.render.viewportWidth/2;
    cameraCentreY = cfg.render.viewportHeight/2;
elseif ~isequal(ax.XLim, xBounds) || ~isequal(ax.YLim, yBounds)
    set(ax, 'XLim', xBounds, 'YLim', yBounds);
end

for playerIndex = 1:2
    otherIndex = 3 - playerIndex;
    ropeDirection = state.players(otherIndex).pos - ...
        state.players(playerIndex).pos;
    handles.players(playerIndex) = updatePear( ...
        handles.players(playerIndex), state.players(playerIndex), ...
        playerIndex, ropeDirection, state.rope.currentTension, cfg);
    if ~isfield(state.render,'detailScale') || state.render.detailScale~=cameraScale
        set(handles.players(playerIndex).eyeWhites,'MarkerSize',6.4*cameraScale);
        set(handles.players(playerIndex).pupils,'MarkerSize',11*cameraScale);
        set(handles.players(playerIndex).blush,'MarkerSize',16*cameraScale);
        set(handles.players(playerIndex).ring,'MarkerSize',5*cameraScale);
    end
end
state.render.detailScale=cameraScale;

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
% World labels must stay inside the game viewport while the camera moves.
if ~isfield(state.render, 'labelsClipped')
    set(findall(ax, 'Type', 'text'), 'Clipping', 'on');
    state.render.labelsClipped = true;
end

if isfield(level, 'regions')
    regionLabel = level.regions(state.world.activeRegionIndex).label;
else
    regionLabel = level.name;
end
if state.inventory.buffTimer > 0
    buffLabel = sprintf('  BOOST %.1fs', state.inventory.buffTimer);
else
    buffLabel = '';
end
instructionLabel = currentWorldInstruction(state, level);
hudCache = struct( ...
    'mode', mode, ...
    'region', state.world.activeRegionIndex, ...
    'hearts', state.status.currentHearts, ...
    'deathPending', state.status.deathPending, ...
    'deathTenths', round(10 * state.status.deathTimer), ...
    'failures', state.stats.failures, ...
    'teaCount', state.inventory.teaCount, ...
    'buffTenths', round(10 * state.inventory.buffTimer), ...
    'ropeSegments', min(6, max(0, ceil(6 * state.rope.currentTension / ...
        cfg.rope.maxTension))), ...
    'checkpoint', state.checkpointIndex, ...
    'paused', state.paused, ...
    'instruction', instructionLabel, ...
    'screenBounds', [xBounds, yBounds]);
hudDirty = ~isfield(state.render, 'hudCache') || ...
    ~isequaln(state.render.hudCache, hudCache);
if hudDirty
panelLeft = xBounds(1) + 0.28;
panelBottom = yBounds(2) - 1.14;
set(handles.hudPanel, 'XData', panelLeft + [0, 11.75, 11.75, 0], ...
    'YData', panelBottom + [0, 0, 0.95, 0.95]);
if state.status.deathPending
    set(handles.hudPanel, 'FaceColor', [0.30, 0.07, 0.08]);
else
    set(handles.hudPanel, 'FaceColor', [0.035, 0.075, 0.095]);
end
for heartIndex = 1:numel(handles.hudHearts)
    heartRect = [panelLeft + 0.30 + (heartIndex - 1) * 0.66, ...
        panelBottom + 0.25, 0.56, 0.49];
    heartFull = heartIndex <= state.status.currentHearts;
    positionHeartSprite(handles.hudHearts(heartIndex), ...
        heartRect, heartFull);
end
for teaIndex = 1:numel(handles.hudTea)
    teaRect = [panelLeft + 2.45 + (teaIndex - 1) * 0.48, ...
        panelBottom + 0.13, 0.40, 0.69];
    positionTeaSprite(handles.hudTea(teaIndex), teaRect, 1.0);
    if teaIndex <= state.inventory.teaCount
        set(handles.hudTea(teaIndex), 'Visible', 'on');
    else
        set(handles.hudTea(teaIndex), 'Visible', 'off');
    end
end
ropeBarX = panelLeft + 4.45 + (0:5) * 0.27;
ropeBarY = repmat(panelBottom + 0.49, 1, 6);
filledRopeSegments = hudCache.ropeSegments;
set(handles.hudRopeBase, 'XData', ropeBarX, 'YData', ropeBarY);
set(handles.hudRopeFill, 'XData', ropeBarX(1:filledRopeSegments), ...
    'YData', ropeBarY(1:filledRopeSegments));
set(handles.hudRopeLabel, 'Position', ...
    [panelLeft + 3.55, panelBottom + 0.48, 0]);
if state.status.deathPending
    healthLabel = sprintf('复活中 %.1fs', state.status.deathTimer);
else
    healthLabel = sprintf('复活 %d', state.stats.failures);
end
hudText = sprintf('%s  |  %s%s', regionLabel, healthLabel, buffLabel);
set(handles.hud, 'Position', [panelLeft + 6.25, panelBottom + 0.48, 0], ...
    'String', hudText);
set(handles.instruction, 'Position', ...
    [xBounds(1) + 0.45, yBounds(2) - 1.55, 0], ...
    'String', instructionLabel);
set(handles.checkpointText, 'Position', ...
    [xBounds(2) - 0.45, yBounds(2) - 0.55, 0], ...
    'String', sprintf('检查点 %d / %d', state.checkpointIndex, ...
    numel(level.checkpoints)));
set(handles.controlsHint, 'Position', ...
    [xBounds(2) - 0.45, yBounds(2) - 1.25, 0]);

if state.paused
    set(handles.pauseShade, ...
        'XData', [xBounds(1), xBounds(2), xBounds(2), xBounds(1)], ...
        'YData', [yBounds(1), yBounds(1), yBounds(2), yBounds(2)], ...
        'Visible', 'on');
    set(handles.pauseCard, 'Position', ...
        [cameraCentre - 4.4, cameraCentreY - 2.18, 8.8, 4.35], ...
        'Visible', 'on');
    set(handles.pauseAccent, 'XData', [cameraCentre - 3.15, ...
        cameraCentre + 3.15], 'YData', ...
        [cameraCentreY - 0.88, cameraCentreY - 0.88], 'Visible', 'on');
    set(handles.pauseText, 'Position', ...
        [cameraCentre, cameraCentreY + 0.82, 0], ...
        'Visible', 'on');
    set(handles.pauseHint, 'Position', ...
        [cameraCentre, cameraCentreY - 1.38, 0], ...
        'Visible', 'on');
else
    set(handles.pauseShade, 'Visible', 'off');
    set(handles.pauseCard, 'Visible', 'off');
    set(handles.pauseAccent, 'Visible', 'off');
    set(handles.pauseText, 'Visible', 'off');
    set(handles.pauseHint, 'Visible', 'off');
end
state.render.hudCache = hudCache;
end

state.render.handles = handles;
end

function handles = initializeScene(ax, level, cfg,campusOnly)
cla(ax);
hold(ax, 'on');
axesColour = cfg.presentation.colors.sky;
if campusOnly
    axesColour = 'none';
end
set(ax, 'Color', axesColour, ...
    'XTick', [], 'YTick', [], ...
    'XGrid', 'off', 'YGrid', 'off', ...
    'Layer', 'top', 'FontName', cfg.render.fontName, ...
    'Box', 'off', 'LineWidth', 1.2, 'SortMethod', 'childorder');
axis(ax, 'manual');
disableDefaultInteractivity(ax);

if ~campusOnly
    previousChildCount = numel(ax.Children);
    drawStaticBackground(ax, level, cfg);
    newChildCount = numel(ax.Children) - previousChildCount;
    tagCameraCulledObjects(ax.Children(1:newChildCount));
end

handles.campusBackgroundAxes = gobjects(1);
handles.campusBackdrop = gobjects(1);
handles.campusRoad = gobjects(1);
if strcmp(level.mechanic.type,'continuousCampus')
    % The painted road IS the playable road. The panorama shares the world
    % transform, so neither the ground nor the architecture jumps in flight.
    stride = max(1, cfg.render.campusHandscrollTextureStride);
    rgb = readGameImage(cfg.assets.lastBusHandscroll, stride);
    % A runtime sky matte lets the existing continuous world sky show
    % through. Only sky connected vertically to the top edge is removed;
    % blue glass below a roof remains opaque. Computed once, never per frame.
    colours = double(rgb);
    skyPixels = colours(:,:,3)>1.03*colours(:,:,2) & ...
        colours(:,:,2)>1.08*colours(:,:,1);
    skyPixels = skyPixels | min(colours,[],3)>230;
    skyPixels(2:end,:)=skyPixels(2:end,:) & ...
        max(abs(diff(colours,1,1)),[],3)<18;
    % The verified skyline starts below 42% of this source. Wispy white
    % clouds above it must not seed opaque vertical streaks in the matte.
    skyPixels(1:floor(size(rgb,1)*level.mechanic.bus.skyClearFraction),:) = true;
    skyMatte = cumprod(skyPixels,1)==0;
    backdropRect=level.mechanic.bus.backgroundRect;
    handles.campusBackdrop = image('Parent', ax, ...
        'CData', flipud(rgb), ...
        'AlphaData', flipud(double(skyMatte)), ...
        'AlphaDataMapping', 'none', ...
        'XData', backdropRect(1)+[0 backdropRect(3)], ...
        'YData', backdropRect(2)+[0 backdropRect(4)], ...
        'Tag', 'cameraCulledBackground', ...
        'UserData', backdropRect(1)+[0 backdropRect(3)]);
end

platformIndices = 1:size(level.platforms, 1);
if campusOnly
    platformIndices = zeros(1, 0);
elseif strcmp(level.mechanic.type, 'continuousCampus')
    segmentRange = activeSegmentRange(cfg.render.activeSegment);
    rightEdge = level.platforms(:, 1) + level.platforms(:, 3);
    platformIndices = find(rightEdge >= segmentRange(1) & ...
        level.platforms(:, 1) <= segmentRange(2));
end
platformCount = numel(platformIndices);
previousChildCount = numel(ax.Children);
handles.platforms = gobjects(platformCount, 1);
for handleIndex = 1:platformCount
    index = platformIndices(handleIndex);
    rect = level.platforms(index, :);
    [faceColor, edgeColor] = platformPalette(rect, level, cfg);
    if strcmp(level.mechanic.type,'continuousCampus') && ...
            rect(1)<170 && rect(1)+rect(3)>240 && rect(2)==0
        % The central narrow road already has a grass foreground texture.
        % Keep the same continuous collider, but don't cover its lawn in grey.
        rect(3)=level.mechanic.bus.backgroundRect(1)-rect(1);
    end
    handles.platforms(handleIndex) = rectangle(ax, 'Position', rect, ...
        'FaceColor', faceColor, 'EdgeColor', edgeColor, ...
        'LineWidth', 1.8, 'Curvature', 0.04);
    drawPlatformTrim(ax, rect, edgeColor);
end
newChildCount = numel(ax.Children) - previousChildCount;
tagCameraCulledObjects(ax.Children(1:newChildCount));

isContinuous = strcmp(level.mechanic.type, 'continuousCampus');
handles.finish = gobjects(1);
if ~isContinuous
    handles.finish = rectangle(ax, 'Position', level.finish, ...
        'FaceColor', 'none', ...
        'EdgeColor', cfg.presentation.colors.safe, ...
        'LineWidth', 2.4, 'LineStyle', '--');
    if strcmp(level.mechanic.type, 'continuousCampus')
        set(handles.finish, 'Visible', 'off');
    end
    text(ax, level.finish(1) + level.finish(3) / 2, ...
        level.finish(2) + level.finish(4) + 0.25, '体育馆终点', ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
        'FontName', cfg.render.fontName, ...
        'Color', cfg.presentation.colors.safe);
end

handles.rope = plot(ax, [0, 0, 0], [0, 0, 0], '-', ...
    'Color', cfg.presentation.colors.rope, 'LineWidth', 2.2);
handles.players = repmat(emptyPlayerHandles(), 1, 2);
for playerIndex = 1:2
    handles.players(playerIndex) = createPear(ax, playerIndex, cfg);
end

gooseCount = 2;
duckCount = 0;
if isContinuous && ~strcmp(cfg.render.activeSegment, 'world')
    % The post-flight campus view can never show the north-lake animals.
    % Avoid creating their 60+ hidden graphics objects: hidden HG objects
    % still participate in MATLAB's renderer bookkeeping.
    gooseCount = 0;
elseif strcmp(level.mechanic.type, 'continuousCampus')
    gooseCount = size(level.mechanic.animals.geese, 1);
    duckCount = size(level.mechanic.animals.ducks, 1);
elseif strcmp(level.mechanic.type, 'geese')
    gooseCount = size(level.mechanic.geese, 1);
end
handles.geese = gobjects(gooseCount, 1);
handles.gooseNecks = gobjects(gooseCount, 1);
handles.gooseHeads = gobjects(gooseCount, 1);
handles.gooseBeaks = gobjects(gooseCount, 1);
handles.gooseWings = gobjects(gooseCount, 1);
handles.gooseEyes = gobjects(gooseCount, 1);
handles.gooseLegs = gobjects(gooseCount, 1);
handles.gooseShadows = gobjects(gooseCount, 1);
if isContinuous && gooseCount > 0
    handles.geese = createCompoundBirdPatch(ax, 'goose', gooseCount);
else
    for index = 1:gooseCount
        [vertices, faces, colours] = birdPatchGeometry('goose');
        handles.geese(index) = patch(ax, 'Vertices', vertices, 'Faces', faces, ...
            'FaceVertexCData', colours, 'FaceColor', 'flat', ...
            'EdgeColor', 'none', 'Visible', 'off', 'UserData', vertices);
    end
end
handles.ducks = gobjects(duckCount, 1);
handles.duckHeads = gobjects(duckCount, 1);
handles.duckBeaks = gobjects(duckCount, 1);
handles.duckWings = gobjects(duckCount, 1);
handles.duckEyes = gobjects(duckCount, 1);
handles.duckLegs = gobjects(duckCount, 1);
handles.duckShadows = gobjects(duckCount, 1);
if isContinuous && duckCount > 0
    handles.ducks = createCompoundBirdPatch(ax, 'duck', duckCount);
else
    for index = 1:duckCount
        [vertices, faces, colours] = birdPatchGeometry('duck');
        handles.ducks(index) = patch(ax, 'Vertices', vertices, 'Faces', faces, ...
            'FaceVertexCData', colours, 'FaceColor', 'flat', ...
            'EdgeColor', 'none', 'Visible', 'off', 'UserData', vertices);
    end
end

handles.cardImage = gobjects(1);
handles.cardFrame = gobjects(1);
if ~isContinuous
    handles.cardImage = surface(ax, nan(2), nan(2), zeros(2), ...
        'CData', zeros(2, 2, 3), 'FaceColor', 'texturemap', ...
        'EdgeColor', 'none', 'Visible', 'off');
    handles.cardFrame = patch(ax, nan, nan, [1, 1, 1], ...
        'FaceColor', 'none', 'EdgeColor', [0.05, 0.45, 0.72], ...
        'LineWidth', 2.4, 'Visible', 'off');
end

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
switchCount = 2 * double(~isContinuous);
handles.switches = gobjects(switchCount, 1);
for index = 1:switchCount
    handles.switches(index) = rectangle(ax, 'Position', [0, 0, 1, 1], ...
        'Curvature', [1, 1], 'FaceColor', [0.72, 0.76, 0.78], ...
        'EdgeColor', cfg.presentation.colors.ink, 'Visible', 'off');
end
handles.routeProgress = gobjects(1);
handles.auxCurve = gobjects(1);
if ~isContinuous
    handles.routeProgress = text(ax, 0, 0, '', 'Visible', 'off', ...
        'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
    handles.auxCurve = plot(ax, nan, nan, 'o-', ...
        'Color', [0.65, 0.20, 0.72], 'MarkerFaceColor', [0.90, 0.62, 0.95], ...
        'LineWidth', 2.0, 'Visible', 'off');
end

taskCount = 4 * double(~isContinuous);
handles.taskCards = gobjects(taskCount, 1);
handles.taskTexts = gobjects(taskCount, 1);
taskLabels = {'未交报告', '还有一章', '马上答辩', '小组消息 99+'};
for index = 1:taskCount
    handles.taskCards(index) = rectangle(ax, 'Position', [0, 0, 1, 1], ...
        'FaceColor', [0.94, 0.35, 0.32], 'EdgeColor', [0.42, 0.08, 0.08], ...
        'LineWidth', 2.0, 'Curvature', 0.08, 'Visible', 'off');
    handles.taskTexts(index) = text(ax, 0, 0, taskLabels{index}, ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
        'FontName', cfg.render.fontName, 'Color', 'white', ...
        'Visible', 'off');
end
handles.bottle = gobjects(1);
if strcmp(level.mechanic.type, 'deadlineStorm')
    handles.bottle = createTeaSprite(ax, cfg.assets.teaSprite, ...
        cfg.render.teaTextureStride, cfg.tea);
end
if strcmp(level.mechanic.type, 'continuousCampus')
    handles.continuous = initializeContinuousHandles(ax, level, cfg,campusOnly);
else
    handles.continuous = struct();
end

handles.worldTransform = gobjects(1);
handles.worldTransform = hgtransform('Parent', ax);
worldChildren = ax.Children;
worldChildren(worldChildren == handles.worldTransform) = [];
if isContinuous
    % Create after the pears and mechanisms: near structures cover actors,
    % while the original bridge image remains the far-side background.
    handles.bridgeForeground=drawBridgeForeground(ax,level,cfg);
    handles.lakeRailForeground=drawLakeRailForeground(ax,level,cfg);
    set(handles.lakeRailForeground,'Parent',handles.worldTransform);
    set(handles.bridgeForeground.body,'Parent',handles.worldTransform);
    set(handles.bridgeForeground.rail,'Parent',handles.worldTransform);
end
% Reparent bottom-to-top so the child order remains exactly the same.  The
% earlier v14 batch regrouping reversed this order and let the sky cover the
% scene; the explicit loop preserves the v15 visual fix.
for childIndex = numel(worldChildren):-1:1
    set(worldChildren(childIndex), 'Parent', handles.worldTransform);
end
if isContinuous
    uistack(handles.bridgeForeground.body,'top');
    uistack(handles.bridgeForeground.rail,'top');
end
handles.cameraCulledBackgrounds = findobj(handles.worldTransform, ...
    '-regexp', 'Tag', '^cameraCulled');
set(ax, 'XLim', [0, cfg.render.viewportWidth], ...
    'YLim', [0, cfg.render.viewportHeight]);

handles.hudPanel = patch(ax, nan, nan, [0.035, 0.075, 0.095], ...
    'EdgeColor', [0.52, 0.70, 0.65], 'LineWidth', 1.5, ...
    'FaceAlpha', 0.96);
handles.hudHearts = gobjects(cfg.health.maxHearts, 1);
for heartIndex = 1:cfg.health.maxHearts
    handles.hudHearts(heartIndex) = createPixelHeart(ax);
end
handles.hudTea = gobjects(cfg.tea.maxCarried, 1);
for teaIndex = 1:cfg.tea.maxCarried
    handles.hudTea(teaIndex) = createTeaSprite(ax, cfg.assets.teaSprite, ...
        max(8, cfg.render.teaTextureStride), cfg.tea);
end
handles.hudRopeBase = plot(ax, nan, nan, 's', ...
    'LineStyle', 'none', 'MarkerSize', 6.8, ...
    'MarkerFaceColor', [0.19, 0.27, 0.29], ...
    'MarkerEdgeColor', [0.45, 0.57, 0.55], 'LineWidth', 0.8);
handles.hudRopeFill = plot(ax, nan, nan, 's', ...
    'LineStyle', 'none', 'MarkerSize', 6.8, ...
    'MarkerFaceColor', [0.95, 0.55, 0.13], ...
    'MarkerEdgeColor', [1.00, 0.78, 0.28], 'LineWidth', 0.8);
handles.hudRopeLabel = text(ax, 0, 0, '绳力', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'FontSize', 8.7, 'Color', [0.93, 0.98, 0.90], ...
    'VerticalAlignment', 'middle');
handles.hud = text(ax, 0, 0, '', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 9.4, ...
    'Color', [0.93, 0.98, 0.90], 'Interpreter', 'none');
handles.instruction = text(ax, 0, 0, '', 'FontName', cfg.render.fontName, ...
    'FontSize', 9.8, 'FontWeight', 'bold', ...
    'Color', [0.97, 0.98, 0.91], ...
    'BackgroundColor', [0.08, 0.22, 0.18], 'Margin', 5);
handles.checkpointText = text(ax, 0, 0, '', ...
    'HorizontalAlignment', 'right', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 10, 'Color', 'white', ...
    'BackgroundColor', [0.58, 0.29, 0.07], 'Margin', 5);
handles.controlsHint = text(ax, 0, 0, ...
    '[Esc] 暂停　[按住 R] 检查点重来', ...
    'HorizontalAlignment', 'right', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 8.8, ...
    'Color', [0.98, 0.98, 0.94], ...
    'BackgroundColor', [0.05, 0.11, 0.15], 'Margin', 4);
handles.pauseShade = patch(ax, nan, nan, [0.02, 0.06, 0.08], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.74, 'Visible', 'off');
handles.pauseCard = rectangle(ax, 'Position', [0, 0, 1, 1], ...
    'FaceColor', [0.98, 0.95, 0.84], 'EdgeColor', [0.45, 0.26, 0.09], ...
    'LineWidth', 2.4, 'Curvature', 0.08, 'Visible', 'off');
handles.pauseAccent = plot(ax, nan, nan, '-', ...
    'Color', [0.82, 0.45, 0.08], 'LineWidth', 2.0, 'Visible', 'off');
handles.pauseText = text(ax, 0, 0, ...
    {'游戏暂停', '两只小梨正在喘口气'}, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'FontSize', 20, 'Color', [0.09, 0.15, 0.16], 'Visible', 'off');
handles.pauseHint = text(ax, 0, 0, ...
    '[Esc] 继续游戏　 ·　 [Q] 退出本轮', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'FontSize', 11, 'Color', [0.39, 0.22, 0.08], 'Visible', 'off');

% Set stacking in two batches.  Calling uistack once per object makes the
% MATLAB web-graphics controller rebuild its child views dozens of times.
worldTopOrder = handles.rope;
for playerIndex = 1:2
    pear = handles.players(playerIndex);
    pearTopOrder = [pear.shadow; pear.stem; pear.body; ...
        pear.shade; pear.highlight; pear.speckles; pear.blush; ...
        pear.eyeWhites; pear.pupils; pear.eyeLines; pear.brows; pear.mouth; ...
        pear.badge; pear.ring];
    pearChildren = pear.transform.Children;
    pearRest = pearChildren(~ismember(pearChildren, pearTopOrder));
    pear.transform.Children = [flipud(pearTopOrder(:)); pearRest];
    worldTopOrder = [worldTopOrder; pear.transform]; %#ok<AGROW>
end
worldChildren = handles.worldTransform.Children;
worldRest = worldChildren(~ismember(worldChildren, worldTopOrder));
handles.worldTransform.Children = [flipud(worldTopOrder(:)); worldRest];
if isContinuous
    uistack(handles.lakeRailForeground,'top');
    uistack(handles.bridgeForeground.body,'top');
    uistack(handles.bridgeForeground.rail,'top');
    signal=handles.continuous;
    frontSignals=[signal.signalLabel(:);signal.signalLights(:);signal.signalHousing(:)];
    children=handles.worldTransform.Children;
    handles.worldTransform.Children=[frontSignals;children(~ismember(children,frontSignals))];
end

hudTopOrder = [handles.hudPanel; handles.hudHearts(:); handles.hudTea(:); ...
    handles.hudRopeBase; handles.hudRopeFill; handles.hudRopeLabel; ...
    handles.hud; handles.instruction; handles.checkpointText; ...
    handles.controlsHint; handles.pauseShade; handles.pauseCard; ...
    handles.pauseAccent; handles.pauseText; handles.pauseHint];
axesChildren = ax.Children;
axesRest = axesChildren(~ismember(axesChildren, hudTopOrder));
ax.Children = [flipud(hudTopOrder(:)); axesRest];
end

function tagCameraCulledObjects(objects)
for index = 1:numel(objects)
    object = objects(index);
    type = get(object, 'Type');
    switch type
        case {'line', 'patch', 'surface', 'image'}
            x = get(object, 'XData');
            x = x(isfinite(x));
            if isempty(x)
                continue;
            end
            range = [min(x(:)), max(x(:))];
        case 'rectangle'
            position = get(object, 'Position');
            range = position(1) + [0, position(3)];
        case 'text'
            position = get(object, 'Position');
            range = position(1) + [-4, 4];
        otherwise
            continue;
    end
    set(object, 'Tag', 'cameraCulledStatic', 'UserData', range);
end
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
    faceColor = [0.62, 0.62, 0.54];
    edgeColor = [0.28, 0.34, 0.29];
elseif centreX < 148
    faceColor = [0.66, 0.62, 0.53];
    edgeColor = [0.25, 0.27, 0.25];
else
    faceColor = [0.42, 0.44, 0.39];
    edgeColor = [0.24, 0.29, 0.25];
end
end

function range = activeSegmentRange(segment)
switch segment
    case 'world'
        range = [0, 176];
    case 'network'
        range = [58, 112];
    case 'traffic'
        range = [106, 148];
    case 'bicycle'
        range = [142, 176];
    otherwise
        range = [-inf, inf];
end
end

function [vertices, faces, colours] = birdPatchGeometry(kind)
theta = linspace(0, 2 * pi, 14)';
shadow = [0.50 + 0.45 * cos(theta), 0.03 + 0.045 * sin(theta)];
legs = {[.31 .08; .35 .08; .35 .23; .31 .23], ...
    [.61 .08; .65 .08; .65 .23; .61 .23]};
if strcmp(kind, 'goose')
    body = [.00 .34; .08 .72; .30 .96; .62 .93; .93 .68; 1 .34; ...
        .80 .15; .52 .10; .23 .13; .04 .23];
    wing = [.23 .47; .47 .62; .78 .49; .62 .25; .34 .24];
    neck = [.76 .48; .90 .54; .99 .78; 1.06 1.13; 1.20 1.20; ...
        1.13 .78; .99 .51; .86 .43];
    head = [1.19 + .17 * cos(theta), 1.22 + .20 * sin(theta)];
    beak = [1.31 1.29; 1.54 1.22; 1.32 1.14];
    eye = [1.27 + .035 * cos(theta), 1.27 + .045 * sin(theta)];
    polygons = [{shadow}, legs, {body, wing, neck, head, beak, eye}];
    colours = [0.72 0.69 0.60; .82 .43 .10; .82 .43 .10; ...
        .97 .97 .93; .86 .87 .82; .98 .98 .95; .98 .98 .95; ...
        .96 .55 .12; .08 .08 .07];
else
    body = [-.01 .43; .13 .78; .40 .97; .75 .82; .98 .52; .90 .20; ...
        .62 .11; .28 .14; .07 .25];
    wing = [.22 .47; .48 .68; .78 .52; .62 .24; .32 .25];
    head = [.87 + .24 * cos(theta), .82 + .34 * sin(theta)];
    beak = [1.04 .90; 1.32 .82; 1.05 .73];
    eye = [.96 + .035 * cos(theta), .91 + .045 * sin(theta)];
    polygons = [{shadow}, legs, {body, wing, head, beak, eye}];
    colours = [0.72 0.69 0.60; .83 .43 .10; .83 .43 .10; ...
        .63 .43 .26; .82 .65 .45; .18 .46 .32; .95 .64 .16; .06 .07 .06];
end
maxCorners = max(cellfun(@(polygon) size(polygon, 1), polygons));
faces = nan(numel(polygons), maxCorners);
vertices = zeros(0, 2);
for index = 1:numel(polygons)
    first = size(vertices, 1) + 1;
    vertices = [vertices; polygons{index}]; %#ok<AGROW>
    faces(index, 1:size(polygons{index}, 1)) = ...
        first:(first + size(polygons{index}, 1) - 1);
end
end

function object = createCompoundBirdPatch(ax, kind, count)
[localVertices, localFaces, localColours] = birdPatchGeometry(kind);
vertexCount = size(localVertices, 1);
faceCount = size(localFaces, 1);
vertices = repmat(localVertices, count, 1);
faces = nan(faceCount * count, size(localFaces, 2));
for index = 1:count
    rows = (index - 1) * faceCount + (1:faceCount);
    faces(rows, :) = localFaces + (index - 1) * vertexCount;
end
colours = repmat(localColours, count, 1);
metadata = struct('localVertices', localVertices, ...
    'vertexCount', vertexCount, 'birdCount', count);
object = patch(ax, 'Vertices', vertices, 'Faces', faces, ...
    'FaceVertexCData', colours, 'FaceColor', 'flat', ...
    'EdgeColor', 'none', 'Visible', 'off', 'UserData', metadata);
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
        text(ax, 45.5, 5.0, '课程原型补给点', ...
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
            stride = max(1, round(cfg.render.loginTextureStride));
            [rgb, ~, alpha] = readGameImage(cfg.assets.loginImage, stride);
            set(handles.cardImage, 'CData', flipud(rgb));
            if ~isempty(alpha)
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
        else
            positionTeaSprite(handles.bottle, bottle, ...
                cfg.tea.visualWidthMultiplier);
            set(handles.bottle, 'Visible', 'on');
        end
end
end

function handles = emptyPlayerHandles()
handles = struct('transform', gobjects(1), ...
    'shadow', gobjects(1), 'stem', gobjects(1), ...
    'body', gobjects(1), 'shade', gobjects(1), ...
    'highlight', gobjects(1), 'speckles', gobjects(1), ...
    'blush', gobjects(1), 'eyeWhites', gobjects(1), ...
    'pupils', gobjects(1), 'eyeLines', gobjects(1), ...
    'brows', gobjects(1), 'mouth', gobjects(1), ...
    'badge', gobjects(1), 'ring', gobjects(1));
end

function handles = createPear(ax, playerIndex, cfg)
handles = emptyPlayerHandles();
handles.transform = hgtransform('Parent', ax);
t = linspace(0, 2 * pi, 20);
handles.shadow = patch(ax, 0.52 * cos(t), -0.07 + 0.075 * sin(t), ...
    [0.10, 0.14, 0.15], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.20);
if playerIndex == 1
    bodyColor = cfg.presentation.colors.player1;
    outlineColor = [0.24, 0.31, 0.13];
else
    bodyColor = cfg.presentation.colors.player2;
    outlineColor = [0.36, 0.31, 0.22];
end
handles.stem = plot(ax, [0.00, 0.015, 0.045], [0.98, 1.045, 1.105], ...
    '-', 'Color', [0.38, 0.23, 0.10], ...
    'LineWidth', 3.0);
outline = pearOutline();
handles.body = patch(ax, outline(:, 1), outline(:, 2), bodyColor, ...
    'EdgeColor', outlineColor, 'LineWidth', 1.35, ...
    'LineJoin', 'round');
handles.shade = patch(ax, ...
    [0.14, 0.34, 0.42, 0.37, 0.26, 0.24, 0.24], ...
    [0.10, 0.18, 0.35, 0.54, 0.66, 0.46, 0.22], 0.72 * bodyColor, ...
    'EdgeColor', 'none', 'FaceAlpha', 0.075);
handles.highlight = patch(ax, ...
    [-0.20, -0.29, -0.22, -0.10, -0.045, -0.12, -0.12], ...
    [0.31, 0.48, 0.69, 0.84, 0.77, 0.55, 0.36], [1, 1, 1], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.095);
handles.speckles = plot(ax, [-0.25, 0.20, 0.30, -0.10, 0.17, -0.20], ...
    [0.25, 0.30, 0.40, 0.17, 0.52, 0.55], '.', ...
    'Color', 0.88 * bodyColor, 'MarkerSize', 3.2);
handles.blush = plot(ax, nan, nan, '.', 'Color', [0.93, 0.39, 0.39], ...
    'MarkerSize', 16);
handles.eyeWhites = plot(ax, [-0.17, 0.17], [0.69, 0.69], 'o', ...
    'MarkerFaceColor', [1.00, 0.98, 0.91], ...
    'MarkerEdgeColor', cfg.presentation.colors.ink, ...
    'MarkerSize', 6.4, 'LineWidth', 1.0);
handles.pupils = plot(ax, [-0.17, 0.17], [0.69, 0.69], '.', ...
    'Color', cfg.presentation.colors.ink, ...
    'MarkerSize', 11);
handles.eyeLines = plot(ax, nan, nan, '-', ...
    'Color', cfg.presentation.colors.ink, 'LineWidth', 1.8);
handles.brows = plot(ax, nan, nan, '-', ...
    'Color', cfg.presentation.colors.ink, 'LineWidth', 1.5);
handles.mouth = plot(ax, nan, nan, '-', 'Color', cfg.presentation.colors.ink, ...
    'LineWidth', 1.3);
handles.badge = plot(ax, nan, nan, 'o', ...
    'MarkerFaceColor', 'white', 'MarkerEdgeColor', cfg.presentation.colors.ink, ...
    'MarkerSize', 7, 'LineWidth', 1.2);
handles.ring = plot(ax, nan, nan, 'o', 'MarkerFaceColor', 'none', ...
    'MarkerEdgeColor', cfg.presentation.colors.ink, 'MarkerSize', 5, ...
    'LineWidth', 1.2);
ringSide = -1;
if playerIndex == 1
    ringSide = 1;
end
set(handles.ring, 'XData', ringSide * 0.46, 'YData', 0.62);
names = fieldnames(handles);
for index = 1:numel(names)
    object = handles.(names{index});
    if isgraphics(object) && object ~= handles.transform
        set(object, 'Parent', handles.transform);
    end
end
end

function handles = updatePear(handles, player, ~, ...
        ropeDirection, ropeTension, ~)
height = player.size(2);
width = player.size(1);
stretch = 1 + min(0.12, abs(player.vel(2)) * 0.009);
if player.onGround && abs(player.vel(1)) > 1.0
    stretch = 0.96;
end
squash = 1 / sqrt(stretch);
tilt = max(-0.18, min(0.18, -player.vel(1) * 0.018));
matrix = makehgtform('translate', [player.pos, 0]) * ...
    makehgtform('zrotate', tilt) * ...
    makehgtform('scale', [width * squash, height * stretch, 1]);
set(handles.transform, 'Matrix', matrix);

persistent shadowTheta
if isempty(shadowTheta)
    shadowTheta = linspace(0, 2 * pi, 20);
end
t = shadowTheta;
airHeight = max(0, min(3, player.pos(2) - 1));
shadowWidth = 0.48 + 0.06 * double(player.onGround) - 0.04 * airHeight;
set(handles.shadow, 'XData', shadowWidth * cos(t), ...
    'YData', (-0.07 - 0.03 * airHeight) / stretch + 0.075 * sin(t), ...
    'FaceAlpha', 0.24 - 0.04 * airHeight);
if isfield(player,'storyFlight') && player.storyFlight
    set(handles.shadow,'Visible','off');
else
    set(handles.shadow,'Visible','on');
end

face = pearExpressionState(player, ropeDirection, ropeTension);
faceCache = get(handles.transform, 'UserData');
faceKey = {face.name, round(1000 * face.gaze)};
if isstruct(faceCache) && isfield(faceCache, 'faceKey') && ...
        isequal(faceCache.faceKey, faceKey)
    return;
end
eyeCentresX = [-0.17, 0.17];
eyeY = 0.69;
set(handles.eyeWhites, 'XData', eyeCentresX, 'YData', [eyeY, eyeY]);
set(handles.pupils, 'XData', eyeCentresX + face.gaze(1), ...
    'YData', [eyeY, eyeY] + face.gaze(2));
set(handles.eyeLines, 'XData', nan, 'YData', nan);
set(handles.brows, 'XData', nan, 'YData', nan);
set(handles.blush, 'XData', nan, 'YData', nan);

mouthY = 0.45;
mouthX = [-0.13, -0.06, 0, 0.06, 0.13];
switch face.name
    case 'pain'
        set(handles.eyeWhites, 'XData', nan, 'YData', nan);
        set(handles.pupils, 'XData', nan, 'YData', nan);
        eyeX = [-0.25, -0.11, nan, 0.11, 0.25];
        eyeLineY = eyeY + [0.05, -0.04, nan, -0.04, 0.05];
        set(handles.eyeLines, 'XData', eyeX, 'YData', eyeLineY);
        set(handles.brows, 'XData', [-0.28, -0.11, nan, 0.11, 0.28], ...
            'YData', eyeY + [0.13, 0.08, nan, 0.08, 0.13]);
        mouthCurve = mouthY + [0.01, 0.05, 0.00, 0.05, 0.01];
    case 'pulled'
        pullSign = sign(face.gaze(1));
        if pullSign == 0
            pullSign = 1;
        end
        set(handles.brows, 'XData', [-0.27, -0.10, nan, 0.10, 0.27], ...
            'YData', eyeY + [0.11, 0.05, nan, 0.05, 0.11]);
        mouthCurve = mouthY + [0, 0.025, -0.015, 0.025, 0];
        mouthX = mouthX + 0.035 * pullSign;
    case 'joy'
        set(handles.blush, 'XData', [-0.31, 0.31], ...
            'YData', [mouthY + 0.08, mouthY + 0.08]);
        set(handles.eyeWhites, 'XData', nan, 'YData', nan);
        set(handles.pupils, 'XData', nan, 'YData', nan);
        set(handles.eyeLines, 'XData', ...
            [-0.27, -0.18, -0.09, nan, 0.09, 0.18, 0.27], ...
            'YData', eyeY + [0.00, 0.055, 0.00, nan, 0.00, 0.055, 0.00]);
        mouthX = [-0.18, -0.09, 0, 0.09, 0.18];
        mouthCurve = mouthY + [0.08, 0.005, -0.07, 0.005, 0.08];
    case 'terrified'
        set(handles.brows,'XData',[-.28 -.12 nan .12 .28], ...
            'YData',eyeY+[.14 .22 nan .22 .14]);
        mouthX=.105*cos(t);
        mouthCurve=mouthY+.15*sin(t);
    case 'surprised'
        mouthX = 0.075 * cos(t);
        mouthCurve = mouthY + 0.085 * sin(t);
    case 'playful'
        set(handles.blush, 'XData', [-0.31, 0.31], ...
            'YData', [mouthY + 0.07, mouthY + 0.07]);
        mouthCurve = mouthY + [0.025, -0.015, -0.045, -0.01, 0.04];
    otherwise
        set(handles.blush, 'XData', [-0.31, 0.31], ...
            'YData', [mouthY + 0.07, mouthY + 0.07]);
        mouthCurve = mouthY + [0.035, -0.005, -0.025, -0.005, 0.035];
end
set(handles.mouth, 'XData', mouthX, 'YData', mouthCurve);
set(handles.transform, 'UserData', struct('faceKey', {faceKey}));
end

function points = pearOutline()
sampleCount = 26;
first = cubicBezier([0.00, 0.02], [-0.23, -0.01], ...
    [-0.48, 0.13], [-0.47, 0.35], sampleCount);
second = cubicBezier([-0.47, 0.35], [-0.45, 0.59], ...
    [-0.27, 0.77], [-0.18, 0.84], sampleCount);
third = cubicBezier([-0.18, 0.84], [-0.19, 0.94], ...
    [-0.10, 1.00], [0.00, 1.00], sampleCount);
left = [first; second(2:end, :); third(2:end, :)];
right = [-flipud(left(1:end - 1, 1)), flipud(left(1:end - 1, 2))];
points = [left; right];
end

function points = cubicBezier(p0, p1, p2, p3, count)
t = linspace(0, 1, count)';
points = (1 - t) .^ 3 .* p0 + ...
    3 * (1 - t) .^ 2 .* t .* p1 + ...
    3 * (1 - t) .* t .^ 2 .* p2 + t .^ 3 .* p3;
end

function sprite = createPixelHeart(ax)
pixels = [ ...
    0, 1, 1, 0, 0, 1, 1, 0; ...
    1, 2, 2, 1, 1, 2, 2, 1; ...
    1, 3, 2, 2, 2, 2, 2, 1; ...
    1, 2, 2, 2, 2, 2, 2, 1; ...
    0, 1, 2, 2, 2, 2, 1, 0; ...
    0, 0, 1, 2, 2, 1, 0, 0; ...
    0, 0, 0, 1, 1, 0, 0, 0];
rgb = zeros(7, 8, 3, 'uint8');
palette = uint8([45, 18, 28; 231, 61, 72; 255, 151, 145]);
for value = 1:3
    mask = pixels == value;
    for channel = 1:3
        layer = rgb(:, :, channel);
        layer(mask) = palette(value, channel);
        rgb(:, :, channel) = layer;
    end
end
alpha = double(pixels > 0);
sprite = surface(ax, nan(2), nan(2), zeros(2), ...
    'CData', flipud(rgb), 'FaceColor', 'texturemap', ...
    'AlphaData', flipud(alpha), 'FaceAlpha', 'texturemap', ...
    'AlphaDataMapping', 'none', 'EdgeColor', 'none', ...
    'UserData', alpha);
end

function positionHeartSprite(sprite, rect, full)
x = rect(1) + [0, rect(3); 0, rect(3)];
y = rect(2) + [0, 0; rect(4), rect(4)];
alpha = get(sprite, 'UserData');
if full
    opacity = 1.0;
else
    opacity = 0.20;
end
set(sprite, 'XData', x, 'YData', y, ...
    'AlphaData', flipud(alpha * opacity), 'Visible', 'on');
end
