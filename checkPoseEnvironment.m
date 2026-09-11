function report = checkPoseEnvironment()
%CHECKPOSEENVIRONMENT Run after MATLAB installation; does not install anything.
root=fileparts(mfilename('fullpath'));
report.version=version; report.computer=computer;
report.toolboxes=ver;
report.addons=matlab.addons.installedAddons;
report.webcamFunction=which('webcam');
report.tfliteFunction=which('loadTFLiteModel');
report.tflitePath=getenv('TFLITE_PATH');
report.backgroundPool=which('backgroundPool');
report.cameras={}; report.cameraError=''; report.interfaceError='';
try
    report.cameras=webcamlist;
catch exception
    report.cameraError=[exception.identifier ': ' exception.message];
end
try
    % Missing-package checks occur before checking the deliberately absent file.
    loadTFLiteModel(fullfile(tempdir,'matlabhi-dependency-probe-absent.tflite'));
catch exception
    report.interfaceError=[exception.identifier ': ' exception.message];
end
folder=fullfile(root,'docs','validation','pose-control');
if ~isfolder(folder), mkdir(folder); end
stamp=char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'));
save(fullfile(folder,['environment-' stamp '.mat']),'report');
fprintf('MATLAB %s (%s)\nwebcam: %s\nTFLite: %s\nTFLITE_PATH: %s\n', ...
    report.version,report.computer,report.webcamFunction, ...
    report.tfliteFunction,report.tflitePath);
disp(report.cameras);
fprintf('Camera check: %s\nInterface probe: %s\n', ...
    report.cameraError,report.interfaceError);
fprintf('An absent-model error is expected; it does NOT prove model inference.\n');
end
