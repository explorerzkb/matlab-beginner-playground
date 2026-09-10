function testAlpacaShortcut()
%TESTALPACASHORTCUT Take the rear kick and land on the red bridge.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'levels'));
addpath(fullfile(projectRoot, 'src'));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
animals = world.mechanic.animals;
bridge = animals.shortcutPlatforms;

bridgeRight = bridge(:, 1) + bridge(:, 3);
animalRight = [animals.geese(:, 1) + animals.geese(:, 3) + ...
    animals.geese(:, 6); animals.ducks(:, 1) + animals.ducks(:, 3) + ...
    animals.ducks(:, 6)];
assert(min(bridge(:, 1)) <= animals.shortcutBypassRange(1) && ...
    max(bridgeRight) >= animals.shortcutBypassRange(2) && ...
    max(bridgeRight) > max(animalRight), ...
    'The red bridge does not bypass the latter animal route.');
assert(min(bridge(:, 2)) > max([animals.geese(:, 2) + ...
    animals.geese(:, 4); animals.ducks(:, 2) + animals.ducks(:, 4)]), ...
    'The red bridge is not vertically clear of the animal route.');
groundTop = 1.0;
bridgeClearance = min(bridge(:, 2)) - groundTop;
assert(bridgeClearance >= 2 * cfg.player.height, ...
    'The red bridge does not leave two player-heights of working room below.');
assert(bridge(1) >= animals.alpacaRearZone(1) + ...
    animals.alpacaRearZone(3) + cfg.player.width, ...
    'The bridge left edge still projects over the right-up kick corridor.');

state = createInitialState(world, cfg, []);
rear = animals.alpacaRearZone;
state.players(1).pos = [rear(1) + rear(3) / 2, 1.0];
% The partner remains on the natural approach side, so the landing must
% succeed while the rope is pulling against the launched player.
state.players(2).pos = [38.0, 1.0];
state.players(1).onGround = true;
state.players(2).onGround = true;
state = stepLevel(state, world, cfg, 0);
assert(state.levelState.animals.kickWarning > 0, ...
    'The bridge traversal did not begin with the visible rear-kick warning.');

input = idleInput();
landed = false;
for stepIndex = 1:round(2.0 / cfg.physics.fixedDt)
    state = stepPhysics(state, input, world, cfg, cfg.physics.fixedDt);
    state = stepLevel(state, world, cfg, cfg.physics.fixedDt);
    if playerOnBridge(state.players(1), bridge)
        landed = true;
        break;
    end
end

assert(landed, ...
    'The alpaca kick did not physically land the player on the red bridge.');
assert(state.levelState.animals.shortcutReached && ...
    state.stats.alpacaBoosts == 1 && state.stats.alpacaShortcutUses == 1, ...
    'Landing on the bridge was not recorded as one useful shortcut use.');
end

function input = idleInput()
for playerIndex = 1:2
    input.player(playerIndex).left = false;
    input.player(playerIndex).right = false;
    input.player(playerIndex).jump = false;
end
input.pause = false;
input.reset = false;
input.quit = false;
input.useItem = false;
input.rawKeys = {};
end

function tf = playerOnBridge(player, bridge)
tf = false;
halfWidth = player.size(1) / 2;
for index = 1:size(bridge, 1)
    rect = bridge(index, :);
    horizontal = player.pos(1) + halfWidth > rect(1) && ...
        player.pos(1) - halfWidth < rect(1) + rect(3);
    onTop = abs(player.pos(2) - (rect(2) + rect(4))) <= 0.08;
    if horizontal && onTop
        tf = true;
        return;
    end
end
end
