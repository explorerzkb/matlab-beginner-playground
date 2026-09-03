function cleanupGame(fig)
%CLEANUPGAME Remove callbacks and close the game figure without leftovers.

if nargin < 1 || isempty(fig) || ~isgraphics(fig)
    return;
end
set(fig, ...
    'WindowKeyPressFcn', '', ...
    'WindowKeyReleaseFcn', '', ...
    'CloseRequestFcn', '');
if isappdata(fig, 'pressedKeys')
    rmappdata(fig, 'pressedKeys');
end
if isappdata(fig, 'closeRequested')
    rmappdata(fig, 'closeRequested');
end
delete(fig);
end
