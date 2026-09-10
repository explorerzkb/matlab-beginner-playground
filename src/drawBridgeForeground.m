function handles=drawBridgeForeground(ax,world,cfg)
%DRAWBRIDGEFOREGROUND Near fascia, piers and rail in front of the walkers.
deck=world.mechanic.traffic.upperBridgePlatforms(1,:);
height=(deck(2)+deck(4)-1)/((674-362)/724);
base=1-height*(1-674/724);
handles.body=drawKeyedSprite(ax,[deck(1),base,deck(3),height], ...
    cfg.assets.northLiBridge,cfg.render.backgroundTextureStride);
% The high sculptural wings are the far side. Only the near fascia/deck and
% piers occlude the route; otherwise the entire walking pear is hidden.
alpha=get(handles.body,'AlphaData');
rowsY=base+linspace(0,height,size(alpha,1));
alpha(rowsY>deck(2)+deck(4)+.65,:)=0;
set(handles.body,'AlphaData',alpha);
set(handles.body,'Tag','cameraCulledBridgeForeground', ...
    'UserData',deck(1)+[0 deck(3)]);
top=deck(2)+deck(4);
posts=deck(1):.9:deck(1)+deck(3);
xs=[posts;posts;nan(size(posts))];
ys=[repmat(top,size(posts));repmat(top+.56,size(posts));nan(size(posts))];
handles.rail=plot(ax,[deck(1),deck(1)+deck(3),nan,xs(:)'], ...
    [top+.56,top+.56,nan,ys(:)'], ...
    'Color',[.68 .70 .67],'LineWidth',1.5, ...
    'Tag','cameraCulledBridgeForeground','UserData',deck(1)+[0 deck(3)]);
end
