function worldRects = pixelRectToWorld(pageRect, pixelRects, pixelSize)
%PIXELRECTTOWORLD Map top-left image pixels with one uniform page scale.
% pageRect and returned rows use [x, y, width, height] in world coordinates.
% pixelRects use zero-based [left, top, width, height] image-edge pixels.

if numel(pageRect) ~= 4 || numel(pixelSize) ~= 2 || ...
        size(pixelRects, 2) ~= 4
    error('matlabHi:InvalidPixelMapping', ...
        '页面、像素框和图片尺寸的列数不正确。');
end
if any(pageRect(3:4) <= 0) || any(pixelSize <= 0) || ...
        any(pixelRects(:, 3:4) <= 0, 'all')
    error('matlabHi:InvalidPixelMapping', ...
        '页面和像素框的宽高必须为正数。');
end

scaleX = pageRect(3) / pixelSize(1);
scaleY = pageRect(4) / pixelSize(2);
if abs(scaleX - scaleY) > 1e-10
    error('matlabHi:NonUniformPageScale', ...
        '页面必须等比例缩放，不能分别拉伸横向和纵向。');
end
if any(pixelRects(:, 1:2) < 0, 'all') || ...
        any(pixelRects(:, 1) + pixelRects(:, 3) > pixelSize(1)) || ...
        any(pixelRects(:, 2) + pixelRects(:, 4) > pixelSize(2))
    error('matlabHi:PixelRectOutsidePage', ...
        '像素框超出了原图边界。');
end

worldRects = zeros(size(pixelRects));
worldRects(:, 1) = pageRect(1) + pixelRects(:, 1) * scaleX;
worldRects(:, 2) = pageRect(2) + ...
    (pixelSize(2) - pixelRects(:, 2) - pixelRects(:, 4)) * scaleX;
worldRects(:, 3:4) = pixelRects(:, 3:4) * scaleX;
end
