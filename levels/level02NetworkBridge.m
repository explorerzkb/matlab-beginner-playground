function level = level02NetworkBridge()
%LEVEL02NETWORKBRIDGE A non-interactive login-page card becomes a platform.

level.id = 2;
level.name = '第二关：北理桥校园网掉线';
level.instruction = '真实登录页只是一张图片；踩住下落卡片，合作越过分区边界。';
level.worldWidth = 46;
level.worldHeight = 13;
level.killY = -4;
level.spawn = [2.2, 1.0; 3.7, 1.0];
level.platforms = [ ...
     0.0, 0.0, 10.0, 1.0; ...
    18.5, 0.0,  7.0, 1.0; ...
    27.5, 0.0, 18.5, 1.0; ...
     7.0, 3.2,  3.0, 0.45; ...
    21.0, 3.8,  3.5, 0.45; ...
    31.0, 2.7,  4.0, 0.45; ...
    37.0, 4.3,  3.5, 0.45];
level.hazards = zeros(0, 4);
level.checkpoints = struct( ...
    'x', {0, 26.5}, ...
    'spawn', {[2.2, 1.0; 3.7, 1.0], [28.8, 1.0; 30.3, 1.0]});
level.finish = [42.0, 1.0, 2.8, 2.4];
level.mechanic.type = 'loginCard';
level.mechanic.cardBase = [10.1, 2.0, 8.1, 0.55];
level.mechanic.cardAmplitude = 1.35;
level.mechanic.cardPeriod = 5.4;
level.mechanic.fallHeight = 6.3;
level.mechanic.fallDuration = 2.2;
level.background = 'networkBridge';
end
