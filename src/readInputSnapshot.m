function input = readInputSnapshot(fig, mappings)
%READINPUTSNAPSHOT Convert the current pressed-key set into game actions.

if ~isgraphics(fig)
    keys = {};
else
    keys = getappdata(fig, 'pressedKeys');
    if isempty(keys)
        keys = {};
    end
    pending = getappdata(fig, 'pendingKeyPresses');
    if ~isempty(pending)
        keys = unique([keys, pending], 'stable');
        setappdata(fig, 'pendingKeyPresses', {});
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
input.toggleMode = hasKey(keys,mappings.toggleMode);
input.recalibrate = hasKey(keys,mappings.recalibrate);
if isgraphics(fig) && isappdata(fig,'poseSession')
    session=getappdata(fig,'poseSession');
    session=pollPoseSession(session,poseClock());
    setappdata(fig,'poseSession',session);
    if ~isempty(session.error)
        % Fatal worker errors end the session; input remains safely paused.
        setappdata(fig,'poseError',session.error);
        stopFigurePose(fig);
    end
end
[pose,input.poseMode]=readFigurePose(fig,poseClock(),false,true);
input.safetyPause=pose.safetyPause;
if input.poseMode, input.player=pose.player; end
if isgraphics(fig) && isequal(getappdata(fig,'suppressItemUntilRelease'),true)
    if ~input.useItem
        setappdata(fig,'suppressItemUntilRelease',false);
    end
    input.useItem=false;
end
end

function actions = playerActions(keys, mapping)
actions.left = hasKey(keys, mapping.left);
actions.right = hasKey(keys, mapping.right);
actions.jump = hasKey(keys, mapping.jump);
end

function tf = hasKey(keys, key)
tf = any(strcmpi(keys, char(key)));
end
