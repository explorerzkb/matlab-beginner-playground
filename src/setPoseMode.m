function setPoseMode(fig,cfg,mode)
%SETPOSEMODE A mode switch clears all old actions and owns resource startup.
stopFigurePose(fig);
setappdata(fig,'inputMode',mode);
setappdata(fig,'pressedKeys',{});
setappdata(fig,'pendingKeyPresses',{});
setappdata(fig,'poseError','');
if strcmp(mode,'pose')
    try
        session=startPoseSession(cfg.pose);
        setappdata(fig,'poseSession',session);
    catch exception
        setappdata(fig,'poseError',exception.message);
    end
end
end
