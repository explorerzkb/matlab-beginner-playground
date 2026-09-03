function runSmokeTests()
%RUNSMOKETESTS Execute data, physics, mechanics, and lifecycle checks.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'tests'));

fprintf('Running level-data checks...\n');
testLevelData();
fprintf('Running input-mapping checks...\n');
testInputMappings();
fprintf('Running physics and mechanic checks...\n');
testPhysics();
fprintf('Running invisible four-level lifecycle check...\n');
figuresBefore = findall(groot, 'Type', 'figure');
startGame('TestMode', true);
figuresAfter = findall(groot, 'Type', 'figure');
assert(numel(figuresAfter) == numel(figuresBefore), ...
    'Test-mode game left a figure or callback lifecycle behind.');
fprintf('ALL MATLAB SMOKE TESTS PASSED\n');
end
