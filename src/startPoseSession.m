function session = startPoseSession(cfg, fixture)
%STARTPOSESESSION Start owned process resources before gameplay begins.
if nargin<2, fixture=[]; end
pool=gcp('nocreate'); owned=isempty(pool);
if owned
    pool=parpool('Processes',1);
elseif ~isa(pool,'parallel.ProcessPool')
    error('matlabHi:PosePool','Pose needs a process pool; existing thread pool was left untouched.');
end
try
    commands=parallel.pool.PollableDataQueue(Destination='any');
    results=parallel.pool.PollableDataQueue;
    future=parfeval(pool,@poseWorker,0,commands,results,cfg,fixture);
    session=struct('pool',pool,'ownedPool',owned,'commands',commands, ...
        'results',results,'future',future,'cfg',cfg,'state',createPoseState(), ...
        'epoch',1,'nextId',0,'inflight',false,'sentTime',-inf,'lastRequest',-inf, ...
        'ready',false,'error','','preview',[],'packets',0,'lastPacket',[], ...
        'cursor',[0 0],'previewRequested',false,'startedTime',poseClock());
catch exception
    if owned, delete(pool); end
    rethrow(exception);
end
end
