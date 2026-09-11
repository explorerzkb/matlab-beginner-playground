function gameFrameWait(action)
%GAMEFRAMEWAIT Yield without drawnow or Windows' ~15.6-ms JVM sleep rounding.
% The bundled Windows helper uses a process-local high-resolution timer.
persistent waiter
if nargin>0 && strcmp(action,'close')
    if ~isempty(waiter), waiter.Dispose(); waiter=[]; end
    return;
end
if ispc
    if isempty(waiter)
        NET.addAssembly(fullfile(fileparts(mfilename('fullpath')),'native','MatlabHiTiming.dll'));
        waiter=MatlabHi.HighResolutionWaiter();
    end
    waiter.Wait();
else
    java.util.concurrent.locks.LockSupport.parkNanos(int64(250000));
end
end
