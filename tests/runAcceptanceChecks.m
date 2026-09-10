function runAcceptanceChecks(outputFolder)
%RUNACCEPTANCECHECKS Repeat the development-machine gate with a saved log.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'tests'));
if nargin<1, outputFolder=fullfile(root,'docs','visuals','acceptance-v5'); end
folder=outputFolder;
if ~isfolder(folder), mkdir(folder); end
logPath=fullfile(folder,'latest-run.txt');
if isfile(logPath), delete(logPath); end
diary(logPath);
guard=onCleanup(@() diary('off'));
fprintf('MATLAB %s | %s | %s\n',version,computer,char(datetime('now')));
runCodeChecks();
runSmokeTests();
testContinuousPrologue();
runEndToEndChecks();
runPerformanceCheck();
runPacedRenderCheck();
fprintf('DEVELOPMENT-MACHINE ACCEPTANCE PASSED. WINDOWS/HUMAN CHECKS NOT INCLUDED.\n');
clear guard;
end
