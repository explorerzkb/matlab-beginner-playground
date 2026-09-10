function report = runKeyboardRolloverCheck(cfg, secondsPerCombination)
%RUNKEYBOARDROLLOVERCHECK Exercise the exact 4/5-key gameplay combinations.

if nargin < 2
    secondsPerCombination = 8;
end
combinations = rolloverCombinations(cfg.input);
passed = false(1, numel(combinations));
peakCounts = zeros(1, numel(combinations));
aborted = false;

fig = figure('Name', '双人多键冲突检查', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Color', [0.08, 0.12, 0.15], ...
    'Position', [120, 120, 820, 470]);
guard = onCleanup(@() closeFigure(fig));
ax = axes(fig, 'Position', [0.06, 0.08, 0.88, 0.84]);
axis(ax, [0, 1, 0, 1]);
axis(ax, 'off');
installInputCallbacks(fig);
titleHandle = text(ax, 0.5, 0.86, '', 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', 'FontSize', 21, ...
    'Color', [0.96, 0.98, 0.96]);
instructionHandle = text(ax, 0.5, 0.61, '', 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', 'FontSize', 17, ...
    'Color', [1.00, 0.82, 0.27]);
detectedHandle = text(ax, 0.5, 0.39, '', 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontSize', 13, ...
    'Color', [0.74, 0.82, 0.86]);
statusHandle = text(ax, 0.5, 0.20, '', 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontSize', 13, ...
    'Color', [0.74, 0.82, 0.86]);

for index = 1:numel(combinations)
    required = combinations(index).keys;
    stableTime = 0;
    previous = tic;
    stageClock = tic;
    while toc(stageClock) < secondsPerCombination && isgraphics(fig)
        drawnow;
        if getappdata(fig, 'closeRequested')
            aborted = true;
            break;
        end
        nowDelta = toc(previous);
        previous = tic;
        keys = currentKeys(fig);
        matches = all(cellfun(@(key) any(strcmpi(keys, key)), required));
        if matches
            stableTime = stableTime + nowDelta;
        else
            stableTime = 0;
        end
        peakCounts(index) = max(peakCounts(index), ...
            sum(cellfun(@(key) any(strcmpi(keys, key)), required)));
        remaining = max(0, ceil(secondsPerCombination - toc(stageClock)));
        set(titleHandle, 'String', sprintf('多键检查 %d / %d', ...
            index, numel(combinations)));
        set(instructionHandle, 'String', combinations(index).label);
        set(detectedHandle, 'String', sprintf('当前识别：%s', keyList(keys)));
        set(statusHandle, 'String', sprintf('请同时按住 0.25 秒 · 剩余 %d 秒', remaining));
        if stableTime >= 0.25
            passed(index) = true;
            set(statusHandle, 'String', '✓ 这组按键全部被识别', ...
                'Color', cfg.presentation.colors.safe, 'FontWeight', 'bold');
            drawnow;
            pause(0.45);
            set(statusHandle, 'Color', [0.74, 0.82, 0.86], 'FontWeight', 'normal');
            break;
        end
        pause(0.01);
    end
    if aborted
        break;
    end
end

report.labels = {combinations.label};
report.requiredKeys = {combinations.keys};
report.passed = passed;
report.peakRecognized = peakCounts;
report.allPassed = all(passed);
fprintf('\nKEYBOARD ROLLOVER CHECK\n');
for index = 1:numel(combinations)
    outcome = 'FAIL';
    if passed(index)
        outcome = 'PASS';
    end
    fprintf('%-4s %s | recognized %d/%d\n', outcome, ...
        combinations(index).label, peakCounts(index), numel(combinations(index).keys));
end
fprintf('KEYBOARD ROLLOVER OVERALL: %s\n\n', passLabel(report.allPassed));

if isgraphics(fig) && ~aborted
    set(titleHandle, 'String', '多键检查完成');
    set(instructionHandle, 'String', sprintf('结果：%s (%d / %d)', ...
        passLabel(report.allPassed), sum(passed), numel(passed)));
    set(detectedHandle, 'String', '结果已写入 MATLAB 命令窗口和 Windows 验收日志。');
    set(statusHandle, 'String', '关闭这个窗口继续。');
    set(fig, 'CloseRequestFcn', @(src, ~) uiresume(src));
    uiwait(fig);
end
clear guard;
end

function combinations = rolloverCombinations(input)
combinations = struct( ...
    'label', { ...
        '主键位：P1 左跳 + P2 左跳', ...
        '主键位：P1 右跳 + P2 右跳', ...
        '备用键位：P1 左跳 + P2 左跳', ...
        '备用键位：P1 右跳 + P2 右跳', ...
        '主键位：双人右跳 + Space', ...
        '备用键位：双人右跳 + Space'}, ...
    'keys', { ...
        {input.player1.left, input.player1.jump, input.player2.left, input.player2.jump}, ...
        {input.player1.right, input.player1.jump, input.player2.right, input.player2.jump}, ...
        {input.player1.left, input.player1.jump, input.player2Alternate.left, input.player2Alternate.jump}, ...
        {input.player1.right, input.player1.jump, input.player2Alternate.right, input.player2Alternate.jump}, ...
        {input.player1.right, input.player1.jump, input.player2.right, input.player2.jump, input.useItem}, ...
        {input.player1.right, input.player1.jump, input.player2Alternate.right, input.player2Alternate.jump, input.useItem}});
end

function keys = currentKeys(fig)
keys = {};
if isgraphics(fig) && isappdata(fig, 'pressedKeys')
    keys = getappdata(fig, 'pressedKeys');
end
end

function value = keyList(keys)
if isempty(keys)
    value = '（无）';
else
    value = strjoin(upper(string(keys)), ' + ');
end
end

function value = passLabel(passed)
if passed
    value = 'PASS';
else
    value = 'FAIL';
end
end

function closeFigure(fig)
if isgraphics(fig)
    delete(fig);
end
end
