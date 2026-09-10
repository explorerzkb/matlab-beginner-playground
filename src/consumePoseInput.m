function [input, cursor] = consumePoseInput(state, cursor, now, cfg, enabled)
%CONSUMEPOSEINPUT Latest directions and durable, expiring one-shot events.
% Call at the physics boundary. Advance cursor even when disabled/airborne.
if isempty(cursor), cursor=[0 0]; end
input.player=repmat(struct('left',false,'right',false,'jump',false),1,2);
input.safetyPause=~strcmp(state.phase,'active') || ...
    now-state.lastFrameTime>cfg.lossPauseSeconds;
for i=1:2
    p=state.player(i);
    fresh=p.valid && now>=p.lastTime && now-p.lastTime<=cfg.staleSeconds;
    active=enabled && ~input.safetyPause && fresh;
    input.player(i).left=active && p.direction<0;
    input.player(i).right=active && p.direction>0;
    input.player(i).jump=active && p.sequence>cursor(i) && ...
        now>=p.eventTime && now-p.eventTime<=cfg.eventTTL;
    cursor(i)=max(cursor(i),p.sequence);
end
end
