function testContinuousPrologue()
%TESTCONTINUOUSPROLOGUE Use the same state and renderer through the opening.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); cfg.runtime.testMode=true;
world=continuousCampusWorld(); state=createInitialState(world,cfg,[]);
state=stepLevel(state,world,cfg,0);
fig=figure('Visible','off','Position',[50 50 1280 720]);
guard=onCleanup(@() close(fig));
ax=axes(fig,'Position',[0.045 0.08 0.92 0.86]);
folder=fullfile(root,'docs','visuals','playability-v29','prologue');
if ~isfolder(folder), mkdir(folder); end
frames=[1 120 141 163 200 253];
state=stepPrologue(state,world,cfg,0);
for tick=1:253
    state=stepPrologue(state,world,cfg,cfg.physics.fixedDt);
    if any(tick==frames)
        state=renderPrologueFrame(fig,ax,state,world,cfg);
        if tick==1, initialBody=state.render.handles.players(1).body; end
        assert(state.render.handles.players(1).body==initialBody, ...
            'Opening replaced the player graphics instead of morphing them.');
        exportgraphics(fig,fullfile(folder,sprintf('frame-%03d.png',tick)),'Resolution',100);
    end
end
assert(state.prologue.complete && state.prologue.soundPlayed);
assert(all(state.prologue.fitR2>0.99) && all(state.prologue.fitRmse<0.05));
assert(state.stats.failures==0 && state.checkpointIndex==1);
positions=vertcat(state.players.pos);
assert(all(positions(:,1)>9) && all(positions(:,1)<13.4) && ...
    all(abs(positions(:,2)-1)<0.1), ...
    'Opening did not hand off grounded pears at the lake entrance.');
assert(state.render.initialized && state.levelTime>1.4);
fprintf('CONTINUOUS PROLOGUE PASSED\n');
clear guard;
end
