function input = readInputSnapshot(fig, mappings)
%READINPUTSNAPSHOT Convert the current pressed-key set into game actions.

if ~isgraphics(fig)
    keys = {};
else
    keys = getappdata(fig, 'pressedKeys');
    if isempty(keys)
        keys = {};
    end
end

input.rawKeys = keys;
input.player(1) = playerActions(keys, mappings.player1);
primary = playerActions(keys, mappings.player2);
alternate = playerActions(keys, mappings.player2Alternate);
input.player(2).left = primary.left || alternate.left;
input.player(2).right = primary.right || alternate.right;
input.player(2).jump = primary.jump || alternate.jump;
input.pause = hasKey(keys, mappings.pause);
input.reset = hasKey(keys, mappings.reset);
input.quit = hasKey(keys, mappings.quit);
input.useItem = hasKey(keys, mappings.useItem);
end

function actions = playerActions(keys, mapping)
actions.left = hasKey(keys, mapping.left);
actions.right = hasKey(keys, mapping.right);
actions.jump = hasKey(keys, mapping.jump);
end

function tf = hasKey(keys, key)
tf = any(strcmpi(keys, char(key)));
end
