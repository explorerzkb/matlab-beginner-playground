function [width,height,scale] = cameraViewport(state,cfg)
%CAMERAVIEWPORT Effective world window; HUD keeps its original screen units.
scale=1;
if isfield(state.render,'cameraScale'), scale=state.render.cameraScale; end
width=cfg.render.viewportWidth/scale;
height=cfg.render.viewportHeight/scale;
end
