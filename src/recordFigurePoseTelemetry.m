function recordFigurePoseTelemetry(fig,action,now,value)
%RECORDFIGUREPOSETELEMETRY Account only real interactive physics/draw calls.
if ~isgraphics(fig) || ~isappdata(fig,'poseSession'), return; end
s=getappdata(fig,'poseSession');
if ~isfield(s,'telemetry'), return; end
if strcmp(action,'physics')
    value=[];
    if ~isempty(s.lastPacket) && s.lastPacket.epoch==s.epoch && ...
            now-s.lastPacket.captureTime<=s.cfg.staleSeconds && ...
            strcmp(s.state.phase,'active') && isempty(s.error)
        value=s.lastPacket;
    end
end
s.telemetry=poseTelemetry(s.telemetry,action,now,value);
setappdata(fig,'poseSession',s);
end
