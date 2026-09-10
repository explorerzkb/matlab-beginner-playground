function stopPoseSession(session)
%STOPPOSESESSION Stop only this session; never delete a user's existing pool.
if isempty(session), return; end
try
    if isvalid(session.future)
        send(session.commands,struct('kind','stop'));
        cancel(session.future);
    end
catch exception
    warning('matlabHi:PoseCleanup','%s',exception.message);
end
if session.ownedPool && isvalid(session.pool)
    delete(session.pool);
end
end
