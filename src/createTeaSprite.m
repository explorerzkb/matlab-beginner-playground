function sprite = createTeaSprite(ax, imagePath, stride, style)
%CREATETEASPRITE Build the one allowed iced-tea visual from the user image.

% The stored source remains unchanged. The transparent PNG can be sampled at
% low resolution because the pickup is only a few dozen screen pixels.

if nargin < 3
    stride = 1;
end
if nargin < 4
    style = struct();
end
stride = max(1, round(stride));
style = applyStyleDefaults(style);

[rgb, alpha, aspectRatio] = preparedTeaTexture( ...
    imagePath, stride, style);

sprite = surface(ax, nan(2), nan(2), zeros(2), ...
    'CData', flipud(rgb), 'FaceColor', 'texturemap', ...
    'AlphaData', flipud(alpha), 'FaceAlpha', 'texturemap', ...
    'AlphaDataMapping', 'none', 'EdgeColor', 'none', 'Visible', 'off', ...
    'UserData', aspectRatio);
end

function [rgb, alpha, aspectRatio] = preparedTeaTexture(imagePath, stride, style)
% One game scene contains several identical tea surfaces. Decode and style
% each resolution once; every surface may safely share the immutable arrays.
persistent cacheKeys cacheRgb cacheAlpha cacheAspect
key = sprintf('%s|%d|%.5g|%.5g|%.5g|%.5g|%.5g|%.5g|%.5g', imagePath, stride, ...
    style.capWidthMultiplier, style.capHeightMultiplier, ...
    style.outlineColor, style.outlineAlpha, style.outlineRadiusPixels);
if isempty(cacheKeys)
    cacheKeys = {};
    cacheRgb = {};
    cacheAlpha = {};
    cacheAspect = [];
end
cacheIndex = find(strcmp(cacheKeys, key), 1);
if ~isempty(cacheIndex)
    rgb = cacheRgb{cacheIndex};
    alpha = cacheAlpha{cacheIndex};
    aspectRatio = cacheAspect(cacheIndex);
    return;
end

[rgb, ~, alpha] = imread(imagePath);
if isempty(alpha)
    alpha = ones(size(rgb, 1), size(rgb, 2));
else
    alpha = double(alpha) / double(intmax(class(alpha)));
end
visiblePixels = alpha > 0.01;
if any(visiblePixels(:))
    rows = find(any(visiblePixels, 2));
    columns = find(any(visiblePixels, 1));
    padding = 4;
    rowRange = max(1, rows(1) - padding):min(size(rgb, 1), rows(end) + padding);
    columnRange = max(1, columns(1) - padding): ...
        min(size(rgb, 2), columns(end) + padding);
    rgb = rgb(rowRange, columnRange, :);
    alpha = alpha(rowRange, columnRange);
end
[rgb, alpha] = enlargeCap(rgb, alpha, ...
    style.capWidthMultiplier, style.capHeightMultiplier);
rgb = rgb(1:stride:end, 1:stride:end, :);
alpha = alpha(1:stride:end, 1:stride:end);
[rgb, alpha] = addSoftOutline(rgb, alpha, style.outlineColor, ...
    style.outlineAlpha, style.outlineRadiusPixels);

aspectRatio = size(rgb, 2) / size(rgb, 1);
cacheKeys{end + 1} = key;
cacheRgb{end + 1} = rgb;
cacheAlpha{end + 1} = alpha;
cacheAspect(end + 1) = aspectRatio;
end

function style = applyStyleDefaults(style)
defaults = struct( ...
    'capWidthMultiplier', 1, ...
    'capHeightMultiplier', 1, ...
    'outlineColor', [0.30, 0.14, 0.40], ...
    'outlineAlpha', 0, ...
    'outlineRadiusPixels', 1);
names = fieldnames(defaults);
for index = 1:numel(names)
    name = names{index};
    if ~isfield(style, name)
        style.(name) = defaults.(name);
    end
end
end

function [rgb, alpha] = enlargeCap(rgb, alpha, widthScale, heightScale)
if widthScale <= 1 && heightScale <= 1
    return;
end

imageHeight = size(alpha, 1);
imageWidth = size(alpha, 2);
capEnd = min(imageHeight, max(1, round(0.115 * imageHeight)));
capMask = alpha(1:capEnd, :) > 0.01;
if ~any(capMask(:))
    return;
end

rows = find(any(capMask, 2));
columns = find(any(capMask, 1));
capRgb = rgb(rows(1):rows(end), columns(1):columns(end), :);
capAlpha = alpha(rows(1):rows(end), columns(1):columns(end));
newHeight = max(1, round(size(capRgb, 1) * heightScale));
newWidth = max(1, round(size(capRgb, 2) * widthScale));
rowMap = round(linspace(1, size(capRgb, 1), newHeight));
columnMap = round(linspace(1, size(capRgb, 2), newWidth));
capRgb = capRgb(rowMap, columnMap, :);
capAlpha = capAlpha(rowMap, columnMap);

alpha(1:capEnd, :) = 0;
targetTop = rows(1);
targetLeft = round((imageWidth - newWidth) / 2) + 1;
targetRows = targetTop:min(imageHeight, targetTop + newHeight - 1);
targetColumns = max(1, targetLeft):min(imageWidth, targetLeft + newWidth - 1);
sourceRows = 1:numel(targetRows);
sourceColumns = 1:numel(targetColumns);
sourceAlpha = capAlpha(sourceRows, sourceColumns);
sourceMask = sourceAlpha > 0;
for channel = 1:3
    target = rgb(targetRows, targetColumns, channel);
    source = capRgb(sourceRows, sourceColumns, channel);
    target(sourceMask) = source(sourceMask);
    rgb(targetRows, targetColumns, channel) = target;
end
targetAlpha = alpha(targetRows, targetColumns);
targetAlpha(sourceMask) = max(targetAlpha(sourceMask), sourceAlpha(sourceMask));
alpha(targetRows, targetColumns) = targetAlpha;
end

function [rgb, alpha] = addSoftOutline(rgb, alpha, color, opacity, radius)
radius = max(0, round(radius));
opacity = max(0, min(1, opacity));
if radius == 0 || opacity == 0
    return;
end

padding = radius + 1;
imageHeight = size(alpha, 1);
imageWidth = size(alpha, 2);
paddedRgb = zeros(imageHeight + 2 * padding, ...
    imageWidth + 2 * padding, 3, 'uint8');
paddedAlpha = zeros(imageHeight + 2 * padding, imageWidth + 2 * padding);
rows = padding + (1:imageHeight);
columns = padding + (1:imageWidth);
paddedRgb(rows, columns, :) = rgb;
paddedAlpha(rows, columns) = alpha;

solidMask = paddedAlpha > 0.08;
kernel = ones(2 * radius + 1);
outlineMask = conv2(double(solidMask), kernel, 'same') > 0 & ~solidMask;
for channel = 1:3
    layer = paddedRgb(:, :, channel);
    layer(outlineMask) = uint8(round(255 * color(channel)));
    paddedRgb(:, :, channel) = layer;
end
paddedAlpha(outlineMask) = max(paddedAlpha(outlineMask), opacity);
rgb = paddedRgb;
alpha = paddedAlpha;
end
