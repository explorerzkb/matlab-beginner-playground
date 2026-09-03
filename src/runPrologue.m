function continueGame = runPrologue(fig, ax, cfg)
%RUNPROLOGUE Animate two MATLAB data points falling into the game world.

continueGame = false;
cla(ax);
hold(ax, 'on');
set(ax, 'Color', [0.95, 0.98, 1.00], 'XGrid', 'on', 'YGrid', 'on', ...
    'GridAlpha', 0.28, 'FontName', cfg.render.fontName);
xlim(ax, [0, 12]);
ylim(ax, [-3, 8]);
x = linspace(0.5, 11.5, 160);
y = 2.2 + 1.2 * sin(0.75 * x) + 0.13 * x;
plot(ax, x, y, '-', 'Color', cfg.presentation.colors.uiBlue, ...
    'LineWidth', 2.2);
point1 = plot(ax, 3.5, interp1(x, y, 3.5), 'o', ...
    'MarkerSize', 12, 'MarkerFaceColor', cfg.presentation.colors.player1, ...
    'MarkerEdgeColor', cfg.presentation.colors.ink);
point2 = plot(ax, 7.8, interp1(x, y, 7.8), 'd', ...
    'MarkerSize', 12, 'MarkerFaceColor', cfg.presentation.colors.player2, ...
    'MarkerEdgeColor', cfg.presentation.colors.ink);
message = text(ax, 6, 7.1, '两个数据点，怎么掉出坐标轴了？', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 18, ...
    'Color', cfg.presentation.colors.ink);
controls = text(ax, 6, -2.35, ...
    {cfg.input.player1.label, cfg.input.player2.label}, ...
    'HorizontalAlignment', 'center', 'FontName', cfg.render.fontName, ...
    'FontSize', 13, 'Color', cfg.presentation.colors.ink);

clock = tic;
while toc(clock) < cfg.runtime.prologueDuration && isgraphics(fig)
    if getappdata(fig, 'closeRequested')
        return;
    end
    elapsed = toc(clock);
    fall = max(0, elapsed - 1.4);
    bounce = 0.12 * sin(9 * elapsed) * exp(-0.45 * fall);
    y1 = interp1(x, y, 3.5) - 1.18 * fall.^1.35 + bounce;
    y2 = interp1(x, y, 7.8) - 1.08 * fall.^1.35 - bounce;
    y1 = max(-1.1, y1);
    y2 = max(-1.1, y2);
    set(point1, 'YData', y1, 'MarkerSize', 12 + min(18, 3 * fall));
    set(point2, 'YData', y2, 'MarkerSize', 12 + min(18, 3 * fall));
    if elapsed > 4.2
        set(message, 'String', '数据点长成了两只小梨——绳拉直后，动作会传给对方。');
    end
    if elapsed > 7.0
        set(controls, 'Color', cfg.presentation.colors.safe, ...
            'FontWeight', 'bold');
    end
    drawnow limitrate;
    pause(0.01);
end
continueGame = true;
end
