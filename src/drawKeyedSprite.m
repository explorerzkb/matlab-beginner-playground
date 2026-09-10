function handle = drawKeyedSprite(ax, rect, imagePath, stride)
%DRAWKEYEDSPRITE Display a checked colour-keyed asset without altering its file.
if nargin < 4, stride = 1; end
rgb=readGameImage(imagePath,stride);
c=double(rgb)/255;
alpha=double(~(c(:,:,1)-c(:,:,2)>0.20 & c(:,:,3)-c(:,:,2)>0.20));
spill=max(0,min(c(:,:,1),c(:,:,3))-c(:,:,2));
c(:,:,1)=c(:,:,1)-spill; c(:,:,3)=c(:,:,3)-spill;
handle=surface(ax,rect(1)+[0 rect(3);0 rect(3)], ...
    rect(2)+[0 0;rect(4) rect(4)],zeros(2), ...
    'CData',flipud(uint8(255*c)),'FaceColor','texturemap', ...
    'AlphaData',flipud(alpha),'FaceAlpha','texturemap', ...
    'AlphaDataMapping','none','EdgeColor','none');
end
