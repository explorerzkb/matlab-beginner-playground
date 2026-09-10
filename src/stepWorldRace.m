function state = stepWorldRace(state, world, dt)
%STEPWORLDRACE Eight fixed-speed runners; neither losing nor waiting locks exits.
data=world.mechanic.race;
positions=[state.players(1).pos(1),state.players(2).pos(1)];
if ~isfield(state.levelState,'race')
    state.levelState.race=struct('phase','waiting','elapsed',0, ...
        'runnerX',repmat(data.startX,1,8),'finishTimes',[inf inf], ...
        'previousX',positions,'teamWon',false);
end
race=state.levelState.race;
if strcmp(race.phase,'waiting')
    if state.levelState.network.authenticated && all(positions>=data.startX)
        race.phase='running';
        % Triggering on both pears prevents starting without the partner.
        race.previousX=positions;
    end
elseif strcmp(race.phase,'running')
    before=race.elapsed;
    race.elapsed=before+dt;
    race.runnerX=min(data.finishX,data.startX+data.speeds*race.elapsed);
    for p=1:2
        if isinf(race.finishTimes(p)) && positions(p)>=data.finishX
            travel=positions(p)-race.previousX(p);
            fraction=1;
            if travel>0
                fraction=min(1,max(0,(data.finishX-race.previousX(p))/travel));
            end
            race.finishTimes(p)=before+fraction*dt;
        end
    end
    if all(isfinite(race.finishTimes)) && all(race.runnerX>=data.finishX)
        race.phase='finished';
        race.teamWon=max(race.finishTimes)< ...
            (data.finishX-data.startX)/max(data.speeds);
    end
end
race.previousX=positions;
state.levelState.race=race;
end
