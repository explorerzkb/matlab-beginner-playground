function testTrafficCars()
%TESTTRAFFICCARS Depth traffic never uses player height as road depth.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); world=continuousCampusWorld(); d=world.mechanic.traffic;
s=createInitialState(world,cfg,[]);
s.players(1).pos=[80 1]; s.players(2).pos=[82 1];
s=stepWorldTraffic(s,world,cfg,0);
initial=s.levelState.traffic.cars;
previous=s.levelState.traffic.carDepth;
moved=false; dt=cfg.physics.fixedDt;
for tick=1:round(6*sum(d.signalPhaseDurations)/dt)
    s.levelState.colliders=zeros(0,4);
    s=stepWorldTraffic(s,world,cfg,dt);
    t=s.levelState.traffic;
    assert(isequal(t.cars(:,1),initial(:,1)),'Cars moved horizontally.');
    assert(all(abs(t.carDepth-previous)<=d.carData(:,5)*dt+1e-8), ...
        'Depth car jumped at signal or road end.');
    moved=moved || any(abs(t.carDepth-previous)>1e-8);
    if t.pedestriansMayCross
        assert(all(abs(t.carDepth)>d.contactDepth),'Pedestrian green has a car in the crossing.');
    end
    previous=t.carDepth;
end
assert(moved && d.crosswalk(3)>=.9*d.upperBridgePlatforms(3));
% A moving car only hurts at the shared ground cross-section.
for probe=1:3
    s=createInitialState(world,cfg,[]);
    s=stepWorldTraffic(s,world,cfg,0);
    s.levelState.traffic.carDepth(1)=0;
    y=1;
    if probe==2, s.levelState.traffic.carDepth(1)=7; end
    if probe==3, y=5.25; end
    s.players(1).pos=[d.carData(1,1)+.8,y];
    s.players(2).pos=[80 1];
    s=stepWorldTraffic(s,world,cfg,dt);
    assert((s.status.currentHearts==0)==(probe==1), ...
        'Depth collision or bridge safety is incorrect.');
end
fprintf('DEPTH TRAFFIC PASSED: six cycles, constant lane X, ground-only contact\n');
end
