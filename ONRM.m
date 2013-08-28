
% AG1 script
% This script loads the paths for the experiment, and creates
% the variable thePath in the workspace.

pwd
thePath.start = pwd;

[pathstr,curr_dir,ext,versn] = fileparts(pwd);
if ~strcmp(curr_dir,'OldNewResponseModality')
    fprintf(['You must start the experiment from the ' curr_dir ' directory. Go there and try again.\n']);
else
    thePath.script = fullfile(thePath.start, 'script');
    thePath.stim = fullfile(thePath.start, 'stim');
    thePath.data = fullfile(thePath.start, 'data');
    thePath.list = fullfile(thePath.start, 'list');
    thePath.main = fullfile(thePath.start);
    % add more dirs above

    % Add relevant paths for this experiment
    names = fieldnames(thePath);
    for f = 1:length(names)
        eval(['addpath(thePath.' names{f} ')']);
        fprintf(['added ' names{f} '\n']);
    end
    cd(thePath.start);
end
