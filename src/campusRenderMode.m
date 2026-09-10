function mode = campusRenderMode(state,world)
%CAMPUSRENDERMODE Hide all ground scenery during the compulsory flight.
mode = 'world';
if ~strcmp(world.mechanic.type,'continuousCampus') || ...
        ~isfield(state.levelState,'bicycle')
    return;
end
if strcmp(state.levelState.bicycle.phase,'flight')
    mode = 'sky';
elseif state.levelState.bicycle.landed && ...
        min([state.players(1).pos(1),state.players(2).pos(1)])>=170
    mode = 'campus';
end
end
