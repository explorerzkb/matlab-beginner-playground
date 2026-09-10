function runCodeChecks()
%RUNCODECHECKS Run MATLAB Code Analyzer over every current .m source file.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
folders = {projectRoot, fullfile(projectRoot, 'config'), ...
    fullfile(projectRoot, 'levels'), fullfile(projectRoot, 'src'), ...
    fullfile(projectRoot, 'tests')};
issueCount = 0;
for folderIndex = 1:numel(folders)
    files = dir(fullfile(folders{folderIndex}, '*.m'));
    for fileIndex = 1:numel(files)
        path = fullfile(files(fileIndex).folder, files(fileIndex).name);
        messages = checkcode(path, '-id');
        for messageIndex = 1:numel(messages)
            issueCount = issueCount + 1;
            fprintf('%s:%d [%s] %s\n', path, messages(messageIndex).line, ...
                messages(messageIndex).id, messages(messageIndex).message);
        end
    end
end
if issueCount > 0
    error('matlabHi:CodeAnalyzerIssues', ...
        'MATLAB Code Analyzer found %d issue(s).', issueCount);
end
fprintf('MATLAB CODE ANALYZER PASSED WITH ZERO ISSUES\n');
end
