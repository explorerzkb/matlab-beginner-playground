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
testPixelRectToWorld();
fprintf('Running input-mapping checks...\n');
testInputMappings();
fprintf('Running shared physics and state checks...\n');
testPhysics();
testPearExpressions();
testMovingPlatform();
testContinuousWorld();
testBreakSystem();
testConsumables();
testTeaPickups();
testCheckpointReset();
fprintf('Running North Lake checks...\n');
testWorldAnimals();
testAlpacaShortcut();
fprintf('Running campus-network checks...\n');
testNetworkPixelLayout();
testNetworkCheckpoint();
testNetworkCredentials();
testNetworkLogin();
testNetworkElevator();
testNetworkRecharge();
fprintf('Running traffic checks...\n');
testFountainLaunch();
testTrafficRoutes();
testTrafficSignal();
testTrafficCars();
testTrafficCrowd();
testTrafficTraversal();
fprintf('Running Lexue and Lucy checks...\n');
testLexuePixelLayout();
testLexueCountdown();
testLexueControlReachability();
testLexueStartButton();
testLexueCheckpoint();
testLexueTasks();
testLucyRiver();
fprintf('Running invisible continuous-world lifecycle check...\n');
figuresBefore = findall(groot, 'Type', 'figure');
startGame('TestMode', true);
figuresAfter = findall(groot, 'Type', 'figure');
assert(numel(figuresAfter) == numel(figuresBefore), ...
    'Test-mode game left a figure or callback lifecycle behind.');
fprintf('ALL MATLAB SMOKE TESTS PASSED\n');
end
