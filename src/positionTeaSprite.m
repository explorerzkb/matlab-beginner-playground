function positionTeaSprite(sprite, collisionRect, widthMultiplier)
%POSITIONTEASPRITE Place the tea image with a controlled width emphasis.

if nargin < 3
    widthMultiplier = 1;
end
aspectRatio = get(sprite, 'UserData');
visualHeight = collisionRect(4);
visualWidth = visualHeight * aspectRatio * widthMultiplier;
centreX = collisionRect(1) + collisionRect(3) / 2;
left = centreX - visualWidth / 2;
bottom = collisionRect(2);

xData = [left, left + visualWidth; left, left + visualWidth];
yData = [bottom, bottom; bottom + visualHeight, bottom + visualHeight];
set(sprite, 'XData', xData, 'YData', yData);
end
