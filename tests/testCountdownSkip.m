function testCountdownSkip()
%TESTCOUNTDOWNSKIP Continuous hold, release reset, no item consumption.
held=0;
for i=1:59
    [held,skip]=stepCountdownSkip(held,true,1/60);
    assert(~skip);
end
[~,skip]=stepCountdownSkip(held,true,1/60); assert(skip);
[held,skip]=stepCountdownSkip(held,false,1/60); assert(held==0 && ~skip);
root=fileparts(fileparts(mfilename('fullpath'))); cfg=gameConfig(root);
fig=figure('Visible','off'); guard=onCleanup(@() delete(fig));
setappdata(fig,'pressedKeys',{'space'});
setappdata(fig,'suppressItemUntilRelease',true);
input=readInputSnapshot(fig,cfg.input); assert(~input.useItem);
setappdata(fig,'pressedKeys',{}); readInputSnapshot(fig,cfg.input);
setappdata(fig,'pressedKeys',{'space'});
input=readInputSnapshot(fig,cfg.input); assert(input.useItem);
ax=axes(fig); setappdata(fig,'closeRequested',false);
clock=tic; continued=runInputCheck(fig,ax,cfg); elapsed=toc(clock);
assert(continued && elapsed>=1 && elapsed<cfg.runtime.inputCheckDuration-1, ...
    'Actual opening screen did not skip after the hold.');
input=readInputSnapshot(fig,cfg.input); assert(~input.useItem);
fprintf('Actual countdown screen skipped after %.2f seconds including drawing\n',elapsed);
clear guard;
fprintf('COUNTDOWN SKIP PASSED: one-second hold, release reset, no item carryover\n');
end
