function runWindowsPlaytest(scaleLabel, plannedRoute, keyMode, sessionLabel)
%RUNWINDOWSPLAYTEST Record one labelled two-person Windows playthrough.

projectRoot = fileparts(mfilename('fullpath'));
if nargin < 1 || strlength(string(scaleLabel)) == 0
    scaleLabel = questdlg('当前 Windows 显示缩放是多少？', ...
        '真人整局验收', '100%', '125%', '150%', '100%');
end
if isempty(scaleLabel), return; end
if nargin < 2 || strlength(string(plannedRoute)) == 0
    choice = questdlg('本局计划走哪条交通路线？', ...
        '真人整局验收', '北理桥', '红绿灯', '北理桥');
    if isempty(choice), return; end
    if strcmp(choice, '北理桥'), plannedRoute = 'upper'; else, plannedRoute = 'lower'; end
end
if nargin < 3 || strlength(string(keyMode)) == 0
    choice = questdlg('玩家二本局使用哪套键位？', ...
        '真人整局验收', '方向键', 'J / L / I', '方向键');
    if isempty(choice), return; end
    if strcmp(choice, '方向键'), keyMode = 'primary'; else, keyMode = 'alternate'; end
end
if nargin < 4 || strlength(string(sessionLabel)) == 0
    answer = inputdlg('给本局写一个简短编号，例如 1、2、3：', ...
        '真人整局验收', [1, 45], ...
        {char(datetime('now', 'Format', 'yyyyMMdd-HHmmss'))});
    if isempty(answer), return; end
    sessionLabel = answer{1};
end
twoPerson = strcmp(questdlg('现在是否有两名真人共同操作？', ...
    '真人整局验收', '是', '否', '否'), '是');
if ~twoPerson
    errordlg('这项验收必须由两名真人共同操作，本局不启动。', '真人整局验收');
    return;
end

scaleLabel = validateChoice(scaleLabel, {'100%', '125%', '150%'}, '显示缩放');
plannedRoute = validateChoice(lower(string(plannedRoute)), ...
    {'upper', 'lower'}, '路线');
keyMode = validateChoice(lower(string(keyMode)), ...
    {'primary', 'alternate'}, '玩家二键位');

startGame('ValidationMode', true, 'ValidationScale', scaleLabel, ...
    'ValidationRoute', plannedRoute, 'ValidationKeys', keyMode, ...
    'ValidationSession', sessionLabel, 'ValidationTwoPerson', true);

visualPass = strcmp(questdlg('两人是否都确认画面清楚、文字可读？', ...
    '本局人工确认', '是', '否', '否'), '是');
controlPass = strcmp(questdlg('两人是否都确认操作响应正常、没有明显漏键？', ...
    '本局人工确认', '是', '否', '否'), '是');
writeHumanReview(projectRoot, scaleLabel, plannedRoute, keyMode, ...
    char(string(sessionLabel)), visualPass, controlPass);
summarizeWindowsValidation(projectRoot);
end

function value = validateChoice(value, allowed, label)
value = char(string(value));
if ~any(strcmp(value, allowed))
    error('matlabHi:InvalidValidationChoice', ...
        '%s必须是：%s。', label, strjoin(allowed, ' / '));
end
end

function writeHumanReview(projectRoot, scaleLabel, route, keys, session, visual, control)
folder = fullfile(projectRoot, 'windows-validation-results');
if ~isfolder(folder), mkdir(folder); end
stamp = char(datetime('now', 'Format', 'yyyyMMdd-HHmmss-SSS'));
path = fullfile(folder, ['human-', stamp, '.txt']);
file = fopen(path, 'w');
if file < 0, error('matlabHi:TelemetryWriteFailed', '无法写入：%s', path); end
guard = onCleanup(@() fclose(file));
fprintf(file, 'MATLABHI HUMAN PLAYTEST REVIEW\n');
fprintf(file, 'Time: %s\nComputer: %s\nispc: %d\n', ...
    char(datetime('now')), computer, ispc);
fprintf(file, 'Scale: %s\nPlanned route: %s\nPlayer 2 keys: %s\n', ...
    scaleLabel, route, keys);
fprintf(file, 'Session label: %s\nTwo-person session: 1\n', session);
fprintf(file, 'Visual readability confirmed: %d\n', visual);
fprintf(file, 'Control response confirmed: %d\n', control);
fprintf('HUMAN REVIEW LOG: %s\n', path);
clear guard;
end
