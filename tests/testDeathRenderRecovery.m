function testDeathRenderRecovery()
%TESTDEATHRENDERRECOVERY Render on the exact reset frame, before another tick.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'),fullfile(root,'levels'));
cfg=gameConfig(root);world=continuousCampusWorld();
fig=figure('Visible','off','Position',[50 50 1280 720]);
guard=onCleanup(@() close(fig));
ax=axes(fig);
s=createInitialState(world,cfg,[]);s=stepLevel(s,world,cfg,0);
s=renderFrame(fig,ax,s,world,cfg);
input.useItem=false;
for round=1:2
    for checkpoint=1:7
        s.checkpointIndex=checkpoint;
        if checkpoint>=4
            s.levelState.network.authenticated=true;
            s.levelState.network.pageMode='success';
        end
        if checkpoint>=6
            s.levelState.bicycle.landed=true;
            s.levelState.bicycle.phase='landed';
        end
        % Exercise death rendering after the new respawn immunity expires.
        s=stepConsumables(s,input,cfg,cfg.health.respawnProtection);
        s=applyDamageEvent(s,cfg,'fatal');
        s=stepConsumables(s,input,cfg,cfg.health.deathDelay);
        assert(s.requestReset);
        s=resetToCheckpoint(s,world);
        % The interactive loop can draw here without running stepLevel again.
        s=renderFrame(fig,ax,s,world,cfg);
        drawnow;
        assert(isgraphics(fig) && s.status.currentHearts==3 && ~s.requestReset);
    end
end
clear guard;
fprintf('DEATH RENDER RECOVERY PASSED: 14 immediate reset frames, all seven checkpoints.\n');
end
