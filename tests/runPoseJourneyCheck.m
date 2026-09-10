function report = runPoseJourneyCheck(route, strategy, sampleHz)
%RUNPOSEJOURNEYCHECK Synthetic joints at 12 Hz + 83 ms result delivery.
% Drives real physics through the real pose classifier; no image/model/human claim.
if nargin<1, route='upper'; end
if nargin<2, strategy='predictive'; end
if nargin<3, sampleHz=12; end
validateattributes(sampleHz,{'numeric'},{'scalar','positive','finite'});
sampleTicks=max(5,round(60/sampleHz));
sampleHz=60/sampleTicks; % One outstanding 83-ms result bounds throughput.
strategy=validatestring(strategy,{'predictive','reactive','full-predictive'});
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig(); pair=cat(3,person(900),person(380)); sz=[720 1280];
addpath(fullfile(root,'levels')); gameCfg=gameConfig(root); world=continuousCampusWorld();
controller=createPoseState();
for t=0:1/sampleHz:6, controller=stepPoseController(controller,pair,sz,t,cfg); end
assert(strcmp(controller.phase,'active'));
cursor=[0 0]; jumpStarted=[-inf -inf]; nextJump=[0 0];
pending=[]; dueTick=inf; failures=0; packets=0; consumed=[0 0];
lastState=[]; bodyJumps=[0 0];
try
    state=runGameplayJourney(route,0,false,'',@adapt);
catch exception
    if ~isempty(lastState), writeReport(false,lastState); end
    rethrow(exception);
end
report=writeReport(true,state);
disp(report);
fprintf('POSE JOINT JOURNEY PASSED: %s (no camera/model/human acceptance)\n',route);

    function input=adapt(wanted,game,tick,policy)
        lastState=game;
        now=6+tick/60;
        if game.stats.failures~=failures
            failures=game.stats.failures;
            session=struct('state',controller,'cursor',cursor,'epoch',1);
            session=resetPoseSession(session,false);
            controller=session.state; cursor=session.cursor;
            pending=[]; dueTick=inf;
        end
        if tick>=dueTick
            controller=stepPoseController(controller,pending.points,sz,pending.time,cfg);
            pending=[]; dueTick=inf; packets=packets+1;
        end
        if mod(tick-1,sampleTicks)==0
            assert(isempty(pending),'Fixture accumulated old frames');
            % Test driver plans ahead for capture, movement and delivery delay.
            % Prediction changes only the driver, never actual game state.
            planned=wanted;
            if ~strcmp(strategy,'reactive')
                future=game; predictionInput=wanted;
                for i=1:2, predictionInput.player(i).jump=false; end
                for horizon=1:10
                    future=stepPhysics(future,predictionInput,world,gameCfg,1/60);
                end
                planned=policy(future);
            end
            points=pair;
            for i=1:2
                % Reference steering already includes velocity feedback;
                % forecasting it again can brake before a platform edge.
                steering=wanted.player(i);
                if strcmp(strategy,'full-predictive'), steering=planned.player(i); end
                direction=double(steering.right)-double(steering.left);
                difference=180*tand(24*direction);
                points(8,2,i)=285-difference/2;
                points(9,2,i)=285+difference/2;
                if planned.player(i).jump && now>=nextJump(i) && strcmp(controller.phase,'active')
                    jumpStarted(i)=now; nextJump(i)=now+.9;
                    bodyJumps(i)=bodyJumps(i)+1;
                end
                age=now-jumpStarted(i);
                if age>=0 && age<.5
                    points(:,2,i)=points(:,2,i)-50*sin(pi*age/.5);
                end
            end
            pending=struct('points',points,'time',now); dueTick=tick+5;
        end
        [pose,cursor]=consumePoseInput(controller,cursor,now,cfg,true);
        consumed=consumed+double([pose.player.jump]);
        input=wanted; input.player=pose.player; input.safetyPause=pose.safetyPause;
    end

    function result=writeReport(completed,game)
        result=struct('route',route,'strategy',strategy,'completed',completed, ...
            'poseHz',sampleHz,'deliveryDelaySeconds',5/60,'packets',packets, ...
            'syntheticBodyJumps',bodyJumps,'classifiedJumps',[controller.player.sequence], ...
            'consumedJumps',consumed,'gameSeconds',game.levelTime, ...
            'failures',game.stats.failures,'syntheticJointsOnly',true);
        stamp=char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'));
        save(fullfile(root,'docs','validation','pose-control', ...
            ['joint-journey-',strategy,'-',route,'-',stamp,'.mat']),'result');
        fprintf('JOINT FIXTURE completed=%d | body jumps %d/%d | classified %d/%d | consumed %d/%d\n', ...
            completed,bodyJumps,[controller.player.sequence],consumed);
    end
end

function p=person(x)
p=[0 110;-10 100;10 100;-20 115;20 115;55 200;-55 200; ...
    90 285;-90 285;12 285;-12 285;45 410;-45 410;45 520;-45 520;45 650;-45 650];
p(:,1)=p(:,1)+x; p(:,3)=.95;
end
