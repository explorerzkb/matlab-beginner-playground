function report = summarizeWindowsValidation(projectRoot)
%SUMMARIZEWINDOWSVALIDATION Audit whether every target-PC gate has evidence.

if nargin < 1, projectRoot = fileparts(mfilename('fullpath')); end
folder = fullfile(projectRoot, 'windows-validation-results');
requiredScales = {'100%', '125%', '150%'};
report.automaticScales = false(1, 3);
report.interactiveScales = false(1, 3);
report.routes = struct('upper', false, 'lower', false);
report.keys = struct('primary', false, 'alternate', false);
report.completedSessions = 0;
report.humanConfirmedSessions = 0;

if isfolder(folder)
    files = dir(fullfile(folder, 'validation-*.txt'));
    for index = 1:numel(files)
        body = fileread(fullfile(files(index).folder, files(index).name));
        if contains(body, 'ispc: 1') && ...
                contains(body, 'AUTOMATIC PERFORMANCE AND KEYBOARD CHECKS: PASS')
            scale = lineValue(body, 'Scale label');
            fps = numberList(body, 'Three minimum FPS results');
            scaleIndex = find(strcmp(requiredScales, scale), 1);
            if ~isempty(scaleIndex) && numel(fps) == 3 && all(fps > 40)
                report.automaticScales(scaleIndex) = true;
            end
        end
    end

    files = dir(fullfile(folder, 'interactive-*.txt'));
    sessions = strings(0, 1);
    for index = 1:numel(files)
        body = fileread(fullfile(files(index).folder, files(index).name));
        scale = lineValue(body, 'Scale');
        route = lineValue(body, 'Actual route');
        planned = lineValue(body, 'Planned route');
        keys = lineValue(body, 'Player 2 keys');
        label = lineValue(body, 'Session label');
        sessionKey = metadataKey(label, scale, planned, keys);
        complete = contains(body, 'ispc: 1') && ...
            contains(body, 'Completed: 1') && ...
            contains(body, 'Two-person session: 1') && ...
            ~isempty(label) && strcmp(route, planned) && allPocketsAbove40(body);
        if complete && ~any(sessions == sessionKey)
            sessions(end + 1, 1) = sessionKey; %#ok<AGROW>
            report.completedSessions = report.completedSessions + 1;
            scaleIndex = find(strcmp(requiredScales, scale), 1);
            if ~isempty(scaleIndex), report.interactiveScales(scaleIndex) = true; end
            if isfield(report.routes, route), report.routes.(route) = true; end
            if isfield(report.keys, keys), report.keys.(keys) = true; end
        end
    end

    files = dir(fullfile(folder, 'human-*.txt'));
    reviews = strings(0, 1);
    for index = 1:numel(files)
        body = fileread(fullfile(files(index).folder, files(index).name));
        label = lineValue(body, 'Session label');
        scale = lineValue(body, 'Scale');
        route = lineValue(body, 'Planned route');
        keys = lineValue(body, 'Player 2 keys');
        reviewKey = metadataKey(label, scale, route, keys);
        passed = contains(body, 'ispc: 1') && ...
            contains(body, 'Two-person session: 1') && ...
            contains(body, 'Visual readability confirmed: 1') && ...
            contains(body, 'Control response confirmed: 1') && ~isempty(label);
        if passed && ~any(reviews == reviewKey)
            reviews(end + 1, 1) = reviewKey; %#ok<AGROW>
        end
    end
    report.humanConfirmedSessions = sum(ismember(sessions, reviews));
end

report.allPassed = all(report.automaticScales) && ...
    all(report.interactiveScales) && report.completedSessions >= 3 && ...
    report.humanConfirmedSessions >= 3 && report.routes.upper && ...
    report.routes.lower && report.keys.primary && report.keys.alternate;
fprintf('\nWINDOWS VALIDATION COVERAGE\n');
fprintf('Automatic pass at 100/125/150%%: %d / %d / %d\n', report.automaticScales);
fprintf('Full playthrough at 100/125/150%%: %d / %d / %d\n', report.interactiveScales);
fprintf('Completed two-person sessions: %d / 3\n', report.completedSessions);
fprintf('Sessions with visual/control confirmation: %d / 3\n', ...
    report.humanConfirmedSessions);
fprintf('Routes upper/lower: %d / %d\n', report.routes.upper, report.routes.lower);
fprintf('Player-2 keys primary/alternate: %d / %d\n', ...
    report.keys.primary, report.keys.alternate);
fprintf('OVERALL TARGET-WINDOWS EVIDENCE: %s\n\n', passLabel(report.allPassed));
end

function key = metadataKey(label, scale, route, keys)
key = string(strjoin({label, scale, route, keys}, '|'));
end

function value = lineValue(body, label)
token = regexp(body, ['(?m)^', regexptranslate('escape', label), ...
    ':\s*([^\r\n]+)$'], 'tokens', 'once');
if isempty(token), value = ''; else, value = strtrim(token{1}); end
end

function values = numberList(body, label)
text = lineValue(body, label);
tokens = regexp(text, '[0-9]+(?:\.[0-9]+)?', 'match');
values = str2double(tokens);
end

function passed = allPocketsAbove40(body)
names = {'north-lake', 'network-race', 'traffic', 'bicycle', 'campus'};
passed = true;
for index = 1:numel(names)
    token = regexp(body, ['(?m)^', names{index}, ...
        '\s+([0-9]+(?:\.[0-9]+)?) FPS.*enough sample: 1$'], ...
        'tokens', 'once');
    passed = passed && ~isempty(token) && str2double(token{1}) > 40;
end
end

function value = passLabel(passed)
if passed, value = 'PASS'; else, value = 'INCOMPLETE'; end
end
