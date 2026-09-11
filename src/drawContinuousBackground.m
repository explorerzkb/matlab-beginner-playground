function drawContinuousBackground(ax, world, cfg)
%DRAWCONTINUOUSBACKGROUND Draw the v3 world as one continuous campus strip.

ink = cfg.presentation.colors.ink;
regions = regionRanges(world);
segment = cfg.render.activeSegment;
switch segment
    case 'world'
        viewRange = [0, 176];
    case 'network'
        viewRange = [58, 112];
    case 'traffic'
        viewRange = [106, 148];
    otherwise
        viewRange = [142, 176];
end

% One sky runs behind every chapter, including the bicycle flight pocket.
patch(ax,[0 world.worldWidth world.worldWidth 0], ...
    [-.4 -.4 cfg.render.flightCameraCeiling cfg.render.flightCameraCeiling], ...
    [.45 .71 .95],'EdgeColor','none');
% One static texture covers every altitude. Mirrored tiles join continuously;
% moving the world camera, rather than rebuilding clouds, preserves motion.
sky=readGameImage(cfg.assets.cloudSky,8);
sky=[sky fliplr(sky)];
sky=[sky;flipud(sky)];
nx=ceil(world.worldWidth/80);
ny=ceil((cfg.render.flightCameraCeiling+.4)/26.6667);
sky=repmat(sky,ny,nx);
skyImage=image(ax,'CData',sky,'XData',[0 nx*80], ...
    'YData',[-.4 ny*26.6667-.4]);
if isprop(skyImage,'Interpolation')
    skyImage.Interpolation='bilinear';
end

if strcmp(segment, 'world')
    drawMatlabOrigin(ax, regions.origin, cfg, ink);

    % North Lake uses the two checked painted plates. They intentionally
    % express a playable panorama, not a survey-accurate shoreline.
    skyPlate=struct('rgb',sky,'rect',[0 -.4 nx*80 ny*26.6667]);
    westPlate=drawTexturePlate(ax, [regions.northLake(1) - 2, 0.15, 30.0, 12.65], ...
        cfg.assets.northLakeWest, cfg.render.backgroundTextureStride,skyPlate,[]);
    drawTexturePlate(ax, [regions.northLake(1) + 24.0, 0.15, 28.4, 12.65], ...
        cfg.assets.northLakeEast, cfg.render.backgroundTextureStride,skyPlate,westPlate);
    drawSceneLabel(ax, regions.northLake(1) + 3.0, 10.8, ...
        '北湖 · 动物借道', '实体鸭鹅 / 羊驼后踢 / 孔雀弹射', cfg);
    drawAlpacaShortcut(ax, world.mechanic.animals.shortcutPlatforms, cfg);
    % The real page screenshot is a physical plane inside world coordinates.
    drawNetworkPage(ax, world.mechanic.network.pageRect, cfg.assets.loginImage, ...
        cfg.render.loginTextureStride);

page = world.mechanic.network.pageRect;
    drawPlaygroundExit(ax, [page(1) + page(3), regions.playground(2)], cfg);
    drawNorthLiBridge(ax, regions.northLiBridge, world.mechanic.traffic, cfg);
    drawBicycleJunction(ax, regions.bicycle, cfg);
end
% The museum/sports road owns a fixed west-to-east view in renderFrame.
% Do not expose the rejected side-view plate ahead of the bicycle launch.
drawContinuousGround(ax, world, viewRange);
end

function drawContinuousGround(ax, world, viewRange)
% A visible road surface follows the actual solid ground, including gaps.
for k = 1:size(world.platforms, 1)
    r = world.platforms(k, :);
    if r(2) ~= 0, continue; end
    roadEnd=world.mechanic.bus.backgroundRect(1);
    if r(1)>=roadEnd, continue; end
    if r(1) + r(3) < viewRange(1) || r(1) > viewRange(2), continue; end
    r(3)=min(r(3),roadEnd-r(1));
    if r(1) < 66
        color = [0.69, 0.63, 0.43];
    else
        color = [0.39, 0.43, 0.42];
    end
    patch(ax, r(1) + [0 r(3) r(3) 0], [1 1 1.48 1.48], ...
        color, 'EdgeColor', 'none');
    plot(ax, r(1)+[0 r(3)], [1.48 1.48], '-', ...
        'Color', [0.72 0.74 0.63], 'LineWidth', 1);
