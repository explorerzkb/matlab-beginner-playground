function testBusRoute()
%TESTBUSROUTE Verify rideable buses, harmless lamps, and same-bus finish.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
data = world.mechanic.bus;

carryState = createInitialState(world, cfg, []);
carryState.levelTime = 0;
carryState = stepWorldBus(carryState, world, cfg, 0);
busRect = carryState.levelState.bus.rects(1, :);
carryState.players(1).pos = [busRect(1) + 2.0, ...
    busRect(2) + busRect(4)];
carryState.players(2).pos = [busRect(1) + 4.0, ...
    busRect(2) + busRect(4)];
oldX = [carryState.players.pos];
carryState.levelTime = 0.5;
carryState = stepWorldBus(carryState, world, cfg, 0.5);
expectedDelta = data.speed * 0.5;
newX = [carryState.players.pos];
assert(abs(newX(1) - oldX(1) - expectedDelta) < 1e-9 && ...
    abs(newX(3) - oldX(3) - expectedDelta) < 1e-9, ...
    'Standing players did not inherit campus-bus motion.');

lampState = createInitialState(world, cfg, []);
lampState = stepWorldBus(lampState, world, cfg, 0);
lamp = data.lampColliders(1, :);
lampState.players(1).pos = [lamp(1) + lamp(3) / 2, lamp(2) + 0.05];
heartsBefore = lampState.status.currentHearts;
lampState = stepWorldBus(lampState, world, cfg, 0);
assert(strcmp(lampState.players(1).visualImpactKind, 'lamp') && ...
    lampState.stats.lampHits == 1, ...
    'Touching a low lamp did not create the stumble feedback.');
assert(lampState.status.currentHearts == heartsBefore && ...
    lampState.stats.damageTaken == 0, ...
    'A lamp collision incorrectly consumed a shared heart.');

finishState = createInitialState(world, cfg, []);
finishState.levelTime = (244-data.loopStart)/data.speed;
finishState = stepWorldBus(finishState, world, cfg, 0);
finishBus = finishState.levelState.bus.rects(1, :);
finishState.players(1).pos = [finishBus(1) + 1.8, ...
    finishBus(2) + finishBus(4)];
finishState.players(2).pos = [finishBus(1) + 4.2, ...
    finishBus(2) + finishBus(4)];
finishState = stepWorldBus(finishState, world, cfg, 0);
assert(finishState.levelState.bus.completed && ...
    finishState.stats.busFinishes == 1, ...
    'Two pears on one bus did not complete the Sports Center finish.');
finishState = stepWorldBus(finishState, world, cfg, 0);
assert(finishState.stats.busFinishes == 1, ...
    'The same Sports Center arrival was counted repeatedly.');

splitState = createInitialState(world, cfg, []);
splitState.levelTime = (244-data.loopStart)/data.speed;
splitState = stepWorldBus(splitState, world, cfg, 0);
firstBus = splitState.levelState.bus.rects(1, :);
secondBus = splitState.levelState.bus.rects(2, :);
splitState.players(1).pos = [firstBus(1) + 2.0, ...
    firstBus(2) + firstBus(4)];
splitState.players(2).pos = [secondBus(1) + 2.0, ...
    secondBus(2) + secondBus(4)];
splitState = stepWorldBus(splitState, world, cfg, 0);
assert(~splitState.levelState.bus.completed, ...
    'Players on different buses incorrectly completed the game.');
end
