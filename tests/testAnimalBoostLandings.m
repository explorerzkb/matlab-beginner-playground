function testAnimalBoostLandings(outputFolder)
%TESTANIMALBOOSTLANDINGS Trigger real boosts with a tethered partner at -25.
if nargin<1, outputFolder=''; end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); world=continuousCampusWorld();
assert(cfg.physics.gravity==-25,'The user-selected gravity was changed.');
deck=world.mechanic.animals.shortcutPlatforms(1,:);
cases=0;
if ~isempty(outputFolder)
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    fig=figure('Visible','off','Position',[50 50 1280 720]);
    guard=onCleanup(@() close(fig));
    ax=axes(fig,'Position',[0.045 0.08 0.92 0.86]);
end
for kind={'alpaca','peacock'}
    for target=1:2
        for offset=[0.25 0.65 1.05]
            state=createInitialState(world,cfg,[]);
            if strcmp(kind{1},'alpaca')
                x=world.mechanic.animals.alpacaRearZone(1)+offset;
            else
                x=world.mechanic.animals.peacockBounceZone(1)+offset;
            end
            state.players(target).pos=[x 1];
            state.players(3-target).pos=[x-3.1 1];
            for p=1:2
                state.players(p).onGround=true;
                input.player(p)=struct('left',false,'right',false,'jump',false);
            end
            state=stepLevel(state,world,cfg,0);
            samples=zeros(210,8); landed=false;
            for tick=1:210
                state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
                state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
                samples(tick,:)=[state.players(1).pos,state.players(2).pos, ...
                    state.players(target).vel,state.players(target).hitWall, ...
                    state.players(target).hitCeiling];
                if ~isempty(outputFolder) && target==1 && offset==0.65 && any(tick==[1 30 60 90])
                    state=renderFrame(fig,ax,state,world,cfg);
                    exportgraphics(fig,fullfile(outputFolder,sprintf('%s-%03d.png',kind{1},tick)),'Resolution',100);
                end
                p=state.players(target);
                if p.onGround && abs(p.pos(2)-sum(deck([2 4])))<0.05 && ...
                        p.pos(1)+p.size(1)/2>deck(1)
                    landed=true;
                    if ~isempty(outputFolder) && target==1 && offset==0.65
                        state=renderFrame(fig,ax,state,world,cfg);
                        exportgraphics(fig,fullfile(outputFolder,[kind{1} '-landed.png']),'Resolution',100);
                    end
                    break;
                end
            end
            assert(landed,'%s target %d offset %.2f failed to land with the real rope.', ...
                kind{1},target,offset);
            cases=cases+1;
            if ~isempty(outputFolder)
                if ~isfolder(outputFolder), mkdir(outputFolder); end
                samples=samples(1:tick,:);
                save(fullfile(outputFolder,sprintf('%s-p%d-%.2f.mat', ...
                    kind{1},target,offset)),'samples','state','cfg');
            end
        end
    end
end
if ~isempty(outputFolder), clear guard; end
fprintf('ANIMAL BOOST LANDINGS PASSED: %d tethered cases at gravity -25\n',cases);
end
