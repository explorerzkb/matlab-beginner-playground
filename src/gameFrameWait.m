function gameFrameWait(action)
%GAMEFRAMEWAIT Yield without drawnow or Windows' ~15.6-ms JVM sleep rounding.
% The bundled Windows helper uses a process-local high-resolution timer.
persistent waiter portableOnly warningSent
if nargin>0 && strcmp(action,'close')
    if ~isempty(waiter), waiter.Dispose(); waiter=[]; end
    return;
end
if isempty(portableOnly), portableOnly=false; end
if isempty(warningSent), warningSent=false; end
if ispc && ~portableOnly
    try
        if isempty(waiter)
            projectRoot=fileparts(fileparts(mfilename('fullpath')));
            assembly=fullfile(projectRoot,'assets','game','runtime','windows', ...
                'MatlabHiTiming.dll');
            NET.addAssembly(assembly);
            waiter=MatlabHi.HighResolutionWaiter();
        end
        waiter.Wait();
        return;
    catch exception
        if ~isempty(waiter)
            try
                waiter.Dispose();
            catch %#ok<CTCH>
                % The portable path below is still safe if disposal failed.
            end
        end
        waiter=[]; portableOnly=true;
        if ~warningSent
            warning('matlabHi:TimingFallback', ...
                'High-resolution timer unavailable; using portable wait: %s', ...
                exception.message);
            warningSent=true;
        end
    end
end
java.util.concurrent.locks.LockSupport.parkNanos(int64(250000));
end
