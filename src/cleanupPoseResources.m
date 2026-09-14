function cleanupPoseResources(fig,~)
%CLEANUPPOSERESOURCES Also runs during direct figure deletion, before appdata dies.
stopFigurePose(fig);
gameFrameWait('close');
end
