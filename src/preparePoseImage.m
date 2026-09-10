function [input, transform] = preparePoseImage(frame, crop, inputSize)
%PREPAREPOSEIMAGE Aspect-preserving integer resize and explicit letterbox.
% crop uses zero-based [x y width height] edges in raw, unmirrored image.
validateattributes(frame,{'uint8'},{'nonempty'});
assert(size(frame,3)==3,'matlabHi:PoseImage','Expected RGB camera frame');
assert(all(crop==floor(crop)) && all(crop(1:2)>=0) && ...
    all(crop(3:4)>0) && crop(1)+crop(3)<=size(frame,2) && ...
    crop(2)+crop(4)<=size(frame,1),'matlabHi:PoseCrop','Invalid crop');
region=frame(crop(2)+(1:crop(4)),crop(1)+(1:crop(3)),:);
scale=min(inputSize./[crop(4) crop(3)]);
resized=max(1,round([crop(4) crop(3)]*scale));
pad=floor((inputSize-resized)/2);
input=zeros([inputSize 3],'uint8');
input(pad(1)+(1:resized(1)),pad(2)+(1:resized(2)),:)=imresize(region,resized);
transform=struct('crop',crop,'input',inputSize,'resized',resized,'pad',pad);
end
