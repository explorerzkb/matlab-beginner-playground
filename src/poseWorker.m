function poseWorker(commands, results, cfg, fixture)
%POSEWORKER Process-owned camera/model; one reply for each requested frame.
% No images or camera handles cross into gameplay. No unbounded frame queue.
try
    model=loadPoseModel(cfg.modelPath,cfg.candidate,cfg);
    if isempty(fixture)
        camera=webcam(cfg.cameraIndex);
        camera.Resolution='640x480';
        snapshot(camera); % hardware startup is outside the first sample
    end
    send(results,struct('kind','ready'));
    while true
        request=poll(commands,5);
        if isempty(request) || strcmp(request.kind,'stop'), break; end
        capture=poseClock();
        if isempty(fixture), frame=snapshot(camera); else, frame=fixture; end
        acquired=poseClock();
        [points,inference]=inferPoseFrame(model,frame,cfg);
        packet=struct('kind','frame','requestId',request.id,'epoch',request.epoch, ...
            'captureTime',capture,'acquiredTime',acquired,'readyTime',poseClock(), ...
            'points',points,'imageSize',size(frame),'inferenceSeconds',inference);
        % Calibration can request a small preview; gameplay never transfers it.
        if request.preview
            packet.preview=imresize(frame,[180 240]);
        end
        send(results,packet);
    end
catch exception
    send(results,struct('kind','error','message',getReport(exception,'basic','hyperlinks','off')));
end
% Function-scope camera cleanup also occurs on error and cancelled future.
end
