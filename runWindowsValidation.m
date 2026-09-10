function runWindowsValidation(scaleLabel)
%RUNWINDOWSVALIDATION Collect repeatable target-PC performance/input evidence.

projectRoot = fileparts(mfilename('fullpath'));
originalPath = path;
pathGuard = onCleanup(@() path(originalPath));
addpath(projectRoot);
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'tests'));

if nargin < 1 || strlength(string(scaleLabel)) == 0
    scaleLabel = questdlg('当前 Windows 显示缩放是多少？', ...
        'Windows 验收', '100%', '125%', '150%', '100%');
    if isempty(scaleLabel)
        scaleLabel = '未记录';
    end
end

resultFolder = fullfile(projectRoot, 'windows-validation-results');
if ~isfolder(resultFolder)
    mkdir(resultFolder);
end
stamp = char(datetime('now', 'Format', 'yyyyMMdd-HHmmss'));
logPath = fullfile(resultFolder, ['validation-', stamp, '.txt']);
diary(logPath);
diaryGuard = onCleanup(@() diary('off'));

screenSize = get(groot, 'ScreenSize');
screenPpi = get(groot, 'ScreenPixelsPerInch');
fprintf('MATLABHI WINDOWS VALIDATION\n');
fprintf('Time: %s\n', char(datetime('now')));
fprintf('MATLAB: %s\n', version);
fprintf('Computer: %s\n', computer);
fprintf('ispc: %d\n', ispc);
fprintf('Reported display scaling: %s\n', char(string(scaleLabel)));
fprintf('MATLAB screen: %.0f x %.0f px | %.1f pixels/inch\n\n', ...
    screenSize(3), screenSize(4), screenPpi);
if ~ispc
    fprintf('WARNING: This run is not target-Windows evidence.\n\n');
end

failures = strings(5, 1);
failureCount = 0;
try
    runCodeChecks();
    runSmokeTests();
    testContinuousPrologue();
    runEndToEndChecks();
    runPacedRenderCheck();
catch err
    failureCount = failureCount + 1;
    failures(failureCount) = "automatic: " + string(err.message);
    fprintf(2, 'AUTOMATIC CHECK FAILED\n%s\n\n', getReport(err, 'extended'));
end

fps = nan(1, 3);
for session = 1:3
    fprintf('\nPERFORMANCE SESSION %d / 3\n', session);
    try
        fps(session) = runPerformanceCheck();
    catch err
        failureCount = failureCount + 1;
        failures(failureCount) = "performance " + session + ": " + ...
            string(err.message);
        fprintf(2, 'PERFORMANCE SESSION %d FAILED\n%s\n', ...
            session, getReport(err, 'extended'));
    end
end

cfg = gameConfig(projectRoot);
try
    rollover = runKeyboardRolloverCheck(cfg);
    if ~rollover.allPassed
        failureCount = failureCount + 1;
        failures(failureCount) = ...
            "keyboard rollover: one or more combinations failed";
    end
catch err
    failureCount = failureCount + 1;
    failures(failureCount) = "keyboard rollover: " + string(err.message);
    fprintf(2, 'KEYBOARD CHECK FAILED\n%s\n', getReport(err, 'extended'));
end

fprintf('\nVALIDATION SUMMARY\n');
fprintf('Scale label: %s\n', char(string(scaleLabel)));
fprintf('Three minimum FPS results: %.1f / %.1f / %.1f\n', fps);
if failureCount == 0
    fprintf('AUTOMATIC PERFORMANCE AND KEYBOARD CHECKS: PASS\n');
else
    fprintf(2, 'CHECKS WITH FAILURES: %d\n', failureCount);
    for index = 1:failureCount
        fprintf(2, '- %s\n', failures(index));
    end
end
fprintf(['Next: run runWindowsPlaytest for the labelled two-person ', ...
    'full playthrough at this scaling. Repeat after changing Windows ', ...
    'scaling to 100%%, 125%%, and 150%%.\n']);
fprintf('Saved log: %s\n', logPath);

clear diaryGuard;
summarizeWindowsValidation(projectRoot);
clear pathGuard;
if usejava('desktop')
    msgbox(sprintf(['自动检查已结束。\n日志：%s\n\n', ...
        '接下来运行 runWindowsPlaytest 完成带路线、键位和人工确认记录的真人双人整局。'], ...
        logPath), '验收日志');
end
end
