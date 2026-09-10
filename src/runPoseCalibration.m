function ready = runPoseCalibration(fig,ax,cfg)
%RUNPOSECALIBRATION Visible zones, stable zero and explicit direction checks.
ready=false;
originalYDir=ax.YDir;
axesGuard=onCleanup(@() restoreAxes(ax,originalYDir));
cla(ax); axis(ax,[0 240 0 180]); axis(ax,'ij'); axis(ax,'off'); hold(ax,'on');
preview=image(ax,zeros(180,240,3,'uint8'));
plot(ax,[120 120],[0 180],'y--');
plot(ax,[0 240],[18 18],'y:');
plot(ax,[0 240],[171 171],'y:');
text(ax,60,12,'玩家一','Color','yellow','HorizontalAlignment','center');
text(ax,180,12,'玩家二','Color','yellow','HorizontalAlignment','center');
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
            set(label,'String',{message,'全身、外展肘与脚踝入画；顶部留起跳余量 · K 键盘 · Q 退出'});
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