end
% Water-filled gaps are visible at the same x coordinates as the physics.
for gap = [14 1.5; 23.5 1.5; 34 2; 48 1.5; 54.5 1.5]'
    x = gap(1); w = gap(2);
    if x + w < viewRange(1) || x > viewRange(2), continue; end
    patch(ax, x+[0 w w 0], [-0.4 -0.4 1.5 1.5], ...
        [0.15 0.36 0.39], 'EdgeColor', 'none');
    plot(ax, x+[0.1 w-0.1], [0.72 0.72], '-', ...
        'Color', [0.55 0.74 0.68], 'LineWidth', 1.2);
end
end

function ranges = regionRanges(world)
for index = 1:numel(world.regions)
    ranges.(world.regions(index).id) = world.regions(index).xRange;
end
end

function drawMatlabOrigin(ax, range, cfg, ink)
patch(ax, [range(1), range(2), range(2), range(1)], ...
    [0, 0, 11.5, 11.5], [0.93, 0.97, 0.94], 'EdgeColor', 'none');
gridX = range(1) + 1:1.5:range(2) - 0.5;
verticalX = reshape([gridX; gridX; nan(size(gridX))], 1, []);
verticalY = repmat([1.0, 10.8, nan], 1, numel(gridX));
gridY = 1:1.5:10.8;
horizontalX = repmat([range(1) + 0.7, range(2) - 0.5, nan], ...
    1, numel(gridY));
horizontalY = reshape([gridY; gridY; nan(size(gridY))], 1, []);
plot(ax, [verticalX, horizontalX], [verticalY, horizontalY], ':', ...
    'Color', [0.66, 0.77, 0.71], 'LineWidth', 0.75);
plot(ax, [range(1) + 1, range(1) + 1], [1, 9.4], '-', ...
    'Color', [0.24, 0.34, 0.38], 'LineWidth', 1.8);
plot(ax, [range(1) + 0.8, range(2) - 0.8], [1, 1], '-', ...
    'Color', [0.24, 0.34, 0.38], 'LineWidth', 1.8);
text(ax, range(1) + 1.5, 10.2, 'MATLAB 坐标轴入口', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'Color', ink, 'FontSize', 14);
text(ax, range(1) + 1.5, 9.55, '从一条曲线，走进一整座校园', ...
    'FontName', cfg.render.fontName, 'Color', [0.29, 0.43, 0.36], ...
    'FontSize', 10.5);
end

function drawPlaygroundExit(ax, range, cfg)
% Match the field photograph inside the fixed webpage, including its red track.
stride=max(1,round(cfg.render.backgroundTextureStride));
rgb=readGameImage(cfg.assets.playground,stride);
backgroundSurface(ax,[range;range],[1 1;9.8 9.8],zeros(2), ...
    'CData',flipud(rgb),'FaceColor','texturemap','EdgeColor','none');
skyEdge=double(rgb(1,:,:))/255;
skyTop=repmat(mean(skyEdge,2),1,size(rgb,2),1);
blend=linspace(0,1,128)';
skyExtension=(1-blend).*skyEdge+blend.*skyTop;
backgroundSurface(ax,[range;range],[9.8 9.8;19 19],zeros(2), ...
    'CData',skyExtension, ...
    'FaceColor','texturemap','EdgeColor','none');
backgroundSurface(ax,[range;range],[-.4 -.4;1 1],zeros(2), ...
    'CData',repmat(rgb(end-8:end,:,:),8,1,1), ...
    'FaceColor','texturemap','EdgeColor','none');
for x=[90 108]
    plot(ax,x+[0 .94],[1 2.42],'-','Color',[.97 .94 .85],'LineWidth',1.4);
end
laneY=1.05+[0 .145 .30 .465 .64 .825 1.02 1.225];
for lane=1:8
    text(ax,89.45+.65*(laneY(lane)-1),laneY(lane),num2str(lane), ...
        'Color',[1 .98 .90],'FontWeight','bold','FontSize',7, ...
        'HorizontalAlignment','center');
