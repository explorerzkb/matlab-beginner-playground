function handles = updateRaceRunners(handles,state,world,cfg,preload)
%UPDATERACERUNNERS Eight articulated students, each planted in one track lane.
if nargin < 5
    preload = false;
end
ax=ancestor(handles.worldTransform,'axes');
worldParent = handles.worldTransform;
colors=[.78 .18 .16;.18 .38 .68;.91 .67 .13;.12 .48 .38; ...
    .57 .28 .66;.94 .45 .19;.26 .62 .66;.82 .31 .47];
visible=state.render.cameraCentre>72 && state.render.cameraCentre<126;
if ~visible && ~preload && ~isfield(handles, 'raceRunners')
    return;
end
if ~isfield(handles,'raceRunners')
    runners=gobjects(8,2);
    faceTemplate = nan(3, 18);
    faceTemplate(1, :) = 1:18;
    faceTemplate(2, 1:4) = 19:22;
    faceTemplate(3, :) = 23:40;
    for lane=8:-1:1
        runners(lane,1)=patch(ax,'Vertices',zeros(40,2), ...
            'Faces',faceTemplate,'FaceVertexCData', ...
            [.35 .34 .31;colors(lane,:);.86 .64 .43], ...
            'FaceColor','flat','EdgeColor','none');
        runners(lane,2)=plot(ax,nan,nan,'-','Color',[.15 .17 .19], ...
            'LineWidth',2.5);
    end
    handles.raceRunners=runners;
    handles.raceCaption=text(ax,91,8.5,'','FontName',cfg.render.fontName, ...
        'FontSize',11,'Color',[.98 .97 .88],'BackgroundColor',[.12 .23 .24], ...
        'Margin',5,'VerticalAlignment','top');
    newHandles=[runners(:);handles.raceCaption];
    for objectIndex = numel(newHandles):-1:1
        set(newHandles(objectIndex), 'Parent', worldParent);
    end
    % Insert newly created runners behind rope/pears without changing HUD order.
    children=worldParent.Children;
    moving=children(ismember(children,newHandles));
    rest=children(~ismember(children,newHandles));
    at=find(rest==handles.rope,1);
    worldParent.Children=[rest(1:at);moving;rest(at+1:end)];
end
r=state.levelState.race;
if ~visible
    if ~preload
        set(handles.raceRunners(:),'Visible','off');
        set(handles.raceCaption,'Visible','off');
        return;
    end
end
if isfield(handles, 'raceRenderTime') && ...
        state.levelTime - handles.raceRenderTime < 1 / 30
    return;
end
set(handles.raceRunners(:),'Visible','on');
animationTime=0;
if strcmp(r.phase,'running') && any(r.runnerX<world.mechanic.race.finishX)
    animationTime=r.elapsed;
end
geometryKey={r.phase,r.runnerX,animationTime,world.mechanic.race.laneY};
geometryChanged=~isfield(handles,'raceGeometryKey') || ...
    ~isequal(handles.raceGeometryKey,geometryKey);
if geometryChanged
theta=linspace(0,2*pi,18);
for lane=8:-1:1
    scale=1.05-.045*(lane-1);
    y=world.mechanic.race.laneY(lane);
    x=r.runnerX(lane)+.65*(y-1);
    moving=strcmp(r.phase,'running') && r.runnerX(lane)<world.mechanic.race.finishX;
    phase=12*r.elapsed+.7*lane;
    stride=.30*sin(phase)*double(moving);
    if strcmp(r.phase,'waiting')
        lean=.18; hip=.40; shoulder=.69;
    else
        lean=.09; hip=.48; shoulder=.86;
    end
    footA=[stride 0]; footB=[-stride .09*double(moving)*max(0,sin(phase))];
    limbs=[footA;[-stride*.1 hip*.55];[0 hip];[stride*.1 hip*.55];footB; ...
        [nan nan];[lean shoulder-.04];[lean-stride*.7-.10 shoulder-.23]; ...
        [lean-stride*.5+.10 shoulder-.32];[nan nan];[lean shoulder-.04]; ...
        [lean+stride*.7+.10 shoulder-.23];[lean+stride*.5+.24 shoulder-.13]];
    shadow=[x+scale*.28*cos(theta(:)), y+.035*sin(theta(:))];
    torso=[x+scale*[-.10;.11;lean+.11;lean-.10], ...
        y+scale*[hip;hip;shoulder;shoulder]];
    head=[x+scale*(lean+.035+.095*cos(theta(:))), ...
        y+scale*(shoulder+.14+.12*sin(theta(:)))];
    set(handles.raceRunners(lane,1),'Vertices',[shadow;torso;head]);
    hairX=x+scale*(lean+[-.05 -.04 .06 .11]);
    hairY=y+scale*(shoulder+[.13 .23 .25 .22]);
    shoesX=x+scale*[footA(1)-.03 footA(1)+.13 nan ...
        footB(1)-.03 footB(1)+.13];
    shoesY=y+scale*[footA(2) footA(2) nan footB(2) footB(2)];
    set(handles.raceRunners(lane,2),'XData',[x+scale*limbs(:,1); ...
        nan;hairX(:);nan;shoesX(:)],'YData',[y+scale*limbs(:,2); ...
        nan;hairY(:);nan;shoesY(:)]);
end
handles.raceGeometryKey=geometryKey;
end
if strcmp(r.phase,'waiting')
    caption='八道短跑 · 两只梨过线起跑 | 按住 Space 喝冰红茶';
elseif strcmp(r.phase,'running')
    caption='冲线！学生只慢一点点 · 冰红茶可以拉开距离';
else
    if r.teamWon, result='双梨获胜'; else, result='学生先到，下次再来'; end
    caption=sprintf('%s · P1 %.2f 秒 / P2 %.2f 秒',result,r.finishTimes);
end
set(handles.raceCaption,'String',caption,'Position',[max(84,state.render.cameraCentre-7) 8.1 0],'Visible','on');
if preload && ~visible
    set(handles.raceRunners(:), 'Visible', 'off');
    set(handles.raceCaption, 'Visible', 'off');
end
handles.raceRenderTime = state.levelTime;
end
