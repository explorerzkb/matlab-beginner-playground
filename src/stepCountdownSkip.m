function [heldTime,skip]=stepCountdownSkip(heldTime,spaceHeld,dt)
%STEPCOUNTDOWNSKIP A release interrupts the one-second opening shortcut.
if spaceHeld
    heldTime=heldTime+max(0,dt);
else
    heldTime=0;
end
skip=heldTime>=1-1e-9;
end