end
plot(ax,[109.1 109.1],[2.7 4.1],'-','Color',[.30 .32 .32],'LineWidth',1.4);
for row=0:1
    for col=0:3
        color=[.98 .97 .90];
        if mod(row+col,2)==0, color=[.18 .21 .23]; end
        rectangle(ax,'Position',[109.1+col*.18,3.7+row*.18,.18,.18], ...
            'FaceColor',color,'EdgeColor','none');
    end
end
end

function drawNorthLiBridge(ax, range, traffic, cfg)
text(ax,116.2,3.1,'车道外等候','FontName',cfg.render.fontName, ...
    'FontSize',8,'Color',[.97 .97 .89],'BackgroundColor',[.12 .35 .28]);
% Checked architectural sprite shares its deck and footing with the physics.
drawGreenbelt(ax,range(1)-1,4.3,diff(range)+2,cfg);
patch(ax, [range(1), range(2), range(2), range(1)], ...
    traffic.roadRenderY([1 1 2 2]), [0.30, 0.34, 0.36], 'EdgeColor', 'none');
for laneX=traffic.laneEdges(2:end-1)
    plot(ax,[laneX laneX],traffic.roadRenderY,'--', ...
        'Color',[0.90 0.89 0.79],'LineWidth',1.2);
end
% Solid outer edges distinguish the four lanes from the waiting shoulders.
for laneX=traffic.laneEdges([1 end])
    plot(ax,[laneX laneX],traffic.roadRenderY,'-', ...
        'Color',[0.90 0.89 0.79],'LineWidth',1.2);
end
crosswalk=traffic.crosswalk;
for signalX=traffic.signalX
    plot(ax,[signalX signalX],[1 2.65],'-','Color',[.16 .20 .22],'LineWidth',3);
end
for stripeX=crosswalk(1):0.75:crosswalk(1)+crosswalk(3)-0.4
    rectangle(ax,'Position',[stripeX 0.72 0.38 3.1], ...
        'FaceColor',[0.92 0.92 0.89],'EdgeColor','none');
end
deck=traffic.upperBridgePlatforms(1,:);
% Source pixels: top of deck 362/724; common footing baseline 674/724.
height=(deck(2)+deck(4)-1)/((674-362)/724);
base=1-height*(1-674/724);
drawKeyedSprite(ax,[deck(1),base,deck(3),height], ...
    cfg.assets.northLiBridge,cfg.render.backgroundTextureStride);
text(ax,mean(deck(1)+[0 deck(3)]),7.5,'北理桥', ...
    'FontName',cfg.render.fontName,'FontWeight','bold','FontSize',13, ...
    'HorizontalAlignment','center','Color',[0.53 0.13 0.10]);
% No ladder: the upper route is reached with a tea-powered jump.
signX=deck(1)-2.4;
plot(ax,[signX signX],[1 3.35],'-','Color',[.34 .37 .32],'LineWidth',2);
rectangle(ax,'Position',[signX-1.9 3.1 3.8 1.35], ...
    'Curvature',.06,'FaceColor',[.31 .39 .30], ...
    'EdgeColor',[.57 .60 .47],'LineWidth',.8);
text(ax,signX,4.03,'大跳可上桥', ...
    'FontName',cfg.render.fontName,'FontSize',10,'FontWeight','bold', ...
    'HorizontalAlignment','center','Color',[.94 .92 .79]);
text(ax,signX,3.47,'先喝冰红茶', ...
    'FontName',cfg.render.fontName,'FontSize',8, ...
    'HorizontalAlignment','center','Color',[.85 .86 .73]);
end

function drawBicycleJunction(ax, range, cfg)
drawGreenbelt(ax,range(1)-2,1.2,28,cfg);
patch(ax, [range(1), range(2), range(2), range(1)], ...
    [-.4, -.4, 1.48, 1.48], [0.35, 0.38, 0.39], 'EdgeColor', 'none');
plot(ax, range, [.4, .4], '--', 'Color', [0.95, 0.83, 0.34], ...
    'LineWidth', 1.5);
for signX = [152.0, 160.0]
    plot(ax, [signX, signX], [1.0, 6.4], '-', ...
        'Color', [0.28, 0.30, 0.30], 'LineWidth', 3.0);
