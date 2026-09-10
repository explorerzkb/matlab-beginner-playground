function testPoseRearmPrecision()
%TESTPOSEREARMPRECISION A rounded duration must not cost a whole camera frame.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig(); sz=[720 1280]; pair=cat(3,person(900),person(380));
template=createPoseState();
for t=0:.1:6, template=stepPoseController(template,pair,sz,t,cfg); end
for origin=[0 1789060000]
    boundary=origin+47.416666666666664;
    s=template; s.lastFrameTime=boundary-.1;
    for i=1:2
        s.player(i).jumpPhase='landing';
        s.player(i).standSince=origin+47.116666666666667;
        s.player(i).lastTime=s.lastFrameTime;
    end
    early=stepPoseController(s,pair,sz,boundary-.0001,cfg);
    assert(all(strcmp({early.player.jumpPhase},'landing')),'Actual early jump was rearmed');
    s=stepPoseController(s,pair,sz,boundary,cfg);
    assert(all(strcmp({s.player.jumpPhase},'standing')),'Rounded 0.3-second boundary missed rearm');
    jump=pair; jump(:,2,:)=jump(:,2,:)-30;
    s=stepPoseController(s,jump,sz,boundary+.1,cfg);
    assert(all([s.player.sequence]==1),'Following valid jump was lost');
end
fprintf('POSE REARM PRECISION PASSED: relative/epoch clocks, true early rejection, next jump\n');
end

function p=person(x)
p=[0 110;-10 100;10 100;-20 115;20 115;55 200;-55 200; ...
    90 285;-90 285;12 285;-12 285;45 410;-45 410;45 520;-45 520;45 650;-45 650];
p(:,1)=p(:,1)+x; p(:,3)=.95;
end
