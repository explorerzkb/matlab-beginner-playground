function testVehicleDamage()
%TESTVEHICLEDAMAGE Visible vehicle bodies hurt even outside the crossing.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'config'),fullfile(root,'levels'),fullfile(root,'src'));
cfg=gameConfig(root);world=continuousCampusWorld();
s=createInitialState(world,cfg,[]);s=stepWorldBus(s,world,cfg,0);
b=s.levelState.bus.rects(1,:);s.players(1).pos=[b(1)+3 1];
s.status.hitCooldown=10;
s=stepWorldBus(s,world,cfg,.02);
assert(s.stats.damageTaken==3 && s.status.deathPending,'Bus body must deal three hearts.');
s=stepWorldBus(s,world,cfg,.02);assert(s.stats.damageTaken==3);
s=createInitialState(world,cfg,[]);s=stepWorldBus(s,world,cfg,0);
b=s.levelState.bus.rects(1,:);
for p=1:2,s.players(p).pos=[b(1)+1+p sum(b([2 4]))];end
s.levelTime=.1;s=stepWorldBus(s,world,cfg,.1);
assert(s.stats.damageTaken==0,'Bus roof riders must remain safe.');
for lane=1:size(world.mechanic.traffic.carData,1)
    s=createInitialState(world,cfg,[]);s=stepWorldTraffic(s,world,cfg,0);
    x=world.mechanic.traffic.carData(lane,1);
    s.levelState.traffic.carDepth(lane)=0;
    s.players(1).pos=[x+.8 1];
    s=stepWorldTraffic(s,world,cfg,.01);
    assert(s.status.deathPending,'Car at the crossing depth did not hurt.');
end
s=createInitialState(world,cfg,[]);s=stepWorldTraffic(s,world,cfg,0);
s.players(1).pos=[122.8 5.25];s.levelState.traffic.carDepth(1)=0;
s=stepWorldTraffic(s,world,cfg,.01);
assert(s.stats.damageTaken==0,'Cars hit a player on the bridge.');
assert(size(world.mechanic.bicycle.bikeRects,1)==9);
assert(all(abs(world.mechanic.bicycle.bikeSpeeds)>=18));
fprintf('VEHICLE DAMAGE PASSED: bus 3 hearts, roof safe, depth crossing, bridge safe.\n');
end