end
text(ax, 152.0, 6.65, '北食堂', 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'Color', [0.16, 0.25, 0.28], 'BackgroundColor', [0.95, 0.89, 0.65], ...
    'Margin', 4);
text(ax, 160.0, 6.65, '徐特立图书馆', 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'Color', [0.16, 0.25, 0.28], 'BackgroundColor', [0.95, 0.89, 0.65], ...
    'Margin', 4);
text(ax, 158, 9.4, '自行车 / 电动车混流路口', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 13, 'Color', [0.69, 0.12, 0.10], ...
    'BackgroundColor', [1.0, 0.92, 0.72], 'Margin', 5);
end

function drawn = drawGreenbelt(ax,x,base,width,cfg)
% Opaque source atlas uses magenta as a display-only transparency key.
% Preserve the original pixels on disk; the sprite is a background layer.
drawn=isfile(cfg.assets.greenbelt);
if ~drawn, return; end
persistent cacheKey cachedRGB cachedAlpha heightRatio
stride=max(1,round(cfg.render.backgroundTextureStride));
key=sprintf('%s:%d',cfg.assets.greenbelt,stride);
if isempty(cacheKey) || ~strcmp(cacheKey,key)
    rgb=imread(cfg.assets.greenbelt);
    rgb=rgb(1:stride:end,1:stride:end,:);
    colors=double(rgb)/255;
    alpha=~(colors(:,:,1)-colors(:,:,2)>0.15 & ...
        colors(:,:,3)-colors(:,:,2)>0.15);
    % Remove magenta spill at anti-aliased leaf edges during display.
    spill=max(0,min(colors(:,:,1),colors(:,:,3))-colors(:,:,2));
    colors(:,:,1)=colors(:,:,1)-spill;
    colors(:,:,3)=colors(:,:,3)-spill;
    rgb=uint8(255*colors);
    rows=find(any(alpha,2)); columns=find(any(alpha,1));
    if isempty(rows) || isempty(columns), drawn=false; return; end
    cachedRGB=rgb(rows(1):rows(end),columns(1):columns(end),:);
    cachedAlpha=double(alpha(rows(1):rows(end),columns(1):columns(end)));
    heightRatio=size(cachedRGB,1)/size(cachedRGB,2);
    cacheKey=key;
end
backgroundSurface(ax,x+[0 width;0 width], ...
    base+[0 0;width*heightRatio width*heightRatio], ...
    zeros(2),'CData',flipud(cachedRGB),'FaceColor','texturemap', ...
    'AlphaData',flipud(cachedAlpha),'FaceAlpha','texturemap', ...
    'AlphaDataMapping','none','EdgeColor','none');
end

function plate = drawTexturePlate(ax, rect, imagePath, stride, sky, previous)
stride = max(1, round(stride));
rgb = readGameImage(imagePath, stride);
% Bake the feather into RGB once.  A full per-pixel AlphaData plane makes
% every later camera frame pay an expensive transparency-compositing cost.
alpha = plateAlpha(size(rgb, 1), size(rgb, 2));
% Match the actual world-space clouds, not a constant blue matte. Include
% the already-composited western plate wherever the eastern one overlaps it.
[worldX,worldY]=meshgrid(linspace(rect(1),rect(1)+rect(3),size(rgb,2)), ...
    linspace(rect(2)+rect(4),rect(2),size(rgb,1)));
matte=samplePlate(sky,worldX,worldY);
if ~isempty(previous)
    under=samplePlate(previous,worldX,worldY);
    inside=isfinite(under);
    matte(inside)=under(inside);
end
rgb = uint8(double(rgb).*alpha + matte.*(1-alpha));
plate=struct('rgb',flipud(rgb),'rect',rect);
x = rect(1) + [0, rect(3); 0, rect(3)];
y = rect(2) + [0, 0; rect(4), rect(4)];
backgroundSurface(ax, x, y, zeros(2), 'CData', flipud(rgb), ...
    'FaceColor', 'texturemap', 'EdgeColor', 'none');
end

