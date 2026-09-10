function handles=drawLakeRailForeground(ax,world,cfg)
%DRAWLAKERAILFOREGROUND Reuse the existing wood rail in front of the pears.
rgb=readGameImage(cfg.assets.northLakeWest,1);
tile=rgb(439:503,702:801,:);
c=double(tile)/255;
alpha=double(c(:,:,1)>1.02*c(:,:,2) & c(:,:,1)>1.18*c(:,:,3));
alpha(48:end,:)=0; % Only rail members, never a solid rectangle over the pear.
scaleY=12.65/size(rgb,1);
top=.15+(size(rgb,1)-439)*scaleY;
bottom=top-size(tile,1)*scaleY;
tileWidth=size(tile,2)*30/size(rgb,2);
deck=world.mechanic.animals.shortcutPlatforms;
right=deck(1)+deck(3);
starts=36:tileWidth:right;
handles=gobjects(numel(starts),1);
for i=1:numel(starts)
    x=starts(i); width=min(tileWidth,right-x);
    count=max(2,round(size(tile,2)*width/tileWidth));
    handles(i)=surface(ax,x+[0 width;0 width], ...
        [bottom bottom;top top],zeros(2),'CData',flipud(tile(:,1:count,:)), ...
        'FaceColor','texturemap','AlphaData',flipud(alpha(:,1:count)), ...
        'FaceAlpha','texturemap','AlphaDataMapping','none','EdgeColor','none', ...
        'Tag','cameraCulledLakeRail','UserData',[x x+width]);
end
end
