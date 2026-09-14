function testPoseDeviceCompatibility()
%TESTPOSEDEVICECOMPATIBILITY Camera modes vary across laptops and USB units.
assert(strcmp(selectPoseCameraResolution( ...
    {'1920x1080','640x480','320x240'},'640x480'),'640x480'));
assert(strcmp(selectPoseCameraResolution( ...
    {'1920x1080','1280x720','800x600'},'640x480'),'800x600'));
assert(strcmp(selectPoseCameraResolution({'1280x720'},'640x480'),'1280x720'));
assert(strcmp(selectPoseCameraResolution({'vendor-default'},'640x480'), ...
    'vendor-default'));
assert(isempty(selectPoseCameraResolution({},'640x480')));
fprintf('POSE DEVICE COMPATIBILITY PASSED: preferred and nearest camera modes\n');
end
