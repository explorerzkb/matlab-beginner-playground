function savePoseTelemetry(session)
%SAVEPOSETELEMETRY Software timing only, not exposure-to-monitor latency.
if ~isfield(session,'telemetry'), return; end
root=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(root,'pose-validation-results');
try
    if ~isfolder(folder), mkdir(folder); end
    stamp=char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'));
    report=session.telemetry;
    report.error=session.error;
    report.names={'north-lake','network-race','traffic','bicycle','campus'};
    duration=report.lastCapture-report.firstCapture;
    report.captureCallHz=NaN; report.perPlayerPoseHz=[NaN NaN];
    report.inferenceCallHz=NaN;
    if duration>0
        % First-to-last span has N-1 intervals; includes inactive UI periods.
        report.captureCallHz=(report.packets-1)/duration;
        report.perPlayerPoseHz=report.captureCallHz*report.validUpdates/max(1,report.packets);
        report.inferenceCallHz=report.captureCallHz*report.inferenceCalls/max(1,report.packets);
    end
    report.notes=['Capture-call rate is not hardware exposure FPS. Per-player rates ', ...
        'are fixed raw-camera ROI valid keypoint rates, not identity accuracy. ', ...
        'Scene metrics exclude paused gameplay. Capture-to-render ends after drawnow; ', ...
        'it excludes unknown exposure and monitor presentation delays. ', ...
        'Samples measure fresh packet use, not measured physical action response.'];
    save(fullfile(folder,['pose-',stamp,'.mat']),'report');
    fprintf('POSE TELEMETRY: %s | capture %.2f Hz | ROI poses %.2f / %.2f Hz\n', ...
        folder,report.captureCallHz,report.perPlayerPoseHz);
catch exception
    warning('matlabHi:PoseTelemetry','Cannot save pose timing: %s',exception.message);
end
end