function rgb = samplePlate(plate, x, y)
% Rows run bottom-to-top, as in the image object's world coordinates.
u=1+(x-plate.rect(1))/plate.rect(3)*(size(plate.rgb,2)-1);
v=1+(y-plate.rect(2))/plate.rect(4)*(size(plate.rgb,1)-1);
% Interpolate only the covered window, not the full high-altitude sky atlas.
left=max(1,min(size(plate.rgb,2)-1,floor(min(u(:)))));
right=min(size(plate.rgb,2),max(left+1,ceil(max(u(:)))));
bottom=max(1,min(size(plate.rgb,1)-1,floor(min(v(:)))));
top=min(size(plate.rgb,1),max(bottom+1,ceil(max(v(:)))));
rgb=zeros([size(x),3]);
for channel=1:3
    rgb(:,:,channel)=interp2(double(plate.rgb(bottom:top,left:right,channel)), ...
        u-left+1,v-bottom+1,'linear',nan);
end
end

function alpha = plateAlpha(height, width)
% Spatial feathering belongs to the static scenery, never to web pages.
edge = min(1, min((0:width-1), (width-1:-1:0)) / (0.075*width));
edge = edge.^2 .* (3 - 2*edge);
alpha = repmat(edge, height, 1);
% Finish within the empty upper sky, before architecture and treetops.
top=min(1,(0:height-1)'/max(1,.16*(height-1)));
top=top.^2.*(3-2*top);
alpha=alpha.*top;
end

function drawSceneLabel(ax, x, y, titleText, kicker, cfg)
text(ax, x, y, {titleText, kicker}, 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 11.5, ...
    'Color', [0.97, 0.96, 0.88], ...
    'BackgroundColor', [0.10, 0.18, 0.16], 'Margin', 5, ...
    'VerticalAlignment', 'top');
end

function drawAlpacaShortcut(ax, platforms, cfg)
% Reuse the edited background's own wood pixels, not an unrelated red slab.
rgb=readGameImage(cfg.assets.northLakeWest,1);
tile=rgb(439:503,702:801,:);
c=double(tile)/255;
alpha=double(c(:,:,1)>1.02*c(:,:,2) & c(:,:,1)>1.18*c(:,:,3));
alpha(48:end,:)=1;
scaleY=12.65/size(rgb,1);
textureTop=0.15+(size(rgb,1)-439)*scaleY;
textureBottom=textureTop-size(tile,1)*scaleY;
tileWidth=size(tile,2)*30/size(rgb,2);
right=platforms(1)+platforms(3);
for x=36:tileWidth:right
    width=min(tileWidth,right-x);
    count=max(2,round(size(tile,2)*width/tileWidth));
    backgroundSurface(ax,x+[0 width;0 width], ...
        [textureBottom textureBottom;textureTop textureTop],zeros(2), ...
        'CData',flipud(tile(:,1:count,:)),'FaceColor','texturemap', ...
        'AlphaData',flipud(alpha(:,1:count)),'FaceAlpha','texturemap', ...
        'AlphaDataMapping','none','EdgeColor','none');
end
% Foreground supports begin after the kick corridor, leaving room to rise.
for x=[platforms(1)+3.1,56.4,63.4]
    rectangle(ax,'Position',[x-0.13 1 0.26 platforms(2)-1], ...
        'FaceColor',[0.42 0.37 0.28],'EdgeColor',[0.31 0.29 0.22]);
    rectangle(ax,'Position',[x-0.30 1 0.60 0.18], ...
        'FaceColor',[0.54 0.53 0.44],'EdgeColor','none');
end
end

function drawNetworkPage(ax, pageRect, imagePath, stride)
stride = max(1, round(stride));
rgb = readGameImage(imagePath, stride);
x = pageRect(1) + [0, pageRect(3); 0, pageRect(3)];
y = pageRect(2) + [0, 0; pageRect(4), pageRect(4)];
backgroundSurface(ax, x, y, zeros(2), 'CData', flipud(rgb), ...
    'FaceColor', 'texturemap', 'EdgeColor', 'none');
rectangle(ax, 'Position', pageRect, 'FaceColor', 'none', ...
    'EdgeColor', [0.18, 0.38, 0.58], 'LineWidth', 1.5);
end

function object = backgroundSurface(ax, x, y, z, varargin)
object = surface(ax, x, y, z, varargin{:});
set(object, 'Tag', 'cameraCulledBackground', ...
    'UserData', [min(x(:)), max(x(:))]);
end
