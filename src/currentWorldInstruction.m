function label = currentWorldInstruction(state, level)
%CURRENTWORLDINSTRUCTION Explain the mechanic under the current camera.

if ~strcmp(level.mechanic.type, 'continuousCampus')
    label = level.instruction;
    return;
end

switch state.levelState.activeRegionId
    case 'origin'
        label = ['P1  [A] [D] [W]　 P2  [←] [→] [↑]　 ' ...
            '[按住 Space] 共饮冰红茶　 两人被普通绳连接'];
    case 'northLake'
        label = ['地面观察鹅鸭空档；靠近羊驼鼻子等预告，' ...
            '喷嚏会把一只梨送上红桥捷径'];
    case 'network'
        label = ['两人分别站用户名和密码 → 踩记住密码存档 → ' ...
            '共同站登录；充值和自助服务都是物理控件'];
    case 'traffic'
        label = ['喷泉可把人送上北理桥；留在地面则观察红绿灯，' ...
            '行人绿灯时过街'];
    case 'lexue'
        if ~state.levelState.lexue.selectionOpen
            label = '数字翻页前会变色预告；站在数字上会被轻轻抛起';
        elseif ~state.levelState.lexue.homeActive
            label = '倒计时已结束：两人共同站上“开始选课”';
        else
            label = '踩“我的课程”存档，躲开分批通知任务；必要时喝冰红茶';
        end
    otherwise
        label = '两只梨一起进入 Lucy 河，清空当前破防并完成旅程';
end
end
