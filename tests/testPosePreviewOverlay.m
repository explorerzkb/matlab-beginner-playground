function testPosePreviewOverlay()
%TESTPOSEPREVIEWOVERLAY Mirrored upper-body geometry and confidence display.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
right=person(500); left=person(140); left(10,3)=0.2;
points=cat(3,left,right); % Deliberately reverse display-player order.
data=posePreviewOverlayData(points,[480 640 3],[180 240],0.35);
assert(size(data.player(1).high,1)==6 && isempty(data.player(1).low));
assert(size(data.player(1).noseHigh,1)==1 && isempty(data.player(1).noseLow));
assert(size(data.player(1).segments,1)==5,'Nose was connected to the skeleton');
assert(size(data.player(2).high,1)==5 && size(data.player(2).low,1)==1);
assert(size(data.player(2).noseHigh,1)==1 && isempty(data.player(2).noseLow));
assert(size(data.player(2).segments,1)==4);
expected=[240*(1-500/640) 180*80/480];
assert(norm(data.player(1).noseHigh-expected)<1e-12, ...
    'Raw-camera point did not align with mirrored preview');
assert(data.player(1).noseHigh(1)<120 && data.player(2).noseHigh(1)>120, ...
    'Mirror-left and mirror-right display assignment was reversed');
fprintf('POSE PREVIEW OVERLAY PASSED: mirrored upper-body skeleton and low-confidence marks\n');
end

function p=person(x)
p=nan(17,3); p(:,3)=0;
p([1 6:11],:)=[x 80 .95;x+35 150 .95;x-35 150 .95; ...
    x+60 220 .95;x-60 220 .95;x+10 235 .95;x-10 235 .95];
end
