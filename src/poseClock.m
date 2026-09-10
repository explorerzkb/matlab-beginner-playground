function time = poseClock()
%POSECLOCK Monotonic seconds with a shared wall-clock origin across workers.
persistent origin clock
if isempty(clock)
    origin=posixtime(datetime('now','TimeZone','UTC'));
    clock=tic;
end
time=origin+toc(clock);
end
