function cfg = gameConfig(projectRoot)
%GAMECONFIG Central numerical and runtime configuration.

cfg.projectRoot = projectRoot;
cfg.physics.fixedDt = 1 / 60;
cfg.physics.maxSubsteps = 5;
cfg.physics.gravity = -25;
cfg.physics.runAcceleration = 42;
cfg.physics.airAcceleration = 24;
cfg.physics.maxRunSpeed = 8.0;
cfg.physics.groundFriction = 34;
cfg.physics.airDrag = 1.2;
cfg.physics.jumpSpeed = 15.0;
cfg.health.busDamage = 3;
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

cfg.health.maxHearts = 3;
cfg.health.minorDamage = 1;
cfg.health.hitInvulnerability = 0.85;
cfg.health.deathDelay = 0.45;
cfg.health.respawnProtection = 3;

cfg.tea.maxCarried = 2;
cfg.tea.useHoldDuration = 0.35;
cfg.tea.buffDuration = 8.0;
cfg.tea.groundAccelerationMultiplier = 1.45;
cfg.tea.airAccelerationMultiplier = 1.35;
cfg.tea.maxRunSpeedMultiplier = 1.25;
cfg.tea.jumpMultiplier = 1.30;
cfg.tea.visualWidthMultiplier = 1.25;
cfg.tea.capWidthMultiplier = 1.14;
cfg.tea.capHeightMultiplier = 1.08;
cfg.tea.outlineColor = [0.30, 0.14, 0.40];
cfg.tea.outlineAlpha = 0.34;
cfg.tea.outlineRadiusPixels = 1;

% Only the first ID has been explicitly supplied. Keep the other two
% placeholders visible so nobody can mistake inferred data for user input.
cfg.network.groupStudentIds = {'1120250036', '待填学号2', '待填学号3'};
cfg.network.passwordMask = '**********';
cfg.network.failureDeathDelay = 6;
cfg.network.timeoutExtraHold = 1;
cfg.network.successIp = '离线演示';
cfg.network.successTraffic = '--';
cfg.network.successDuration = '--';
cfg.network.successBalance = '--';

cfg.render.targetHz = 50;
cfg.render.windowSize = [960 540];
cfg.render.viewportWidth = 22;
cfg.render.viewportHeight = 13.4;
cfg.render.worldHeight = cfg.render.viewportHeight;
cfg.render.flightCameraCeiling = 180;
cfg.render.flightCameraResponse = 0.065;
cfg.render.campusCameraScale = 0.50;
cfg.render.campusZoomResponse = 2.0;
cfg.render.campusZoomAltitude = 18;
cfg.render.marginY = 0.25;
cfg.render.fontName = 'Microsoft YaHei';
cfg.render.graphicsSmoothing = 'off';
cfg.render.loginTextureStride = 2;
cfg.render.networkStateTextureStride = 2;
cfg.render.backgroundTextureStride = 4;
% The final bus panorama is revealed through a narrow moving crop, so it
% keeps its native pixels instead of sharing the coarse full-screen stride.
cfg.render.campusHandscrollTextureStride = 1;
cfg.render.teaTextureStride = 6;
cfg.render.cameraHorizontalDeadZone = [0.28, 0.67];
cfg.render.cameraVerticalDeadZone = [0.25, 0.72];
cfg.render.cameraHorizontalResponse = 0.18;
cfg.render.cameraVerticalResponse = 0.20;

cfg.runtime.testMode = false;
cfg.runtime.lowPowerMode = true;
cfg.runtime.validationMode = false;
cfg.runtime.validationScale = 'unrecorded';
cfg.runtime.validationPlannedRoute = 'unrecorded';
cfg.runtime.validationPlayer2Keys = 'unrecorded';
cfg.runtime.validationSessionLabel = 'unrecorded';
cfg.runtime.validationTwoPerson = false;
cfg.runtime.testDuration = 1.2;
cfg.runtime.inputCheckDuration = 5.0;
cfg.runtime.prologueDuration = 4.2;
cfg.runtime.resetHoldDuration = 0.8;
cfg.runtime.maxFrameDelta = 0.12;
cfg.runtime.enableAudio = true;

cfg.input = inputConfig();
cfg.presentation = presentationConfig();
cfg.assets.loginImage = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'campus-network-login.png');
cfg.assets.networkTimeoutImage = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'campus-network-timeout.png');
cfg.assets.networkAuthenticatedImage = fullfile(projectRoot, 'assets', ...
    'game', 'images', 'campus-network-authenticated.png');
cfg.assets.northLakeWest = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'north-lake-west-extended-v5.png');
cfg.assets.northLakeEast = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'north-lake-east-painted.jpg');
cfg.assets.sportsDefense = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'sports-open-v5.png');
cfg.assets.museum = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'museum-open-v5.png');
cfg.assets.museumSportsRoad = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'museum-sports-road-v11.png');
cfg.assets.museumSportsWest = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'museum-sports-west-v13.png');
cfg.assets.lastBusHandscroll = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'last-bus-handscroll-v30.png');
cfg.assets.cloudSky = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'cloud-sky-v30.png');
cfg.assets.campusContinuation = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'campus-continuation-v30.png');
cfg.assets.northLiBridge = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'north-li-bridge-v5.png');
cfg.assets.playground = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'playground-photo-v6.png');
cfg.assets.openPlaza = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'open-plaza-v5.png');
cfg.assets.greenbelt = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'backgrounds', 'campus-greenbelt-v4.png');
cfg.assets.bitEmblem = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'bit-emblem.jpg');
cfg.assets.teaSourceImage = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'items', 'tropical-iced-tea.jpg');
cfg.assets.teaSprite = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'items', 'tropical-iced-tea-cutout.png');
cfg.assets.alpacaSprite = fullfile(projectRoot, 'assets', 'game', ...
    'images', 'animals', 'alpaca-cheeky-v2.png');
end
