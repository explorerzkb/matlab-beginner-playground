function testPoseController()
%TESTPOSECONTROLLER Synthetic joints, NOT real-camera recognition evidence.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig(); sz=[720 1280];
pair=cat(3,person(900),person(380));
s=createPoseState();
for t=0:1/30:6, s=stepPoseController(s,pair,sz,t,cfg); end
assert(strcmp(s.phase,'active'));
assert(s.player(1).anchor(1)>s.player(2).anchor(1));
[a,cursor]=consumePoseInput(s,[],6,cfg,true);
assert(~any([a.player.left a.player.right a.player.jump]));
tilted=pair;
tilted(8,2,1)=tilted(8,2,1)-45; tilted(9,2,1)=tilted(9,2,1)+45;
tilted(8,2,2)=tilted(8,2,2)+45; tilted(9,2,2)=tilted(9,2,2)-45;
for t=6+1/30:1/30:6.5, s=stepPoseController(s,tilted,sz,t,cfg); end
[a,cursor]=consumePoseInput(s,cursor,6.5,cfg,true);
assert(a.player(1).right && a.player(2).left,'Anatomical directions reversed');
% Model detection order is not identity.
s=stepPoseController(s,tilted(:,:,[2 1]),sz,6.54,cfg);
assert(s.player(1).direction==1 && s.player(2).direction==-1);
for t=6.58:0.04:7.1, s=stepPoseController(s,pair,sz,t,cfg); end
assert(all([s.player.direction]==0));
% Loss of one person's joints releases that input during the grace interval.
loss=stepPoseController(s,pair(:,:,1),sz,7.12,cfg);
[lostInput,~]=consumePoseInput(loss,cursor,7.12,cfg,true);
assert(~lostInput.safetyPause && ~lostInput.player(2).jump && ...
    ~lostInput.player(2).left && ~lostInput.player(2).right);
% Both jump while tilting. Persistent event survives the next neutral frame.
jump=tilted; jump(:,2,:)=jump(:,2,:)-30;
s=stepPoseController(s,jump,sz,7.14,cfg);
assert(all([s.player.sequence]==1));
s=stepPoseController(s,jump,sz,7.18,cfg);
[a,cursor]=consumePoseInput(s,cursor,7.18,cfg,true);
assert(all([a.player.jump]));
[a,cursor]=consumePoseInput(s,cursor,7.19,cfg,true);
assert(~any([a.player.jump]));
for t=7.22:0.04:8, s=stepPoseController(s,pair,sz,t,cfg); end
% Raising arms, crouching and tiptoe with stationary ankles must not jump.
for kind=1:3
    falseJump=pair;
    if kind==1, falseJump(6:11,2,:)=falseJump(6:11,2,:)-30;
    elseif kind==2, falseJump(6:15,2,:)=falseJump(6:15,2,:)+30;
    else, falseJump(6:15,2,:)=falseJump(6:15,2,:)-30;
    end
    t=8+kind*0.08;
    s=stepPoseController(s,falseJump,sz,t,cfg);
    s=stepPoseController(s,pair,sz,t+0.04,cfg);
end
assert(all([s.player.sequence]==1));
% Stale and disabled input consumes events, never queues across lifecycle.
copy=s; copy.player(1).sequence=2; copy.player(1).eventTime=8.28;
[a,cursor]=consumePoseInput(copy,cursor,8.28,cfg,false);
assert(~any([a.player.jump]));
[a,~]=consumePoseInput(copy,cursor,8.30,cfg,true);
assert(~any([a.player.jump]));
[a,~]=consumePoseInput(copy,[0 0],9,cfg,true);
assert(a.safetyPause && ~any([a.player.jump a.player.left a.player.right]));
% Arms down pauses whole session after bounded grace.
down=pair; down(10:11,2,:)=570;
for t=8.32:0.04:9.2, s=stepPoseController(s,down,sz,t,cfg); end
assert(strcmp(s.phase,'paused'));
for t=9.24:0.04:13.8, s=stepPoseController(s,pair,sz,t,cfg); end
assert(strcmp(s.phase,'active') && all(isinf([s.player.eventTime])));
% Overlap is never silently re-bound.
overlap=cat(3,person(650),person(630));
s=stepPoseController(s,overlap,sz,13.84,cfg);
assert(strcmp(s.phase,'paused'));
% Exact inverse of asymmetric letterbox, same fixed-camera coordinates.
tr=struct('crop',[640 0 640 720],'input',[192 192], ...
    'resized',[192 171],'pad',[0 10]);
original=pair(:,:,1); yxs=original(:,[2 1 3]);
yxs(:,1)=(original(:,2)-tr.crop(2))/tr.crop(4)*tr.resized(1)/tr.input(1);
yxs(:,2)=((original(:,1)-tr.crop(1))/tr.crop(3)*tr.resized(2)+tr.pad(2))/tr.input(2);
restored=restorePoseCoordinates(yxs,tr);
assert(max(abs(restored-original),[],'all')<1e-9);
% A moving calibration window must not turn a squat into standing height.
unstable=createPoseState();
for t=0:0.04:3
    moving=pair; moving(:,2,:)=moving(:,2,:)+20*sin(t*8);
    unstable=stepPoseController(unstable,moving,sz,t,cfg);
end
assert(strcmp(unstable.phase,'calibrating'));
fprintf('POSE SYNTHETIC CHECKS PASSED (not human recognition/playability)\n');
end

function p=person(x)
p=[0 110; -10 100; 10 100; -20 115; 20 115; ...
    55 200; -55 200; 90 285; -90 285; 12 285; -12 285; ...
    45 410; -45 410; 45 520; -45 520; 45 650; -45 650];
p(:,1)=p(:,1)+x;
p(:,3)=0.95;
end
