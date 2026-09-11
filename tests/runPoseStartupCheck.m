function runPoseStartupCheck()
%RUNPOSESTARTUPCHECK Live camera startup and automatic exit, no human claims.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root);
observed=false; clock=tic;
watcher=timer('ExecutionMode','fixedSpacing','Period',0.5,'TimerFcn',@observe);
guard=onCleanup(@() cleanTimer(watcher)); start(watcher);
startGame('InputMode','pose');
assert(observed,'Did not receive five camera packets in calibration UI');
camera=webcam(1); snapshot(camera); clear camera;
clear guard;
fprintf('LIVE POSE STARTUP / CALIBRATION UI / AUTOMATIC EXIT / CAMERA REOPEN PASSED\n');
fprintf('No two-person calibration or human actions were performed.\n');

    function observe(~,~)
        figures=findall(groot,'Type','figure');
        for i=1:numel(figures)
            fig=figures(i);
            if ~isappdata(fig,'inputMode'), continue; end
            if isappdata(fig,'poseSession')
                session=getappdata(fig,'poseSession');
                if session.packets>=5 && ~isempty(session.preview)
                    observed=true; setappdata(fig,'closeRequested',true);
                end
                if ~isempty(session.error)
                    fprintf('STARTUP ERROR: %s\n',session.error);
                    setappdata(fig,'closeRequested',true);
                end
            end
            if toc(clock)>90, setappdata(fig,'closeRequested',true); end
        end
    end
end

function cleanTimer(watcher)
stop(watcher); delete(watcher);
end
