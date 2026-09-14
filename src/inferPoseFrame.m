function [detections, timings] = inferPoseFrame(model, frame, cfg)
%INFERPOSEFRAME Standalone candidate comparison, not a game-loop callback.
height=size(frame,1); width=size(frame,2);
timings=zeros(1,2);
if strcmp(model.candidate,'single')
    middle=floor(width/2);
    % Fixed disjoint zones; each model sees one person, never the whole pair.
    crops=[middle 0 width-middle height; 0 0 middle height];
    detections=zeros(17,3,2);
    for i=1:2
        [input,tr]=preparePoseImage(frame,crops(i,:),model.inputSize);
        clock=tic;
        raw=predictPoseModel(model.net,cast(input,model.inputType));
        timings(i)=toc(clock);
        detections(:,:,i)=restorePoseCoordinates(reshape(raw,[17 3]),tr);
    end
else
    [input,tr]=preparePoseImage(frame,[0 0 width height],model.inputSize);
    clock=tic;
    raw=predictPoseModel(model.net,cast(input,model.inputType));
    timings(1)=toc(clock); timings(2)=NaN;
    rows=reshape(raw,[6 56]);
    rows=rows(rows(:,56)>=cfg.confidence,:);
    detections=zeros(17,3,size(rows,1));
    for i=1:size(rows,1)
        detections(:,:,i)=restorePoseCoordinates(reshape(rows(i,1:51),[3 17])',tr);
    end
end
end
