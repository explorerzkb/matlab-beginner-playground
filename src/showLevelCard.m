function continueGame = showLevelCard(fig, ax, level, cfg)
%SHOWLEVELCARD Brief chapter card between levels.

continueGame = false;
cla(ax);
axis(ax, [0, 1, 0, 1]);
axis(ax, 'off');
set(ax, 'Color', [0.94, 0.97, 0.98]);
text(ax, 0.5, 0.62, level.name, 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontWeight', 'bold', ...
    'FontSize', 25, 'Color', cfg.presentation.colors.ink);
text(ax, 0.5, 0.42, level.instruction, 'HorizontalAlignment', 'center', ...
    'FontName', cfg.render.fontName, 'FontSize', 14, ...
    'Color', cfg.presentation.colors.muted);
clock = tic;
while toc(clock) < 1.25 && isgraphics(fig)
    if getappdata(fig, 'closeRequested')
        return;
    end
    drawnow limitrate;
    pause(0.01);
end
continueGame = true;
end
