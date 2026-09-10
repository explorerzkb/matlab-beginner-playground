function state = runGameplayJourney(route, delayTicks, includeOpening, outputFolder)
if nargin < 2, delayTicks = 0; end
if nargin < 3, includeOpening = false; end
if nargin < 4, outputFolder = ''; end
if nargin < 1, route = 'upper'; end
%RUNGAMEPLAYJOURNEY Drive from the real spawn using keys only; log stalls.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); world=continuousCampusWorld();
state=createInitialState(world,cfg,[]); state=stepLevel(state,world,cfg,0);
if includeOpening
    cfg.runtime.testMode = true;
    state = stepPrologue(state,world,cfg,0);
    for openingTick = 1:253
        state = stepPrologue(state,world,cfg,cfg.physics.fixedDt);
    end
end
capture = ~isempty(outputFolder);
lastEvent = ''; frameIndex = 0;
inputTrace = zeros(18000, 6);
if capture
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    fig = figure('Visible','off','Position',[50 50 1280 720]);
    guard = onCleanup(@() close(fig));
    ax = axes(fig,'Position',[0.045 0.08 0.92 0.86]);
end
input.useItem=false;
for tick=1:18000
    for p=1:2
        player=state.players(p);
        input.player(p).left=false;
        input.player(p).right=true;
        input.player(p).jump=player.onGround && ~player.jumpHeld;
        if player.pos(1)>38 && player.pos(1)<43
            input.player(p).jump=false;
        end
        if player.pos(1)>68 && ~state.levelState.network.authenticated
            target=world.mechanic.network.loginButton(1)+0.45+0.65*(p-1);
            errorX=target-player.pos(1);
            demand=3*errorX-player.vel(1);
            input.player(p).right=demand>0.2;
            input.player(p).left=demand< -0.2;
            input.player(p).jump=false;
        end
    end
    for p=1:2
        player=state.players(p); x=player.pos(1);
        if x>110 && x<151
            input.player(p).jump=false;
            if strcmp(route,'lower') && x<118
                traffic=state.levelState.traffic;
                if ~traffic.pedestriansMayCross || traffic.signalProgress>.12
                    demand=3*(117.0-x)-player.vel(1);
                    input.player(p).right=demand>.2;
                    input.player(p).left=demand<-.2;
                end
            end
            if strcmp(route,'upper') && any(state.levelState.traffic.climbPresses<4)
                if state.levelState.traffic.climbPresses(p)>=4
                    input.player(p).right=false;
                    input.player(p).left=false;
                    continue;
                end
                target=114.5+1.2*(p-1);
                demand=3*(target-x)-player.vel(1);
                input.player(p).right=demand>0.2;
                input.player(p).left=demand< -0.2;
                if abs(target-x)<0.8
                    input.player(p).jump=mod(tick,12)==0;
                end
            end
        end
        if x>world.checkpoints(7).x && isfield(state.levelState,'bus')
            rects=state.levelState.bus.rects;
            idx=1;
            bus=rects(idx,:); target=bus(1)+2.0+1.8*(p-1);
            top=bus(2)+bus(4); riding=abs(player.pos(2)-top)<0.1;
            if riding
                input.player(p).right=false; input.player(p).left=false;
                lamps=world.mechanic.bus.lampColliders(:,1);
                direction=1;
                gap=(lamps-x)*direction;
                input.player(p).jump=any(gap>0 & gap<1.9) && ~player.jumpHeld;
            else
                demand=3*(target-x)-player.vel(1);
                input.player(p).right=demand>0.2; input.player(p).left=demand< -0.2;
                input.player(p).jump=player.onGround && ~player.jumpHeld;

            end
        end
    end
    if tick <= delayTicks
        for p=1:2
            input.player(p).left=false;
            input.player(p).right=false;
            input.player(p).jump=false;
        end
    end
    inputTrace(tick,:) = [input.player(1).left, input.player(1).right, ...
        input.player(1).jump, input.player(2).left, input.player(2).right, input.player(2).jump];
    state=stepConsumables(state,input,cfg,cfg.physics.fixedDt);
    state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
    state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
    if state.requestReset
        fprintf('RESET t%.2f phase=%s cp%d positions %.2f %.2f / %.2f %.2f\n',state.levelTime,state.levelState.bicycle.phase,state.checkpointIndex,state.players(1).pos,state.players(2).pos);
        state=resetToCheckpoint(state,world);
    end
    if mod(tick,600)==0 || state.completed
        fprintf('t=%.1f p1=[%.2f %.2f] p2=[%.2f %.2f] cp=%d net=%s deaths=%d\n', ...
          state.levelTime,state.players(1).pos,state.players(2).pos, ...
          state.checkpointIndex,state.levelState.network.pageMode,state.stats.failures);
        fprintf('route=%s climbs=%d/%d bus=%d\n',state.levelState.traffic.route,state.levelState.traffic.climbPresses,state.completed);
    end
    event = sprintf('%s-%s-%d-%s',state.levelState.activeRegionId, ...
        state.levelState.network.pageMode,state.checkpointIndex,state.levelState.bicycle.phase);
    if capture && (~strcmp(event,lastEvent) || state.completed)
        frameIndex = frameIndex+1;
        state = renderFrame(fig,ax,state,world,cfg);
        exportgraphics(fig,fullfile(outputFolder,sprintf('%02d-%s.png',frameIndex,event)), ...
            'Resolution',100);
        lastEvent = event;
    end
    if state.completed, break; end
end
assert(state.completed,'Input journey stalled before the Sports Center.');
assert(state.levelState.network.authenticated && state.stats.networkAttempts==2);
assert(state.levelState.bicycle.landed && state.stats.bicycleLaunches==1);
assert(state.checkpointIndex==7 && state.stats.busFinishes==1);
assert(strcmp(state.levelState.traffic.route,route));
assert(state.stats.teaUsed==0,'Journey depended on a consumable.');
if ~includeOpening && delayTicks==0
    assert(state.stats.failures<=3 && state.stats.damageTaken<=6, ...
        'The hazardous vehicle route failed to recover within two extra retries.');
else
    assert(state.stats.failures<=3, ...
        'Changed input timing could not recover within three retries.');
end
if capture
    inputTrace=inputTrace(1:tick,:);
    save(fullfile(outputFolder,'journey-evidence.mat'),'state','inputTrace','route','delayTicks');
    clear guard;
end
fprintf('INPUT JOURNEY PASSED: %s, delay %d, opening %d, %.2fs\n', ...
    route,delayTicks,includeOpening,state.levelTime);
end
