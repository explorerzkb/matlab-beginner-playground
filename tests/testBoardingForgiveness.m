function testBoardingForgiveness()
%TESTBOARDINGFORGIVENESS Forgive rear jumps, not arbitrary bus collisions.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=gameConfig(root); world=continuousCampusWorld(); d=world.mechanic.bus;
for position=[.3 2 1;6 2 1;16.7 2 1;.3 1 0]'
    s=createInitialState(world,cfg,[]); s=stepWorldBus(s,world,cfg,0);
    s.players(1).pos=[d.loopStart+position(1),position(2)];
    s.players(1).vel=[5 10*position(3)];
    s.players(1).onGround=~logical(position(3));
    s=stepWorldBus(s,world,cfg,cfg.physics.fixedDt);
    shouldLive=position(1)<d.boardingTailWidth && position(3)==1;
    assert((s.status.currentHearts==3)==shouldLive,'Rear jump grace leaked or failed.');
end
s=createInitialState(world,cfg,[]); s=stepWorldBus(s,world,cfg,0);
s.players(1).pos=[d.loopStart+.3,2]; s.players(1).vel=[3 10];
s.players(1).onGround=false;
s=stepWorldBus(s,world,cfg,.01);
s.players(1).pos(2)=d.y+d.size(2)-.25; s.players(1).vel(2)=-1;
s=stepWorldBus(s,world,cfg,.01);
assert(s.status.currentHearts==3 && s.players(1).onGround && ...
    abs(s.players(1).pos(2)-(d.y+d.size(2)))<1e-9);
% Actual two-player jumps from several rear distances, with normal physics.
for offset=[-3.8 -3 -2 -1 0]
    s=createInitialState(world,cfg,[]); s=stepLevel(s,world,cfg,0);
    s.levelState.network.authenticated=true; s.levelState.network.pageMode='success';
    s.levelState.bicycle.landed=true; s.levelState.bicycle.phase='landed';
    for p=1:2
        s.players(p).pos=[d.loopStart+offset+1.5*(p-1),1];
        s.players(p).onGround=true;
    end
    input.useItem=false; boarded=false;
    for tick=1:100
        for p=1:2
            input.player(p)=struct('left',false,'right',true,'jump',tick==1);
        end
        s=stepPhysics(s,input,world,cfg,cfg.physics.fixedDt);
        s=stepLevel(s,world,cfg,cfg.physics.fixedDt);
        assert(s.status.currentHearts==3,'Normal rear jump killed a pear at offset %.1f.',offset);
        boarded=all([s.players.onGround]) && ...
            all(abs([s.players(1).pos(2),s.players(2).pos(2)]-(d.y+d.size(2)))<.1);
        if boarded, break; end
    end
    assert(boarded,'Rear jump did not reach the roof at offset %.1f.',offset);
end
fprintf('BUS REAR GRACE PASSED: five real paired jumps, bounded grace, middle/front/ground lethal\n');
end
