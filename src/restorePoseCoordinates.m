function points = restorePoseCoordinates(yxs, transform)
%RESTOREPOSECOORDINATES Undo exact resize/pad/crop into raw camera pixels.
% transform: crop=[x y width height] (zero-based edges), resized=[h w],
% input=[h w], pad=[top left]. Joint labels always remain anatomical.
% Mirroring is preview-only, AFTER this conversion. Never mirror the model.
validateattributes(yxs, {'numeric'}, {'2d','ncols',3,'finite'});
points = double(yxs(:,[2 1 3]));
points(:,1) = (points(:,1)*transform.input(2)-transform.pad(2)) ...
    *transform.crop(3)/transform.resized(2)+transform.crop(1);
points(:,2) = (points(:,2)*transform.input(1)-transform.pad(1)) ...
    *transform.crop(4)/transform.resized(1)+transform.crop(2);
end
