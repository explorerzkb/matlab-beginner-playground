function [rgb, map, alpha] = readGameImage(imagePath, stride)
%READGAMEIMAGE Decode and sample each unchanged runtime image once.

if nargin < 2, stride = 1; end
stride = max(1, round(stride));
persistent paths strides modified bytes rgbCache mapCache alphaCache
info = dir(imagePath);
if isempty(info) || info.isdir
    error('matlabHi:MissingImage', '找不到运行时图片：%s', imagePath);
end
normalizedPath = char(string(imagePath));
cacheIndex = find(strcmp(paths, normalizedPath) & strides == stride, 1);
unchanged = ~isempty(cacheIndex) && modified(cacheIndex) == info.datenum && ...
    bytes(cacheIndex) == info.bytes;
if unchanged
    rgb = rgbCache{cacheIndex};
    map = mapCache{cacheIndex};
    alpha = alphaCache{cacheIndex};
    return;
end

[rgb, map, alpha] = imread(normalizedPath);
rgb = rgb(1:stride:end, 1:stride:end, :);
if ~isempty(alpha), alpha = alpha(1:stride:end, 1:stride:end); end
if isempty(cacheIndex)
    cacheIndex = numel(paths) + 1;
    paths{cacheIndex} = normalizedPath;
    strides(cacheIndex) = stride;
end
modified(cacheIndex) = info.datenum;
bytes(cacheIndex) = info.bytes;
rgbCache{cacheIndex} = rgb;
mapCache{cacheIndex} = map;
alphaCache{cacheIndex} = alpha;
end
