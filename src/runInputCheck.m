function continueGame = runInputCheck(fig, ax, cfg)
%RUNINPUTCHECK Five-second visible two-player keyboard recognition check.

continueGame = false;
cla(ax);
axis(ax, [0, 1, 0, 1]);
axis(ax, 'off');
set(ax, 'Color', [0.94, 0.97, 0.98]);
titleText = text(ax, 0.5, 0.86, '双人按键检测 · 5 秒', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 24, ...
    'Color', cfg.presentation.colors.ink);
p1Text = text(ax, 0.23, 0.55, cfg.input.player1.label, ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'FontSize', 15, 'Color', cfg.presentation.colors.muted);
p2Text = text(ax, 0.77, 0.55, {cfg.input.player2.label, ...
    cfg.input.player2Alternate.label}, 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontSize', 15, ...
    'Color', cfg.presentation.colors.muted);
simultaneousText = text(ax, 0.5, 0.30, '请两人同时按住各自任意一个移动键', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'FontSize', 14, 'Color', cfg.presentation.colors.ink);
itemText = text(ax, 0.5, 0.20, '共享道具：长按 Space 饮用冰红茶', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'FontSize', 12, 'Color', cfg.presentation.colors.muted);
hint = text(ax, 0.5, 0.10, 'Esc 暂停 · 按住 R 0.8 秒重来 · Q 退出', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'Color', cfg.presentation.colors.muted); %#ok<NASGU>

seenP1 = false;
seenP2 = false;
seenTogether = false;
seenItem = false;
clock = tic;
while toc(clock) < cfg.runtime.inputCheckDuration && isgraphics(fig)
    if getappdata(fig, 'closeRequested')
        return;
    end
    input = readInputSnapshot(fig, cfg.input);
    if input.quit
        return;
    end
    p1Active = input.player(1).left || input.player(1).right || input.player(1).jump;
    p2Active = input.player(2).left || input.player(2).right || input.player(2).jump;
    seenP1 = seenP1 || p1Active;
    seenP2 = seenP2 || p2Active;
    seenTogether = seenTogether || (p1Active && p2Active);
    seenItem = seenItem || input.useItem;
    set(p1Text, 'Color', statusColor(seenP1, cfg), ...
        'String', appendStatus(cfg.input.player1.label, seenP1));
    set(p2Text, 'Color', statusColor(seenP2, cfg), ...
        'String', {appendStatus(cfg.input.player2.label, seenP2), ...
        cfg.input.player2Alternate.label});
    if seenTogether
        set(simultaneousText, 'String', '✓ 已识别双人同时输入', ...
            'Color', cfg.presentation.colors.safe, 'FontWeight', 'bold');
    end
    set(itemText, 'Color', statusColor(seenItem, cfg), ...
        'String', appendStatus('共享道具：长按 Space 饮用冰红茶', seenItem));
    remaining = ceil(cfg.runtime.inputCheckDuration - toc(clock));
    set(titleText, 'String', sprintf('双人按键检测 · %d 秒', max(0, remaining)));
    drawnow limitrate;
    pause(0.01);
end
continueGame = true;
end

function value = appendStatus(label, passed)
if passed
    value = [label, '  ✓'];
else
    value = [label, '  等待输入'];
end
end

function color = statusColor(passed, cfg)
if passed
    color = cfg.presentation.colors.safe;
else
    color = cfg.presentation.colors.muted;
end
end
