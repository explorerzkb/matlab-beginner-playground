function report = runPoseModelChecks(singlePath,multiPath,samplePath)
%RUNPOSEMODELCHECKS Public still-image inference and paired-composite timing.
% The pair is two copies of ONE public person, not actual two-person quality.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'));
cfg=poseConfig(); source=imread(samplePath);
frame=[source source];
paths={singlePath,multiPath}; names={'single','multi'};
report=struct();
for c=1:2
    model=loadPoseModel(paths{c},names{c},cfg);
    for warm=1:5, inferPoseFrame(model,frame,cfg); end
    elapsed=zeros(1,30); inference=zeros(30,2);
    for i=1:30
        clock=tic; [p,inference(i,:)]=inferPoseFrame(model,frame,cfg);
        elapsed(i)=toc(clock);
    end
    assert(size(p,3)==2,'Expected two instances on public duplicated-person fixture');
    [~,order]=sort(squeeze(mean(p(6:7,1,:),1)));
    p=p(:,:,order);
    assert(all(p(1,3,:)>0.35),'Expected confident noses');
    % Coarse independently observed public-image positions, not model output.
    for person=1:2
        local=p(:,:,person); local(:,1)=local(:,1)-(person-1)*size(source,2);
        assert(abs(local(1,1)/size(source,2)-0.46)<0.1);
        assert(abs(local(1,2)/size(source,1)-0.42)<0.1);
        assert(all(local(6:7,3)>0.35),'Expected confident shoulders');
        assert(all(local(6:7,1)>0 & local(6:7,1)<size(source,2)));
        assert(all(local(6:7,2)>0 & local(6:7,2)<size(source,1)));
    end
    report.(names{c})=struct('pairMedianMs',1000*median(elapsed), ...
        'pairMaxMs',1000*max(elapsed),'perPlayerUpdateCeilingHz',1/mean(elapsed), ...
        'inferenceSeconds',inference,'elapsed',elapsed,'keypoints',p);
    fprintf('%s paired still: %.1f ms median / %.1f max; per-player ceiling %.2f Hz\n', ...
        names{c},1000*median(elapsed),1000*max(elapsed),1/mean(elapsed));
end
folder=fullfile(root,'docs','validation','pose-control');
save(fullfile(folder,'model-comparison.mat'),'report');
fprintf('PUBLIC COMPOSITE CHECKS PASSED; not live two-person accuracy or E2E latency.\n');
end
