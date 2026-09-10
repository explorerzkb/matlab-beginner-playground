function state = renderPrologueFrame(fig, ax, state, world, cfg)
%RENDERPROLOGUEFRAME Morph the actual pear body vertices from fitted curves.
state = renderFrame(fig, ax, state, world, cfg);
if ~isfield(state.render, 'prologueLines')
    state.render.prologueLines = gobjects(1,2);
    state.render.prologueHalo = plot(ax,nan,nan,'-', ...
        'Color',[0.53 0.48 0.39],'LineWidth',4.0);
    for p=1:2
        if p==1, color=cfg.presentation.colors.player1;
        else, color=cfg.presentation.colors.player2; end
        state.render.prologueLines(p)=plot(ax,nan,nan,'-', ...
            'Color',color,'LineWidth',2.2);
    end
    prologueObjects = [state.render.prologueHalo, state.render.prologueLines];
    for objectIndex = numel(prologueObjects):-1:1
        set(prologueObjects(objectIndex), 'Parent', ...
            state.render.handles.worldTransform);
    end
end
t = state.prologue.elapsed;
blend = min(1,max(0,(t-2)/0.7));
blend = blend^2*(3-2*blend);
for p = 1:2
    pear = state.render.handles.players(p);
    names = fieldnames(pear);
    for k = 1:numel(names)
        if isgraphics(pear.(names{k}))
            if blend < 1
                set(pear.(names{k}),'Visible','off');
            else
                set(pear.(names{k}),'Visible','on');
            end
        end
    end
    x = get(pear.body,'XData'); y = get(pear.body,'YData');
    points = pear.transform.Matrix * [x(:)'; y(:)'; zeros(1, numel(x)); ...
        ones(1, numel(x))];
    x = points(1, :)';
    y = points(2, :)';
    curveX = linspace(1.4,10.3,numel(x))';
    curveY = [ones(size(curveX)),sin(0.65*curveX),cos(0.65*curveX)] * ...
        state.prologue.fitCoefficients(:,p);
    morphX=(1-blend)*curveX+blend*x(:);
    morphY=(1-blend)*curveY+blend*y(:);
    if blend < 1
        set(state.render.prologueLines(p),'XData',morphX,'YData',morphY,'Visible','on');
        if p==2
            set(state.render.prologueHalo,'XData',morphX,'YData',morphY,'Visible','on');
        end
    else
        set(state.render.prologueLines(p),'Visible','off');
        set(state.render.prologueHalo,'Visible','off');
    end
end
if blend < 1
    set(state.render.handles.rope,'Visible','off');
else
    set(state.render.handles.rope,'Visible','on');
end
if t < 2
    label = sprintf('拟合完成   R^2 = %.3f   RMSE = %.3f', ...
        mean(state.prologue.fitR2),mean(state.prologue.fitRmse));
elseif t < 2.7
    label = '咦？曲线跑了。';
else
    label = '准备好，一起往右走。';
end
set(state.render.handles.instruction,'String',label);
end
