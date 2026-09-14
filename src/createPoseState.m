function state = createPoseState()
%CREATEPOSESTATE Pure-data controller; usable with camera or recorded joints.
p = struct('anchor',[NaN NaN],'scale',NaN,'zero',0,'bodyY',NaN, ...
    'headY',NaN,'headGap',NaN,'angle',0,'direction',0,'lastTime',-inf, ...
    'lastBodyY',NaN,'lastHeadY',NaN,'jumpPhase','standing', ...
    'standSince',NaN,'sequence',0,'eventTime',-inf,'valid',false);
state.player = repmat(p,1,2);
state.phase = 'calibrating';
state.lastFrameTime = -inf;
state.samples = zeros(0,11);
state.badSince = NaN;
state.stableSince = NaN;
state.countdownUntil = inf;
state.reason = '两人上半身入镜，胸前双臂水平保持 2.5 秒';
end
