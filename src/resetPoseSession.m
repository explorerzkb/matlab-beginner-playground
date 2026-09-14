function session = resetPoseSession(session, recalibrate)
%RESETPOSESESSION Epoch rejects old in-flight packets across lifecycle changes.
session.epoch=session.epoch+1;
if isfield(session,'telemetry')
    session.telemetry=poseTelemetry(session.telemetry,'flush',poseClock(),[]);
end
session.cursor=[session.state.player.sequence];
if recalibrate
    session.state=createPoseState();
    session.cursor=[0 0];
else
    % Lifecycle flush must not bypass an unresolved identity ambiguity.
    if ~strcmp(session.state.phase,'recalibrate')
        session.state.phase='paused';
    end
    session.state.stableSince=NaN;
    session.state.badSince=NaN;
    for i=1:2
        session.state.player(i).direction=0;
        session.state.player(i).eventTime=-inf;
        session.state.player(i).jumpPhase='landing';
        session.state.player(i).standSince=NaN;
    end
end
end
