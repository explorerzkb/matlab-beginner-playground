function report = runPosePrototype(modelPath, candidate, duration)
%RUNPOSEPROTOTYPE Independent MATLAB webcam/MoveNet check, no game physics.
% runPosePrototype('E:/.../3.tflite','single',60)
% This sequential prototype measures its own acquisition rate, NOT camera
% hardware FPS or background execution suitability. Raw images are not saved.
if nargin<2, candidate='single'; end
if nargin<3, duration=60; end
validateattributes(duration,{'numeric'},{'scalar','positive','finite'});
root=fileparts(mfilename('fullpath')); oldPath=path;
pathGuard=onCleanup(@() path(oldPath));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig();
if isempty(which('webcam'))
    error('matlabHi:PoseDependency','Install MATLAB Support Package for USB Webcams.');
end
model=loadPoseModel(modelPath,candidate,cfg);
camera=webcam(cfg.cameraIndex);
fig=figure('Name','独立体感小样（尚非游戏验收）','NumberTitle','off');
guard=onCleanup(@() closePreview(fig));
ax=axes(fig); frame=snapshot(camera);
preview=image(ax,frame(:,end:-1:1,:)); axis(ax,'image'); hold(ax,'on');
width=size(frame,2); height=size(frame,1);
plot(ax,[width/2 width/2],[0 height],'y--');
text(ax,width*.25,30,'玩家一：镜像左','Color','yellow','HorizontalAlignment','center');
text(ax,width*.75,30,'玩家二：镜像右','Color','yellow','HorizontalAlignment','center');
plot(ax,[0 width],[height*.1 height*.1],'y:');
plot(ax,[0 width],[height*.95 height*.95],'y:');
joints=plot(ax,NaN,NaN,'g.','MarkerSize',12);
state=createPoseState(); clock=tic; cursor=[]; n=0; seen=zeros(1,2); events=zeros(1,2);
samples=zeros(0,6);
while isgraphics(fig) && toc(clock)<duration
    captureStart=toc(clock); frame=snapshot(camera); captureEnd=toc(clock);
    [detections,timings]=inferPoseFrame(model,frame,cfg);
    state=stepPoseController(state,detections,size(frame),captureStart,cfg);
    ready=toc(clock);
    [input,cursor]=consumePoseInput(state,cursor,ready,cfg,true);
    n=n+1; seen=seen+double([state.player.valid]); events=events+double([input.player.jump]);
    samples(n,:)=[captureStart captureEnd ready timings double(input.safetyPause)];
    if ~isgraphics(fig), break; end
    set(preview,'CData',frame(:,end:-1:1,:));
    x=reshape(detections(:,1,:),[],1); y=reshape(detections(:,2,:),[],1);
    set(joints,'XData',width-x,'YData',y);
    title(ax,sprintf('%s | %s | 方向 %d / %d | 跳 %d / %d', ...
        state.phase,state.reason,state.player(1).direction,state.player(2).direction,events));
    drawnow;
end
elapsed=toc(clock);
report=struct('candidate',candidate,'model',modelPath,'elapsed',elapsed, ...
    'acquiredFrames',n,'acquisitionHz',n/elapsed,'validUpdatesHz',seen/elapsed, ...
    'events',events,'samples',samples,'humanAccepted',false);
folder=fullfile(root,'docs','validation','pose-control');
if ~isfolder(folder), mkdir(folder); end
save(fullfile(folder,['prototype-' char(datetime('now','Format','yyyyMMdd-HHmmss-SSS')) '.mat']),'report');
fprintf('Acquisition %.2f Hz; valid player updates %.2f / %.2f Hz.\n', ...
    report.acquisitionHz,report.validUpdatesHz);
fprintf('Not hardware camera FPS, game FPS, or exposure-to-display latency.\n');
clear camera guard pathGuard;
end

function closePreview(fig)
if isgraphics(fig), delete(fig); end
end
