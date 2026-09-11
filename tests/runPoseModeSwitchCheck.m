function runPoseModeSwitchCheck()
%RUNPOSEMODESWITCHCHECK Real keyboard game -> camera calibration -> keyboard.
% Timer supplies debug keys; it does not simulate successful human calibration.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root);
oldFigures=findall(groot,'Type','figure');
stage=0; previewSeen=false; restored=false; clock=tic; returnTime=NaN;
watcher=timer('ExecutionMode','fixedSpacing','Period',.25,'TimerFcn',@drive);
guard=onCleanup(@() stopWatcher(watcher)); start(watcher);
startGame;
assert(previewSeen && restored,'Mode-switch lifecycle did not complete');
camera=webcam(1); snapshot(camera); clear camera;
clear guard;
fprintf('LIVE MODE SWITCH PASSED: game -> mirrored calibration -> upright keyboard game; camera reopened\n');
fprintf('Timer supplied debug keys only; no human calibration or playthrough claim.\n');

    function drive(~,~)
        figures=findall(groot,'Type','figure');
        figures=figures(~ismember(figures,oldFigures));
        for i=1:numel(figures)
            fig=figures(i);
            if ~isappdata(fig,'inputMode'), continue; end
            if toc(clock)>120, setappdata(fig,'closeRequested',true); continue; end
            switch stage
                case 0
                    if strcmp(getappdata(fig,'inputMode'),'pose'), stage=1; continue; end
                    setappdata(fig,'pressedKeys',{'space'});
                    if toc(clock)>12
                        setappdata(fig,'pressedKeys',{});
                        setappdata(fig,'pendingKeyPresses',{'k'});
                    end
                case 1
                    if isappdata(fig,'poseSession')
                        s=getappdata(fig,'poseSession');
                        if s.packets>=5 && ~isempty(s.preview)
                            axes=findall(fig,'Type','axes');
                            previewSeen=any(strcmp(get(axes,'YDir'),'reverse'));
                            setappdata(fig,'pendingKeyPresses',{'k'}); stage=2;
                        end
                    end
                case 2
                    if strcmp(getappdata(fig,'inputMode'),'keyboard') && ~isappdata(fig,'poseSession')
                        if isnan(returnTime), returnTime=toc(clock); end
                        if toc(clock)-returnTime>2
                            axes=findall(fig,'Type','axes');
                            restored=all(strcmp(get(axes,'YDir'),'normal'));
                            setappdata(fig,'closeRequested',true);
                        end
                    end
            end
        end
    end
end

function stopWatcher(watcher)
stop(watcher); delete(watcher);
end
