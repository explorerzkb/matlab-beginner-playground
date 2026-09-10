function [input,mode] = readFigurePose(fig,now,consume,enabled)
%READFIGUREPOSE Convert pose state; events consumed ONLY at a physics step.
mode=isgraphics(fig) && strcmp(getappdata(fig,'inputMode'),'pose');
input.player=repmat(struct('left',false,'right',false,'jump',false),1,2);
input.safetyPause=mode;
if ~mode || ~isappdata(fig,'poseSession'), return; end
session=getappdata(fig,'poseSession');
if ~isempty(session.error), return; end
[input,cursor]=consumePoseInput(session.state,session.cursor,now,session.cfg,enabled);
if consume
    session.cursor=cursor;
    setappdata(fig,'poseSession',session);
else
    for i=1:2, input.player(i).jump=false; end
end
end
