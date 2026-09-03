function testPearExpressions()
%TESTPEAREXPRESSIONS Verify collision, flight, and rope-driven faces.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
cfg = gameConfig(projectRoot);
world = continuousCampusWorld();
state = createInitialState(world, cfg, []);
player = state.players(1);

player.visualImpactTimer = 0.2;
face = pearExpressionState(player, [1, 0], 20);
assert(strcmp(face.name, 'pain'), ...
    'Impact pain must override the rope expression.');

player.visualImpactTimer = 0;
face = pearExpressionState(player, [3, 1], 20);
assert(strcmp(face.name, 'pulled') && face.gaze(1) > 0 && face.gaze(2) > 0, ...
    'A taut rope did not pull the pupils toward the tether direction.');

player.onGround = false;
player.vel = [0, 6];
face = pearExpressionState(player, [0, 0], 0);
assert(strcmp(face.name, 'joy'), ...
    'A freely rising pear did not select the joyful face.');

player.vel = [0, -6];
face = pearExpressionState(player, [0, 0], 0);
assert(strcmp(face.name, 'surprised'), ...
    'A fast-falling pear did not select the surprised face.');

player.pos = [1, 1];
player.vel = [5, 0];
player = resolveCollisions(player, [2, 0, 1, 3], 0.3);
assert(player.hitWall, 'Wall impact did not emit a visual collision event.');

player = state.players(1);
player.pos = [1, 1];
player.vel = [0, 5];
player = resolveCollisions(player, [0, 2.55, 3, 1], 0.3);
assert(player.hitCeiling, ...
    'Head impact did not emit a visual collision event.');
end
