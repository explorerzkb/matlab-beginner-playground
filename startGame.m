function startGame(varargin)
%STARTGAME Launch the two-player MATLAB platform game from any folder.
%   STARTGAME() starts the interactive game.
%   STARTGAME('TestMode', true) runs a short, invisible lifecycle check.

projectRoot = fileparts(mfilename('fullpath'));
originalPath = path;
pathGuard = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));

cfg = gameConfig(projectRoot);
if mod(numel(varargin), 2) ~= 0
    error('matlabHi:InvalidArguments', ...
        '可选参数必须使用名称/值成对传入，例如 startGame(''TestMode'', true)。');
end

for index = 1:2:numel(varargin)
    name = lower(char(string(varargin{index})));
    value = varargin{index + 1};
    switch name
        case 'testmode'
            cfg.runtime.testMode = logical(value);
        case 'lowpowermode'
            cfg.runtime.lowPowerMode = logical(value);
        otherwise
            error('matlabHi:UnknownOption', '未知启动选项：%s', name);
    end
end

if cfg.runtime.lowPowerMode
    cfg.render.targetHz = 20;
end

runGame(cfg);
clear pathGuard;
end
