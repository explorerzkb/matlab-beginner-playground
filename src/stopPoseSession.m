function stopPoseSession(session)
%STOPPOSESESSION Stop only this session; never delete a user's existing pool.
if isempty(session), return; end
try
    send(session.commands,struct('kind','stop'));
    cancel(session.future);
catch exception
    warning('matlabHi:PoseCleanup','%s',exception.message);
end
if session.ownedPool && isvalid(session.pool)
    delete(session.pool);
end
end
