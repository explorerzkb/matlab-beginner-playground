function testPixelRectToWorld()
%TESTPIXELRECTTOWORLD Verify one uniform, top-left pixel transformation.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src'));

pageRect = [10, 2, 20, 10];
pixelSize = [200, 100];
pixelRects = [20, 10, 40, 20; 140, 70, 20, 10];
mapped = pixelRectToWorld(pageRect, pixelRects, pixelSize);
expected = [12, 9, 4, 2; 24, 4, 2, 1];
assert(all(abs(mapped - expected) < 1e-12, 'all'), ...
    'Top-left source pixels did not map to the expected world rectangles.');

didRejectStretch = false;
try
    pixelRectToWorld([10, 2, 21, 10], pixelRects, pixelSize);
catch exception
    didRejectStretch = strcmp(exception.identifier, ...
        'matlabHi:NonUniformPageScale');
end
assert(didRejectStretch, ...
    'The mapping helper accepted a non-uniformly stretched page.');
end
