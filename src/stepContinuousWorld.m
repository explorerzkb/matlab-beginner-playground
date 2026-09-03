function state = stepContinuousWorld(state, world, cfg, dt)
%STEPCONTINUOUSWORLD Advance global region, checkpoint, and finish state.

state.levelState.colliders = world.platforms;
centreX = mean([state.players(1).pos(1), state.players(2).pos(1)]);
regionIndex = findRegionIndex(centreX, world.regions);
state.world.previousRegionIndex = state.world.activeRegionIndex;
state.world.activeRegionIndex = regionIndex;
state.levelState.activeRegionId = world.regions(regionIndex).id;
state = collectTeaPickups(state, world);
state = stepWorldAnimals(state, world, cfg, dt);
state = stepWorldNetwork(state, world, cfg, dt);
state = stepWorldTraffic(state, world, cfg, dt);
state = stepWorldLexue(state, world, cfg, dt);

minimumX = min(state.players(1).pos(1), state.players(2).pos(1));
for index = state.checkpointIndex + 1:numel(world.checkpoints)
    if checkpointSatisfied(state, world.checkpoints(index), minimumX)
        state.checkpointIndex = index;
    else
        break;
    end
end

if state.players(1).pos(2) < world.killY || ...
        state.players(2).pos(2) < world.killY
    state = applyBreakEvent(state, cfg, 'major');
end

state.completed = playerOverlaps(state.players(1), world.finish) && ...
    playerOverlaps(state.players(2), world.finish);

state.trajectorySampleClock = state.trajectorySampleClock + dt;
if state.trajectorySampleClock >= 0.1
    state.trajectorySampleClock = state.trajectorySampleClock - 0.1;
    sample = [state.levelTime, state.players(1).pos, state.players(2).pos];
    state.levelTrajectory(end + 1, :) = sample;
    state.stats.trajectory(end + 1, :) = [world.id, state.stats.elapsed, ...
        state.players(1).pos, state.players(2).pos];
end

if any(~isfinite([state.players(1).pos, state.players(1).vel, ...
        state.players(2).pos, state.players(2).vel]))
    error('matlabHi:NonFinitePhysics', ...
        '物理状态出现 NaN 或 Inf，游戏已安全停止。');
end

% cfg is part of the public stepping interface. Later continuous systems use
% it for break events, timed traffic, and consumables.
if cfg.break.maxValue <= 0
    error('matlabHi:InvalidBreakConfig', '破防值上限必须为正数。');
end
end

function tf = checkpointSatisfied(state, checkpoint, minimumX)
switch checkpoint.trigger
    case 'networkCheckbox'
        tf = minimumX >= checkpoint.x && ...
            state.levelState.network.rememberChecked;
    case 'lexueCourseCard'
        tf = minimumX >= checkpoint.x && ...
            state.levelState.lexue.courseCardReached;
    otherwise
        tf = minimumX >= checkpoint.x;
end
end

function index = findRegionIndex(x, regions)
index = numel(regions);
for candidate = 1:numel(regions)
    range = regions(candidate).xRange;
    if x >= range(1) && x < range(2)
        index = candidate;
        return;
    end
end
end

function tf = playerOverlaps(player, rect)
halfWidth = player.size(1) / 2;
tf = player.pos(1) + halfWidth > rect(1) && ...
     player.pos(1) - halfWidth < rect(1) + rect(3) && ...
     player.pos(2) + player.size(2) > rect(2) && ...
     player.pos(2) < rect(2) + rect(4);
end
