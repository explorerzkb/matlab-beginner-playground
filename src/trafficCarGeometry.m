function [vertices,faces,colours] = trafficCarGeometry(rects,directions)
%TRAFFICCARGEOMETRY Batched front/rear cars: glass, hood, lamps and wheels.
persistent base face palette shade
if isempty(base)
    base=zeros(0,2); face=zeros(0,4);
    parts=[.06 .06 .88 .87; .17 .43 .66 .45; .21 .49 .58 .30; ...
        .12 .10 .76 .22; .14 .03 .72 .09; .09 .20 .19 .10; ...
        .72 .20 .19 .10; .32 .09 .36 .05; .01 .08 .08 .27; ...
        .91 .08 .08 .27; .01 .56 .08 .22; .91 .56 .08 .22; ...
        .20 .84 .60 .04; .25 .55 .035 .23; .11 .41 .08 .055; .81 .41 .08 .055];
    shade=[1 1 1; .15 .22 .26; .38 .62 .74; .8 .8 .8; .2 .24 .27; ...
        1 .94 .69; 1 .94 .69; .08 .12 .14; .1 .12 .14; .1 .12 .14; ...
        .1 .12 .14; .1 .12 .14; .9 .92 .93; .75 .86 .9; .3 .32 .34; .3 .32 .34];
    for k=1:size(parts,1)
        r=parts(k,:); base=[base;r(1)+[0;r(3);r(3);0],r(2)+[0;0;r(4);r(4)]]; %#ok<AGROW>
        face=[face;(k-1)*4+(1:4)]; %#ok<AGROW>
    end
    palette=[.78 .24 .20;.84 .86 .88;.15 .32 .5;.3 .35 .4;.72 .60 .38];
end
n=size(rects,1); nv=size(base,1); nf=size(face,1);
vertices=zeros(n*nv,2);faces=zeros(n*nf,4);colours=zeros(n*nf,3);
for k=1:n
    local=base; c=shade; body=palette(mod(k-1,5)+1,:);
    c(1,:)=body;c(4,:)=body*.8;
    if directions(k)<0
        local(:,2)=1-local(:,2);c(6:7,:)=repmat([.95 .13 .10],2,1);
    end
    vertices((k-1)*nv+(1:nv),:)=local.*rects(k,3:4)+rects(k,1:2);
    faces((k-1)*nf+(1:nf),:)=face+(k-1)*nv;
    colours((k-1)*nf+(1:nf),:)=c;
end
end
