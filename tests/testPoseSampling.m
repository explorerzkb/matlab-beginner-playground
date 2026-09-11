function testPoseSampling(which)
%TESTPOSESAMPLING Missing samples cannot imply a held pose or retained turn.
if nargin<1, which='all'; end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig(); sz=[720 1280];
pair=cat(3,person(900),person(380));
if any(strcmp(which,{'all','calibration'}))
    s=createPoseState();
    for t=[0 .08 .16 2.8], s=stepPoseController(s,pair,sz,t,cfg); end
    assert(strcmp(s.phase,'calibrating'),'Missing camera time counted as stable calibration');
    for t=2.88:.08:5.44, s=stepPoseController(s,pair,sz,t,cfg); end
    assert(strcmp(s.phase,'countdown'),'Continuous observations did not calibrate');
end
if any(strcmp(which,{'all','direction'}))
    s=createPoseState();
    for t=0:.08:6, s=stepPoseController(s,pair,sz,t,cfg); end
    signs=[1 -1]; dt=.16; alpha=1-exp(-dt/cfg.smoothingSeconds);
    target=(-8-(1-alpha)*18)/alpha;
    tilt=pair;
    for i=1:2
        s.player(i).direction=signs(i); s.player(i).angle=18*signs(i);
        difference=180*tand(target*signs(i));
        tilt(8,2,i)=285-difference/2; tilt(9,2,i)=285+difference/2;
    end
    s=stepPoseController(s,tilt,sz,6+dt,cfg);
    assert(all(abs([s.player.angle])>cfg.exitDegrees & ...
        abs([s.player.angle])<cfg.enterDegrees),'Fixture missed opposite neutral band');
    assert(all([s.player.direction]==0),'Skipped neutral sample retained the wrong direction');
end
fprintf('POSE SAMPLING PASSED: %s (synthetic timing/angles, not human accuracy)\n',which);
end

function p=person(x)
p=[0 110;-10 100;10 100;-20 115;20 115;55 200;-55 200; ...
    90 285;-90 285;12 285;-12 285;45 410;-45 410;45 520;-45 520;45 650;-45 650];
p(:,1)=p(:,1)+x; p(:,3)=.95;
end
