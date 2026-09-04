function cfg = gameConfig(projectRoot)
%GAMECONFIG Central numerical and runtime configuration.

cfg.projectRoot = projectRoot;
cfg.physics.fixedDt = 1 / 60;
cfg.physics.maxSubsteps = 5;
cfg.physics.gravity = -20;
cfg.physics.runAcceleration = 42;
cfg.physics.airAcceleration = 24;
cfg.physics.maxRunSpeed = 8.0;
cfg.physics.groundFriction = 34;
cfg.physics.airDrag = 1.2;
cfg.physics.jumpSpeed = 12.2;
cfg.physics.maxFallSpeed = -22;
cfg.physics.collisionEpsilon = 1e-7;

cfg.player.width = 1.05;
cfg.player.height = 1.45;
cfg.player.mass = 1.0;

cfg.rope.length = 5.2;
cfg.rope.stiffness = 34;
cfg.rope.damping = 6.5;
cfg.rope.maxTension = 72;
cfg.rope.positionCorrection = 0.62;
cfg.rope.pullCountThreshold = 8;

cfg.break.maxValue = 6;
cfg.break.minorIncrease = 1;
cfg.break.majorIncrease = 2;
cfg.break.respawnValue = 3;
cfg.break.hitCooldown = 0.8;

cfg.tea.maxCarried = 2;
cfg.tea.breakReduction = 2;
cfg.tea.useHoldDuration = 0.35;
cfg.tea.buffDuration = 6.0;
cfg.tea.runAccelerationMultiplier = 1.15;
cfg.tea.jumpMultiplier = 1.08;
cfg.tea.knockbackMultiplier = 0.50;
cfg.tea.visualWidthMultiplier = 1.25;
cfg.tea.capWidthMultiplier = 1.14;
cfg.tea.capHeightMultiplier = 1.08;
cfg.tea.outlineColor = [0.30, 0.14, 0.40];
cfg.tea.outlineAlpha = 0.34;
cfg.tea.outlineRadiusPixels = 1;

% Replace these three explicit placeholders with the group's real student
% IDs after the user supplies them. Do not infer personal data elsewhere.
cfg.network.groupStudentIds = {'待填学号1', '待填学号2', '待填学号3'};
cfg.network.passwordMask = '**********';

cfg.render.targetHz = 30;
cfg.render.viewportWidth = 22;
cfg.render.worldHeight = 13;
cfg.render.marginY = 0.25;
cfg.render.fontName = 'Microsoft YaHei';
cfg.render.loginTextureStride = 2;
cfg.render.backgroundTextureStride = 2;
cfg.render.teaTextureStride = 6;

cfg.runtime.testMode = false;
cfg.runtime.lowPowerMode = false;
cfg.runtime.testDuration = 1.2;
cfg.runtime.inputCheckDuration = 5.0;
cfg.runtime.prologueDuration = 10.0;
cfg.runtime.resetHoldDuration = 0.8;
cfg.runtime.maxFrameDelta = 0.12;
cfg.runtime.enableAudio = true;

cfg.input = inputConfig();
cfg.presentation = presentationConfig();
cfg.assets.loginImage = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'campus-network-login.png');
cfg.assets.northLakeWest = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'north-lake-west-painted.jpg');
cfg.assets.northLakeEast = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'north-lake-east-painted.jpg');
cfg.assets.sportsDefense = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'sports-defense-painted.jpg');
cfg.assets.museum = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'museum-painted.jpg');
cfg.assets.bitEmblem = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'bit-emblem.jpg');
cfg.assets.teaSourceImage = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'items', 'tropical-iced-tea.jpg');
cfg.assets.teaSprite = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'items', 'tropical-iced-tea-cutout.png');
cfg.assets.alpacaSprite = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'animals', 'alpaca-cheeky-v2.png');
end
