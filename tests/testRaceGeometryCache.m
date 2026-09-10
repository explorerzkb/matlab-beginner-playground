function testRaceGeometryCache()
%TESTRACEGEOMETRYCACHE Cache must preserve exact original graphic coordinates.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'config'),fullfile(root,'levels'));
cfg=gameConfig(root); level=continuousCampusWorld();
fig=figure('Visible','off'); guard=onCleanup(@() delete(fig)); ax=axes(fig);
state=createPerformanceScene(level,cfg,82);
state=renderFrame(fig,ax,state,level,cfg); h=state.render.handles;
for phase={'waiting','running','finished'}
    for time=[0 .2 .4]
        state.levelState.race.phase=phase{1}; state.levelState.race.elapsed=time;
        state.levelTime=state.levelTime+1;
        h=updateRaceRunners(h,state,level,cfg);
        cached=get(h.raceRunners(:,1),'Vertices');
        cachedX=get(h.raceRunners(:,2),'XData');
        cachedY=get(h.raceRunners(:,2),'YData');
        reference=rmfield(h,{'raceGeometryKey','raceRenderTime'});
        reference=updateRaceRunners(reference,state,level,cfg);
        assert(isequaln(cached,get(reference.raceRunners(:,1),'Vertices')));
        assert(isequaln(cachedX,get(reference.raceRunners(:,2),'XData')));
        assert(isequaln(cachedY,get(reference.raceRunners(:,2),'YData')));
    end
end
clear guard;
fprintf('RACE GEOMETRY CACHE PASSED: exact coordinates in all animation phases\n');
end
