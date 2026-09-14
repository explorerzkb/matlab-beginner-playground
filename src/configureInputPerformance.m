function cfg = configureInputPerformance(cfg)
%CONFIGUREINPUTPERFORMANCE Select pacing and texture cost for one input mode.
if strcmp(cfg.input.mode,'pose')
    cfg.render.targetHz=cfg.pose.renderHz;
    if cfg.runtime.lowPowerMode
        cfg.render.backgroundTextureStride=max( ...
            cfg.render.backgroundTextureStride, ...
            cfg.pose.backgroundTextureStride);
        cfg.render.campusHandscrollTextureStride=max( ...
            cfg.render.campusHandscrollTextureStride, ...
            cfg.pose.campusHandscrollTextureStride);
    end
else
    cfg.render.targetHz=50;
end
end
