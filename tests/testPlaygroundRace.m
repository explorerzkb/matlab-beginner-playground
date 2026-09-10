function testPlaygroundRace(outputFolder)
%TESTPLAYGROUNDRACE Drive the actual keys and consumable through an optional race.
if nargin<1, outputFolder=''; end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'levels'),fullfile(root,'config'));
cfg=gameConfig(root); world=continuousCampusWorld();
normal=runCase(false,false); boosted=runCase(true,false); lost=runCase(false,true);
assert(normal.levelState.race.teamWon,'Normal running must narrowly win.');
normalTime=max(normal.levelState.race.finishTimes);
margin=18-max(world.mechanic.race.speeds)*normalTime;
assert(margin>.30 && margin<.85,'Normal lead must stay around half a body.');
assert(boosted.stats.teaUsed==1 && boosted.inventory.teaCount==0);
assert(max(boosted.levelState.race.finishTimes)<normalTime-.25, ...
    'Real tea must make a noticeable difference.');
assert(~lost.levelState.race.teamWon,'Stopping must permit an honest loss.');
assert(lost.players(1).pos(1)>108 && lost.players(2).pos(1)>108);
% A single player crossing cannot start the race without the partner.
s=createInitialState(world,cfg,[]);s.levelState.network.authenticated=true;
s.players(1).pos=[91 1];s.players(2).pos=[88 1];s=stepLevel(s,world,cfg,0);
assert(strcmp(s.levelState.race.phase,'waiting'));
s=resetToCheckpoint(s,world);s=stepLevel(s,world,cfg,0);
assert(strcmp(s.levelState.race.phase,'waiting'));
fprintf('PLAYGROUND RACE PASSED: normal lead %.3f, normal %.3fs, tea %.3fs; loss and reset recover.\n', ...
    margin,normalTime,max(boosted.levelState.race.finishTimes));

    function state=runCase(useTea,pauseRace)
        state=createInitialState(world,cfg,[]);
        state.levelState.network.authenticated=true;
        state.levelState.network.pageMode='success';
        state.players(1).pos=[86 1];state.players(2).pos=[87.5 1];
        state.inventory.teaCount=double(useTea);
        state=stepLevel(state,world,cfg,0);
        capture=~isempty(outputFolder) && ~pauseRace;
        if capture
            if ~isfolder(outputFolder),mkdir(outputFolder);end
            fig=figure('Visible','off','Position',[50 50 1280 720]);
            guard=onCleanup(@() close(fig));
            ax=axes(fig,'Position',[.045 .08 .92 .86]);
        end
        for tick=1:600
            input.useItem=useTea;
            stop=pauseRace && strcmp(state.levelState.race.phase,'running') && ...
                state.levelState.race.elapsed<1;
            for p=1:2
                input.player(p)=struct('left',false,'right',~stop,'jump',false);
            end
            state=stepConsumables(state,input,cfg,cfg.physics.fixedDt);
            state=stepPhysics(state,input,world,cfg,cfg.physics.fixedDt);
            state=stepLevel(state,world,cfg,cfg.physics.fixedDt);
            if capture && any(tick==[1 35 80 135])
                state=renderFrame(fig,ax,state,world,cfg);
                exportgraphics(fig,fullfile(outputFolder,sprintf('tea%d-%03d.png',useTea,tick)),'Resolution',100);
            end
            if strcmp(state.levelState.race.phase,'finished'),break;end
        end
        assert(strcmp(state.levelState.race.phase,'finished'));
        if capture
            save(fullfile(outputFolder,sprintf('tea%d.mat',useTea)),'state');
            clear guard;
        end
    end
end
