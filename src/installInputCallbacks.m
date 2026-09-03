function installInputCallbacks(fig)
%INSTALLINPUTCALLBACKS Store key state only; gameplay reads it on fixed steps.

setappdata(fig, 'pressedKeys', {});
setappdata(fig, 'closeRequested', false);
set(fig, ...
    'WindowKeyPressFcn', @keyPressed, ...
    'WindowKeyReleaseFcn', @keyReleased, ...
    'CloseRequestFcn', @closeRequested);
end

function keyPressed(src, event)
if ~isgraphics(src)
    return;
end
keys = getappdata(src, 'pressedKeys');
key = char(event.Key);
if ~any(strcmpi(keys, key))
    keys{end + 1} = key;
    setappdata(src, 'pressedKeys', keys);
end
end

function keyReleased(src, event)
if ~isgraphics(src)
    return;
end
keys = getappdata(src, 'pressedKeys');
key = char(event.Key);
keys(strcmpi(keys, key)) = [];
setappdata(src, 'pressedKeys', keys);
end

function closeRequested(src, ~)
if isgraphics(src)
    setappdata(src, 'closeRequested', true);
end
end
