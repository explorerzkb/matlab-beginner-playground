function session = pollPoseSession(session, now)
%POLLPOSESESSION Never wait for inference. At most one frame is in flight.
packet=poll(session.results,0);
if ~isempty(packet)
    switch packet.kind
        case 'ready'
            session.ready=true;
        case 'error'
            session.error=packet.message;
            session.inflight=false;
        case 'frame'
            session.inflight=false;
            session.packets=session.packets+1;
            session.lastPacket=packet;
            session.telemetry=poseTelemetry(session.telemetry,'packet',now, ...
                struct('packet',packet,'cfg',session.cfg));
            if packet.epoch==session.epoch && now>=packet.captureTime && ...
                    now-packet.captureTime<=session.cfg.staleSeconds
                session.state=stepPoseController(session.state,packet.points, ...
                    packet.imageSize,packet.captureTime,session.cfg);
                if isfield(packet,'preview'), session.preview=packet.preview; end
            end
    end
end
if ~isempty(session.error), return; end
if strcmp(session.future.State,'finished')
    session.error='Pose worker stopped; switch to keyboard or restart pose session.';
    return;
end
if session.inflight && now-session.sentTime>session.cfg.workerTimeout
    session.error='Camera/inference timed out; gameplay paused.';
    return;
end
if session.ready && ~session.inflight && ...
        now-session.lastRequest>=1/session.cfg.requestHz
    session.nextId=session.nextId+1;
    request=struct('kind','next','id',session.nextId,'epoch',session.epoch, ...
        'preview',session.previewRequested);
    send(session.commands,request);
    session.inflight=true; session.sentTime=now; session.lastRequest=now;
end
end
