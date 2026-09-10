function testGameImageCache()
%TESTGAMEIMAGECACHE Verify sampled cache hits and file-change invalidation.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src'));
folder = tempname;
mkdir(folder);
guard = onCleanup(@() rmdir(folder, 's'));
path = fullfile(folder, 'cache-check.png');
first = zeros(8, 10, 3, 'uint8');
first(:, :, 1) = 211;
imwrite(first, path);
[loaded, map, alpha] = readGameImage(path, 2);
assert(isequal(size(loaded), [4, 5, 3]) && all(loaded(:, :, 1) == 211, 'all'), ...
    'Sampled runtime image was decoded incorrectly.');
assert(isempty(map) && isempty(alpha), 'Unexpected indexed or alpha data.');
cached = readGameImage(path, 2);
assert(isequal(loaded, cached), 'Cached runtime image changed between reads.');

second = zeros(9, 11, 3, 'uint8');
second(:, :, 2) = 173;
imwrite(second, path);
reloaded = readGameImage(path, 2);
assert(isequal(size(reloaded), [5, 6, 3]) && ...
    all(reloaded(:, :, 2) == 173, 'all'), ...
    'Runtime image cache did not invalidate after the file changed.');
clear guard;
end
