function ready = runPoseCalibration(fig,ax,cfg)
%RUNPOSECALIBRATION Visible zones, stable zero and explicit direction checks.
ready=false;
originalYDir=ax.YDir;
axesGuard=onCleanup(@() restoreAxes(ax,originalYDir));
cla(ax); axis(ax,[0 240 0 180]); axis(ax,'ij'); axis(ax,'off'); hold(ax,'on');
preview=image(ax,[0 240],[0 180],zeros(180,240,3,'uint8'));
plot(ax,[120 120],[0 180],'y--');
plot(ax,[0 240],[18 18],'y:');
text(ax,60,12,'玩家一','Color','yellow','HorizontalAlignment','center');
text(ax,180,12,'玩家二','Color',[0 .85 1],'HorizontalAlignment','center');
overlay=createOverlay(ax);
text(ax,4,176,'黄 P1  青 P2  红× 低置信度','Color','white','FontSize',8);
label=title(ax,'正在启动摄像头；K 切键盘，Q 退出','FontName',cfg.render.fontName);
verified=false(2,3); lastRender=-inf;
jumpBaseline=[0 0];
if isappdata(fig,'poseSession')
    initialSession=getappdata(fig,'poseSession');
    jumpBaseline=[initialSession.state.player.sequence];
end
while isgraphics(fig)
    input=readInputSnapshot(fig,cfg.input);
    if input.quit || getappdata(fig,'closeRequested'), return; end
    if input.toggleMode
        setPoseMode(fig,cfg,'keyboard'); ready=true; return;
    end
    if input.recalibrate
        flushFigurePose(fig,true); verified=false(2,3); jumpBaseline=[0 0];
    end
    if isappdata(fig,'poseSession')
        s=getappdata(fig,'poseSession'); s.previewRequested=true;
        setappdata(fig,'poseSession',s);
        if strcmp(s.state.phase,'active')
            for i=1:2
                verified(i,1)=verified(i,1) || s.state.player(i).direction<0;
                verified(i,2)=verified(i,2) || s.state.player(i).direction>0;
                verified(i,3)=verified(i,3) || s.state.player(i).sequence>jumpBaseline(i);
            end
        end
        message=s.state.reason;
        if strcmp(s.state.phase,'active')
            message=sprintf('逐人左倾／右倾／试跳：P1 %d%d%d · P2 %d%d%d',verified(1,:),verified(2,:));
        end
        if ~isempty(s.error), message=s.error; end
        if poseClock()-lastRender>=1/15
            if ~isempty(s.preview), set(preview,'CData',s.preview(:,end:-1:1,:)); end
            if ~isempty(s.lastPacket)
                updateOverlay(overlay,s.lastPacket,s.cfg.confidence);
            else
                clearOverlay(overlay);
            end
            set(label,'String',{message,'头、肩、肘、腕完整入画；头顶留起跳余量 · K 键盘 · Q 退出'});
            drawnow; lastRender=poseClock();
        end
        if all(verified,'all')
            s.previewRequested=false; setappdata(fig,'poseSession',s);
            flushFigurePose(fig,false); ready=true; return;
        end
    else
        set(label,'String',{getappdata(fig,'poseError'),'K 切键盘 · Q 退出'}); drawnow;
    end
    pause(0.005);
end
end

function restoreAxes(ax,direction)
if isgraphics(ax), set(ax,'YDir',direction); end
end

function overlay=createOverlay(ax)
colors={[1 .82 0],[0 .85 1]};
for i=1:2
    overlay(i).bones=plot(ax,nan,nan,'-','Color',colors{i},'LineWidth',2); %#ok<AGROW>
    overlay(i).high=plot(ax,nan,nan,'o','Color',colors{i}, ...
        'MarkerFaceColor',colors{i},'MarkerSize',4); %#ok<AGROW>
    overlay(i).low=plot(ax,nan,nan,'x','Color',[1 .2 .2], ...
        'LineWidth',1.5,'MarkerSize',6); %#ok<AGROW>
    overlay(i).noseHigh=plot(ax,nan,nan,'o','Color',colors{i}, ...
        'MarkerFaceColor',colors{i},'MarkerSize',9,'LineWidth',1.5); %#ok<AGROW>
    overlay(i).noseLow=plot(ax,nan,nan,'x','Color',[1 .2 .2], ...
        'LineWidth',2,'MarkerSize',10); %#ok<AGROW>
end
end

function updateOverlay(overlay,packet,confidence)
data=posePreviewOverlayData(packet.points,packet.imageSize,[180 240],confidence);
for i=1:2
    segments=data.player(i).segments;
    if isempty(segments)
        x=nan; y=nan;
    else
        x=[segments(:,1) segments(:,3) nan(size(segments,1),1)]'; x=x(:);
        y=[segments(:,2) segments(:,4) nan(size(segments,1),1)]'; y=y(:);
    end
    set(overlay(i).bones,'XData',x,'YData',y);
    set(overlay(i).high,'XData',data.player(i).high(:,1), ...
        'YData',data.player(i).high(:,2));
    set(overlay(i).low,'XData',data.player(i).low(:,1), ...
        'YData',data.player(i).low(:,2));
    set(overlay(i).noseHigh,'XData',data.player(i).noseHigh(:,1), ...
        'YData',data.player(i).noseHigh(:,2));
    set(overlay(i).noseLow,'XData',data.player(i).noseLow(:,1), ...
        'YData',data.player(i).noseLow(:,2));
end
end

function clearOverlay(overlay)
for i=1:2
    handles=[overlay(i).bones overlay(i).high overlay(i).low ...
        overlay(i).noseHigh overlay(i).noseLow];
    set(handles,'XData',nan,'YData',nan);
end
end
