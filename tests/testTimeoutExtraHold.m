function testTimeoutExtraHold()
%TESTTIMEOUTEXTRAHOLD The normal harmless timeout must hold one extra second.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=gameConfig(root); world=continuousCampusWorld();
s=createInitialState(world,cfg,[]); s=stepLevel(s,world,cfg,0);
s.levelState.network.pageMode='timeout';
s.players(1).pos(2)=world.killY-1;
s=stepLevel(s,world,cfg,0);
assert(~s.requestReset && s.levelState.network.timeoutResetTimer==1);
for tick=1:59
    s=stepLevel(s,world,cfg,cfg.physics.fixedDt);
    assert(~s.requestReset && strcmp(s.levelState.network.pageMode,'timeout'));
end
s=stepLevel(s,world,cfg,2*cfg.physics.fixedDt);
assert(s.requestReset && s.status.currentHearts==3 && s.stats.damageTaken==0);
s=resetToCheckpoint(s,world,cfg);
assert(~isfield(s.levelState.network,'timeoutResetTimer'));
fprintf('TIMEOUT HOLD PASSED: extra 1 second on actual harmless reset path\n');
end
