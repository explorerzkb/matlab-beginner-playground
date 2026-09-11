function data = posePreviewOverlayData(points, imageSize, previewSize, confidence)
%POSEPREVIEWOVERLAYDATA Mirror upper-body joints into preview coordinates.
% Display-only ordering follows mirror-left to mirror-right. Controller
% identity binding remains independent and never uses this ordering.
edges=[1 6;1 7;6 7;6 8;8 10;7 9;9 11];
empty=struct('segments',zeros(0,4),'high',zeros(0,2),'low',zeros(0,2));
data.player=repmat(empty,1,2);
if ismatrix(points), points=reshape(points,size(points,1),size(points,2),1); end
if size(points,1)~=17 || size(points,2)~=3 || numel(imageSize)<2, return; end
count=size(points,3); centres=nan(1,count);
for i=1:count
    shoulderX=points(6:7,1,i); shoulderX=shoulderX(isfinite(shoulderX));
    if ~isempty(shoulderX), centres(i)=mean(shoulderX);
    elseif isfinite(points(1,1,i)), centres(i)=points(1,1,i);
    end
end
[~,order]=sort(centres,'descend','MissingPlacement','last');
for player=1:min(2,count)
    p=points(:,:,order(player));
    xy=[previewSize(2)*(1-p(:,1)/imageSize(2)) ...
        previewSize(1)*p(:,2)/imageSize(1)];
    visible=all(isfinite(xy),2) & p(:,1)>=0 & p(:,1)<=imageSize(2) & ...
        p(:,2)>=0 & p(:,2)<=imageSize(1) & isfinite(p(:,3));
    upper=[1 6:11]; high=visible & p(:,3)>=confidence;
    highUpper=upper(high(upper)); lowUpper=upper(visible(upper) & ~high(upper));
    data.player(player).high=xy(highUpper,:);
    data.player(player).low=xy(lowUpper,:);
    usable=high(edges(:,1)) & high(edges(:,2));
    selected=edges(usable,:);
    if ~isempty(selected)
        data.player(player).segments=[xy(selected(:,1),:) xy(selected(:,2),:)];
    end
end
end
