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
        label = ['鸭鹅有实体：可跳过、站上去或持续推开；' ...
            '绕到羊驼身后会被踢上桥，孔雀开屏可向上弹射'];
    case 'network'
        switch state.levelState.network.pageMode
            case 'timeout'
                label = '校园网超时：网页承托消失，掉下去后从入口重试';
            case 'loading'
                label = '两只梨正在原地连接校园网……';
            case 'success'
                label = '登录成功：沿操场继续向右，网页会自然留在身后';
            otherwise
                label = ['走台阶或红桥登上公告框 → 经过用户名自动填表 → ' ...
                    '跳上登录按钮'];
        end
    case 'playground'
        label = '八道短跑：两梨过线一起起跑，按住 Space 共饮冰红茶加速。';
    case 'northLiBridge'
        traffic=state.levelState.traffic;
        if strcmp(traffic.route,'undecided')
            label = ['选上桥或地面路线，进入后不能换。' ...
                '上桥要各按四次跳跃键；走地面要等绿灯。'];
        elseif strcmp(traffic.route,'upper') && any(traffic.climbPresses<4)
            label = '两人各按四次跳跃键，爬到一半也可以停下来等同伴。';
        elseif strcmp(traffic.route,'upper')
            label = '沿桥面往右走，到前面的路口汇合。';
        elseif traffic.pedestriansMayCross
            label = '绿灯了，一起往右过街。';
        else
            label = '先在车道外的等候处等绿灯，行驶的汽车碰到就会受伤。';
        end
    case 'bicycle'
        if strcmp(state.levelState.bicycle.phase, 'warning')
            label = '自行车和电动车涌来——剧情撞飞不可避，准备向右上飞！';
        elseif strcmp(state.levelState.bicycle.phase, 'flight')
            label = '两只梨正被撞向右上方，镜头会一起抬升到文博中心';
        else
            label = '北食堂／徐特立图书馆路口：混乱车流即将出现';
        end
    case 'museum'
        label = '跳上同一辆绿白校车；注意车身碰撞扣 3 点，车顶可站';
    case 'busTour'
        label = '车身碰撞扣 3 点；站车顶跳过路灯，撞灯本身不扣血';
    case 'sportsCenter'
        label = '体育馆就是终点：两只梨必须同乘一辆校车进入终点区';
    otherwise
        label = '两只梨继续沿连续校园世界向右前进';
end
end
