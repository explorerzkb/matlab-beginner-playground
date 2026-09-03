function cfg = gameConfig(projectRoot)
%GAMECONFIG Central numerical and runtime configuration.

cfg.projectRoot = projectRoot;
cfg.physics.fixedDt = 1 / 60;
cfg.physics.maxSubsteps = 5;
cfg.physics.gravity = -10;
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

cfg.render.targetHz = 30;
cfg.render.viewportWidth = 22;
cfg.render.worldHeight = 13;
cfg.render.marginY = 0.25;
cfg.render.fontName = 'Microsoft YaHei';
cfg.render.loginTextureStride = 2;

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
end
