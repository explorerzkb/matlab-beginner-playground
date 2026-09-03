function level = level01NorthLake()
%LEVEL01NORTHLAKE North Lake geese teach movement and rope cooperation.

level = baseLevel(1, '第一关：北湖动物借道', ...
    '等鹅群经过；一人站稳时，绳可以把同伴拉回来。', 44);
level.spawn = [2.2, 1.0; 3.7, 1.0];
level.platforms = [ ...
     0.0, 0.0, 12.0, 1.0; ...
    13.5, 0.0,  9.0, 1.0; ...
    24.0, 0.0,  8.0, 1.0; ...
    33.5, 0.0, 10.5, 1.0; ...
     6.8, 3.0,  4.2, 0.45; ...
    18.0, 2.6,  3.3, 0.45; ...
    28.0, 3.5,  3.2, 0.45];
level.checkpoints = struct( ...
    'x', {0, 23.5}, ...
    'spawn', {[2.2, 1.0; 3.7, 1.0], [24.8, 1.0; 26.3, 1.0]});
level.finish = [40.2, 1.0, 2.8, 2.4];
level.mechanic.type = 'geese';
level.mechanic.geese = [ ...
    15.5, 1.0, 1.15, 0.75, 2.0, 3.8, 0.0; ...
    26.5, 1.0, 1.15, 0.75, 1.6, 4.6, 1.8];
level.background = 'northLake';
end

function level = baseLevel(id, name, instruction, worldWidth)
level.id = id;
level.name = name;
level.instruction = instruction;
level.worldWidth = worldWidth;
level.worldHeight = 13;
level.killY = -4;
level.platforms = zeros(0, 4);
level.hazards = zeros(0, 4);
level.checkpoints = struct('x', {}, 'spawn', {});
level.finish = [worldWidth - 4, 1, 3, 2.4];
level.spawn = [2, 1; 3.5, 1];
level.mechanic = struct('type', 'none');
level.background = 'plain';
end
