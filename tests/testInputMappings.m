function testInputMappings()
%TESTINPUTMAPPINGS Verify primary, alternate, pause, reset, and quit keys.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
cfg = gameConfig(projectRoot);
fig = figure('Visible', 'off');
cleanupGuard = onCleanup(@() cleanupGame(fig));
installInputCallbacks(fig);

setappdata(fig, 'pressedKeys', {'a', 'w', 'leftarrow', 'uparrow'});
input = readInputSnapshot(fig, cfg.input);
assert(input.player(1).left && input.player(1).jump, ...
    'Player-one primary mapping was not recognized.');
assert(input.player(2).left && input.player(2).jump, ...
    'Player-two arrow mapping was not recognized.');

setappdata(fig, 'pressedKeys', ...
    {'j', 'l', 'i', 'escape', 'r', 'q', 'space'});
input = readInputSnapshot(fig, cfg.input);
assert(input.player(2).left && input.player(2).right && input.player(2).jump, ...
    'Player-two J/L/I alternate mapping was not recognized.');
assert(input.pause && input.reset && input.quit, ...
    'Pause, reset, or quit mapping was not recognized.');
assert(input.useItem, 'Global item-use mapping was not recognized.');
clear cleanupGuard;
end
