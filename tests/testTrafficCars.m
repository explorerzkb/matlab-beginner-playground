function testTrafficCars()
%TESTTRAFFICCARS Depth traffic never uses player height as road depth.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root); world=continuousCampusWorld(); d=world.mechanic.traffic;
assert(numel(d.laneEdges)==5,'The road must have exactly four marked lanes.');
centres=d.carData(:,1)+d.carData(:,3)/2;
laneIds=discretize(centres,d.laneEdges);
for lane=1:4
    assert(sum(laneIds==lane)==5,'Every marked lane needs five cars.');
    assert(all(abs(centres(laneIds==lane)-mean(d.laneEdges(lane:lane+1)))<1e-9), ...
        'Cars are not centred in their marked lane.');
end
crossed=false(1,4);
s=createInitialState(world,cfg,[]);
s.players(1).pos=[80 1]; s.players(2).pos=[82 1];
s=stepWorldTraffic(s,world,cfg,0);
s.levelState.traffic.arrived=true;
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
    for lane=1:4
        ids=laneIds==lane;
        % At least some real body area must remain inside the road crop.
        bodyBottom=t.cars(ids,2)+.07*t.cars(ids,4);
        bodyTop=t.cars(ids,2)+.93*t.cars(ids,4);
        assert(any(bodyBottom<d.roadRenderY(2) & bodyTop>d.roadRenderY(1)), ...
            'A marked lane has no visible traffic.');
        crossed(lane)=crossed(lane) || ...
            any(min(t.carDepth(ids),previous(ids))<=0 & ...
            max(t.carDepth(ids),previous(ids))>=0);
    end
    if mod(tick,30)==0
        [v,f,c]=trafficCarGeometry(t.cars,t.carDirections,d.roadRenderY);
        visibleY=v(f(:),2);
        assert(all(visibleY>=d.roadRenderY(1) & visibleY<=d.roadRenderY(2)), ...
            'Rendered car escaped the asphalt into the bridge or sky.');
        assert(size(f,1)==size(c,1),'Clipping lost face colours.');
    end
    if t.pedestriansMayCross
        assert(all(abs(t.carDepth)>d.contactDepth),'Pedestrian green has a car in the crossing.');
    end
    previous=t.carDepth;
end
assert(moved && d.crosswalk(3)>=.9*d.upperBridgePlatforms(3));
assert(all(crossed),'Every lane must carry cars through the crossing.');
% Fully off-road cars vanish; a car at the crossing keeps its full shape.
for direction=[-1 1]
    [~,f,~]=trafficCarGeometry([122 -8 1.9 2.2;122 7 1.9 2.2], ...
        [direction;direction],d.roadRenderY);
    assert(isempty(f),'Off-road cars still have visible faces.');
    [v,f,c]=trafficCarGeometry([122 1 1.9 2.2],direction);
    [cv,cf,cc]=trafficCarGeometry([122 1 1.9 2.2],direction,d.roadRenderY);
    assert(isequal(v,cv) && isequal(f,cf) && isequal(c,cc), ...
        'Clipping changed the car at the player crossing.');
end
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
