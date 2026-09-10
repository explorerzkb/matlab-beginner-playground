function captureTrafficLaneSnapshots(outputFolder)
%CAPTURETRAFFICLANESNAPSHOTS Review all four lanes and the normal camera.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
if nargin<1
    outputFolder=fullfile(root,'docs','visuals','traffic-road-bounds','lanes');
end
if ~isfolder(outputFolder),mkdir(outputFolder);end
world=continuousCampusWorld();
for shot=1:3
    cfg=gameConfig(root);cfg.runtime.testMode=true;
    names={'all-four-lanes','left-lanes','right-lanes'};
    centres=[134 124 143];
    if shot==1
        cfg.render.viewportWidth=40;
        cfg.render.viewportHeight=15;
        cfg.render.windowSize=[1440 640];
    end
    state=createInitialState(world,cfg,[]);
    state.players(1).pos=[146 1];state.players(2).pos=[147.3 6.5];
    state=stepLevel(state,world,cfg,0);
    state.levelState.network.authenticated=true;
    state.levelState.network.pageMode='success';
    state.checkpointIndex=4;
    state.render.cameraCentre=centres(shot);
    state.render.cameraCentreY=cfg.render.viewportHeight/2-.4;
    fig=figure('Visible','off','Position',[50 50 cfg.render.windowSize]);
    guard=onCleanup(@() close(fig));
    ax=axes(fig,'Position',[.025 .04 .95 .92]);
    renderFrame(fig,ax,state,world,cfg);
    drawnow;
    exportgraphics(fig,fullfile(outputFolder,[names{shot} '.png']),'Resolution',120);
    clear guard;
end
end
