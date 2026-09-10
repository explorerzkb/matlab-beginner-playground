function testBridgeOcclusion()
%TESTBRIDGEOCCLUSION Pixel evidence of bridge piers and near rails covering pears.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=gameConfig(root); world=continuousCampusWorld();
folder=fullfile(root,'docs','visuals','playability-v30');
if ~isfolder(folder), mkdir(folder); end
fig=figure('Visible','off','Position',[50 50 cfg.render.windowSize]);
guard=onCleanup(@() delete(fig)); ax=axes(fig,'Position',[.045 .08 .92 .86]);
for position=[118.2 1;120 6.5]'
    s=createInitialState(world,cfg,[]);
    s.players(1).pos=position'; s.players(2).pos=position'+[1.6 0];
    s=stepLevel(s,world,cfg,0); s.render.cameraCentre=122;
    s=renderFrame(fig,ax,s,world,cfg); drawnow;
    h=s.render.handles;
    order=h.worldTransform.Children;
    assert(find(order==h.bridgeForeground.body)<find(order==h.players(1).transform));
    assert(find(order==h.bridgeForeground.rail)<find(order==h.players(1).transform));
    f=getframe(fig); front=f.cdata;
    imwrite(front,fullfile(folder,sprintf('bridge-front-y%.2f.png',position(2))));
    set([h.bridgeForeground.body h.bridgeForeground.rail],'Visible','off');
    drawnow; f=getframe(fig); behind=f.cdata;
    imwrite(behind,fullfile(folder,sprintf('bridge-no-occlusion-y%.2f.png',position(2))));
    point=h.worldTransform.Matrix*[position;0;1];
    px=ax.Position(1)+ax.Position(3)*point(1)/cfg.render.viewportWidth;
    py=ax.Position(2)+ax.Position(4)*point(2)/cfg.render.viewportHeight;
    w=size(front,2); height=size(front,1);
    col=round(px*w); row=round((1-py)*height);
    patchA=double(front(max(1,row-85):min(height,row),max(1,col-40):min(w,col+40),:));
    patchB=double(behind(max(1,row-85):min(height,row),max(1,col-40):min(w,col+40),:));
    assert(nnz(max(abs(patchA-patchB),[],3)>20)>30, ...
        'Foreground does not actually cover the pear pixels.');
end
clear guard;
fprintf('BRIDGE OCCLUSION PASSED: pier and near rail pixel comparisons\n');
end
