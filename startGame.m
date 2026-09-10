function startGame(varargin)
%STARTGAME Launch the two-player MATLAB platform game from any folder.
%   STARTGAME() starts the interactive game.
%   STARTGAME('TestMode', true) runs a short, invisible lifecycle check.
%   STARTGAME('ValidationMode', true) shows live FPS and saves a session log.

projectRoot = fileparts(mfilename('fullpath'));
originalPath = path;
pathGuard = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
cfg.pose = poseConfig();
cfg.pose.modelPath = fullfile(projectRoot,'assets','game','models','movenet-single-lightning.tflite');
if mod(numel(varargin), 2) ~= 0
    error('matlabHi:InvalidArguments', ...
        '可选参数必须使用名称/值成对传入，例如 startGame(''TestMode'', true)。');
end

for index = 1:2:numel(varargin)
    name = lower(char(string(varargin{index})));
    value = varargin{index + 1};
    switch name
        case 'inputmode'
            cfg.input.mode=validatestring(char(string(value)),{'keyboard','pose'});
        case 'posemodel'
            cfg.pose.modelPath=char(string(value));
        case 'testmode'
            cfg.runtime.testMode = logical(value);
        case 'lowpowermode'
            cfg.runtime.lowPowerMode = logical(value);
        case 'validationmode'
            cfg.runtime.validationMode = logical(value);
        case 'validationscale'
            cfg.runtime.validationScale = char(string(value));
        case 'validationroute'
            cfg.runtime.validationPlannedRoute = lower(char(string(value)));
        case 'validationkeys'
            cfg.runtime.validationPlayer2Keys = lower(char(string(value)));
        case 'validationsession'
            cfg.runtime.validationSessionLabel = char(string(value));
        case 'validationtwoperson'
            cfg.runtime.validationTwoPerson = logical(value);
        otherwise
            error('matlabHi:UnknownOption', '未知启动选项：%s', name);
    end
end

if strcmp(cfg.input.mode,'pose')
    cfg.render.targetHz=cfg.pose.renderHz;
end
if ~cfg.runtime.lowPowerMode
    cfg.render.windowSize = [1280 720];
    cfg.render.backgroundTextureStride = 2;
end

runGame(cfg);
clear pathGuard;
end
