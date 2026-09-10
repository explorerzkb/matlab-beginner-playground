function restartRequested = showResults(fig, ax, stats, cfg)
%SHOWRESULTS Plot the session's actual trajectories as MATLAB curves.

restartRequested = false;
cla(ax);
hold(ax, 'on');
set(ax, 'Color', [0.97, 0.98, 0.96], 'XGrid', 'on', 'YGrid', 'on', ...
    'GridAlpha', 0.35, 'FontName', cfg.render.fontName);
if ~isempty(stats.trajectory)
    plot(ax, stats.trajectory(:, 3), stats.trajectory(:, 4), '-', ...
        'Color', cfg.presentation.colors.player1, 'LineWidth', 2.2);
    plot(ax, stats.trajectory(:, 5), stats.trajectory(:, 6), '-', ...
        'Color', cfg.presentation.colors.player2, 'LineWidth', 2.2);
end
xlabel(ax, '连续校园世界 x');
ylabel(ax, '连续校园世界 y');
title(ax, '本局真实轨迹重新成为 MATLAB 曲线', ...
    'FontName', cfg.render.fontName, 'FontSize', 18);
legend(ax, {'香梨绿', '鸭梨白'}, 'Location', 'best');
summary = sprintf(['总用时 %.1f 秒\n共同复活 %d 次 · 累计失去爱心 %d\n' ...
    '冰红茶：拾取 %d · 饮用 %d\n交通路线：%s · 候灯 %.1f 秒\n' ...
    '羊驼后踢 %d · 自行车撞飞 %d · 撞灯 %d\n' ...
    '共同倒地 %d · 互相拉回 %d 次 · 最大绳张力 %.1f\n' ...
    '校园网尝试 %d · 校车抵达 %d\n\n按 R 重新开始 · 按 Q 退出'], ...
    stats.elapsed, stats.failures, stats.damageTaken, ...
    stats.teaCollected, stats.teaUsed, stats.trafficRoute, ...
    stats.trafficWaitTime, stats.alpacaBoosts, stats.bicycleLaunches, ...
    stats.lampHits, stats.knockouts, stats.ropePulls, stats.maxTension, ...
    stats.networkAttempts, stats.busFinishes);
text(ax, 0.02, 0.96, summary, 'Units', 'normalized', ...
    'VerticalAlignment', 'top', 'FontName', cfg.render.fontName, ...
    'FontWeight', 'bold', 'FontSize', 12, ...
    'BackgroundColor', [1, 1, 1], 'Margin', 8);

previousR = false;
previousQ = false;
while isgraphics(fig)
    if getappdata(fig, 'closeRequested')
        return;
    end
    input = readInputSnapshot(fig, cfg.input);
    if input.reset && ~previousR
        restartRequested = true;
        return;
    end
    if input.quit && ~previousQ
        return;
    end
    previousR = input.reset;
    previousQ = input.quit;
    drawnow limitrate;
    pause(0.01);
end
end
