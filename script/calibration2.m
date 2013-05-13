function calibration2()

maxSize = 0; % if you want to change the movies aspect ratio change maxSize 0-25.  0 doesn't scale it, 25 makes it 25 degrees
bgColor = [128 128 128]; %background color of screen
% numRepetitions = 1; %how many times to play each video?  Use this if you are planning to show very few or very short files
fixR = 0.25; %radius of fixation point (deg)
fixColor = [0 0 0]; %color of fixation point
% numberOfFix = 4; %number of trials that will be fixation
fixDur = 2; %duration of fixation period (s)
% imageDur = 2; %if presenting an image (as opposed to a video) how long should it remain on the screen? (s)
% restInterval = 300; %minimum time between rests (sec)

%% system specific info
[d hostname]=system('hostname');
switch strcat(hostname)
    case 'kalanit-grill-spectors-macbookpro41.local' %powerbook 'Andre the Giant'
        projDir = '/Users/kalanit/Experiments/SpatiotemporalLearning/Pilot14/RunExperiment/code';
    case 'kweb-com.local' %george w/ 454dell
        projDir = '/Users/kalanit/Experiments/DynamicStim/eyetracking_pilot';
    case 'skidder' %remus's desktop, using Dell LCD
        projDir = '/Users/kalanit/Experiments/DynamicStim/eyetracking_pilot';
    case 'Alan-Gordons-MacBook-Pro.local'
        projDir = '/Users/alangordon/Studies/OldNewResponseModality/data';
    otherwise
        error('Unknown host name - is this computer still connected to the network?')
end

tmp = inputdlg({'Enter viewing distance (cm)', 'Which display is being used (1) = LCD, (2) = CRT, (3) = Integrated display'}, 'Display information', 1, {'57.5', '2'} );
viewingDistance = str2double(tmp{1});
displayUsed = str2double(tmp{2});

if displayUsed == 1 %indicates Either Dell 2005FPW
    nativeResolution = [1680 1050]; %script will force the screen to match these dimensions
    pixPerCM = 400/10.35; % %measured by remus @ resolution = 1680x1050 (true for both Dell 2005FPW and 2009Wt)
    % cal = LoadCalFile('EyetrackerDell2005FPW'); %true on Andre, not calibrated on George (remus 10/19/10)
elseif displayUsed == 2
    %load info for CRT
    %     nativeResolution = [1600 1200]; %script will force the screen to match these dimensions
    %     pixPerCM = 400/9.9; %measured by remus @ resolution = 1600x1200 (7/20/10, on mitsubishi diamondpro2070sb)
    nativeResolution = [1024 768]; % changed from genuine nativeResolution (1600x1200) since Eyelink DataViewer doesn't scale videos
    pixPerCM = 400/15.05; %measured by remus @ resolution = 1024x768 (11/30/10, on mitsubishi diamondpro2070sb)
    if ~isequal(nativeResolution ,[1600 1200]) &&  ~isequal(nativeResolution,[ 1024 768])
        disp('Warning: The screen is set to a non native resolution, scaling will not be reliable');
        % to calculate on a different native resolution put an image of 400
        % pixels and divide by the size in cm on the screen
    end
    nativeHz = 85;
    % cal = LoadCalFile('EyeTrackerCRT'); %indicates mitsubishi diamondpro2070sb used with eyelink tracker -- true on Andre, not calibrated on George (remus 10/19/10)

elseif displayUsed == 3
    if ~strcmpi(hostname, 'kalanit-grill-spectors-macbookpro41.local') %using George (15" macbook) or some other machine
        error('Integrated screen dimensions not yet measured - see code for examples')
    end
    %presuming we're using Andre
    nativeResoultion = [1920 1200];
    pixPerCM = 400/7.7; %measured by remus @ resolution = 1920X1200 (for Andre (17" macbook) integrated display)
else
    error('unknown display')
end

%% get subject name
cd(projDir)
prompt = {'subject initials (max 2 characters)'};
answer = inputdlg(prompt, 'Info Please');
subject = answer{1};
if length(subject) > 2
    error('subject intials cannot be more than 2 letters') % because we have a limit of 8 characters for filename other 6 are date
end

% %% load interest area file (if applicable)
% %Try to load interest areas for each stimulus set - note if no IA file exists
% %As of December 2010, we are not using these conventions.  Instead, we output a text file that lists the IAS files for each trial and load those files in data viewer.
% %This block is kept here since it doesn't hurt and is a decent proof-of-concept for online loading of interest areas
% try
%     tmp = load(fullfile(stim1Dir, 'interestAreas.mat'));
%     IADefs1 = tmp.IADefs;
%     loadInterestAreas1 = 1;
% catch NOIAFORSTIM1
%     fprintf('No interest areas are loaded for stimulus set 1\n');
%     loadInterestAreas1 = 0;
% end
%
% try
%     tmp = load(fullfile(stim2Dir, 'interestAreas.mat'));
%     IADefs2 = tmp.IADefs;
%     loadInterestAreas2 = 1;
% catch NOIAFORSTIM2
%     fprintf('No interest areas are loaded for stimulus set 2\n');
%     loadInterestAreas2 = 0;
% end

%% Do eyetracker setup
% STEP 1
% Initialization of the connection with the Eyelink Gazetracker.
% exit program if this fails.
if Eyelink('initialize') ~= 0
    fprintf('error in connecting to the eye tracker\n\n');
    return;
end

% STEP 2
% Added a dialog box to set your own EDF file name before opening
% experiment graphics. Make sure the entered EDF file name is 1 to 8
% characters in length and only numbers or letters are allowed.
prompt = {'Enter tracker EDF file name (Max 8 characters, only letters and numerals)'};
dlg_title = 'Create EDF file';
tmp = clock;
year = num2str(tmp(1));
year = year(3:4);
month = num2str(tmp(2), '%02.0f');
day = num2str(tmp(3), '%02.0f');
def     = {strcat(subject,year,month,day)};
answer  = inputdlg(prompt,dlg_title,1,def);
edfFile = answer{1};

%% Initialize Screens & continue with eyetracker setup
screens=Screen('Screens');
screenNumber=max(screens);

if screenNumber < 2
    HideCursor; % Hide the mouse cursor
end

if exist('nativeHz','var') %if using CRT
    oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2), nativeHz);
    disp('refresh set to nativeHz');
else
    oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2));
end

[w, rect] = Screen('OpenWindow', screenNumber, bgColor);
Priority(MaxPriority(w));
ListenChar(0)


% %%do gamma correction (modified from CalDemo)
originalGammaTable = Screen('ReadNormalizedGammaTable',w);
% cal = SetGammaMethod(cal,0);
% % Make the desired linear output, then convert.
% linearValues = ones(3,1)*linspace(0,1,length(cal.gammaTable));
% clutValues = PrimaryToSettings(cal,linearValues);
% Screen('LoadNormalizedGammaTable',w,clutValues');


%%Initial flip
Screen('Flip', w);
FlushEvents('keyDown'); %initial flush

%%locate screen center
[center(1), center(2)] = RectCenter(rect);


% STEP 4
% Provide Eyelink with details about the graphics environment
% and perform some initializations. The information is returned
% in a structure that also contains useful defaults
% and control codes (e.g. tracker state bit and Eyelink key values).
el=EyelinkInitDefaults(w);

[v vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

% open file to record data to
i = Eyelink('Openfile', edfFile);
if i~=0
    printf('Cannot create EDF file ''%s'' ', edffilename);
    Eyelink( 'Shutdown');
    return;
end

Eyelink('command', 'add_file_preamble_text ''dynamic stim eyetracking''');

% STEP 5
% SET UP TRACKER CONFIGURATION
% Setting the proper recording resolution, proper calibration type,
% as well as the data file content;
[width, height]=Screen('WindowSize', screenNumber);
Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
%SETS 'screen_pixel_coords' field in *.ini file on host computer (in this case,
%'physical.ini' to selected values

Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
%notes that last change in edf file via message

% set calibration type.
Eyelink('command', 'calibration_type = HV9');
%determines how many dots we will be using for calibration , set in calibr.ini

% set parser (conservative saccade thresholds)
%     Eyelink('command', 'saccade_velocity_threshold = 35');
%     Eyelink('command', 'saccade_acceleration_threshold = 9500');
% %   this is just to show that you can change thresholds for what qualifie as saccade - changes info in some ini file on host computer

% set EDF file contents
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
%choosing the info that is written to each column of edf file - here
%this is filtered data for events (L & R are samples, other = events)

Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
%choosing the info that is written to each column for raw data


% set link data (used for gaze cursor)
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
%choosing the info that is available to stimulus computer in real time
%via ethernet

% allow to use the big button on the eyelink gamepad to accept the
% calibration/drift correction target
Eyelink('command', 'button_function 5 "accept_target_fixation"');
%can use the gamepad to dismiss/confirm drift check (can check gamepad
%keynums on host computer by going to Offline mode and pressing buttons.

%If interested in other preferences, to get a list either
% 1) look through each ini file on host computer (c:\elcl\exe) or
% 2) look into log files for a given session (same directory)

% make sure we're still connected to eyetracker
if Eyelink('IsConnected')~=1
    error('Eyetracker lost!!!')
end

presStart = GetSecs;

try
%% calibrate eyetracker
% STEP 6
% Calibrate the eye tracker
% setup the proper calibration foreground and background colors
el.backgroundcolour = bgColor;
el.foregroundcolour = 0;
%if not already done, hide cursor
% HideCursor

EyelinkDoTrackerSetup(el);

%following commands change the display state of the host computer
%so that we can watch eye trace in realtime

% Must be offline to draw to EyeLink screen
Eyelink('Command', 'set_idle_mode');
% clear tracker display and draw box at center
EyeLink('Command', 'clear_screen 0')

%draw box somewhere on that host display that indicates an area of
%interest (not used in data viewer, but for qualitative
%visualization)
Eyelink('command', 'draw_box %d %d %d %d 15', width/2-50, height/2-50, width/2+50, height/2+50);


% download data file
cd (fullfile(projDir,'data'))


%% Output a list of IAS files for this session, to be loaded in DataViewer
makeIASList(stimFiles, presentationOrder, projDir, edfFile);

%% save workspace
tmp = clock;
ptbVer = PsychtoolboxVersion;
cd (fullfile(projDir,'data','workspaces'))
save (edfFile);
cd (projDir)

%% save this script
if ispc
    copystring = '!copy';
elseif ismac
    copystring = '!cp';
end
command = sprintf('%s %s %s',copystring, strcat(thisFunction, '.m'), strcat(fullfile(projDir,'data', 'script_archive', strcat('dynamic_stim_eyetracking_demo_', char(subject),'_',date,'_',num2str(tmp(4)),'-',num2str(tmp(5)),'.m'))));
eval(command);

%% close screens when escape key is hit
WaitSecs(10);

% KbWait
Screen('LoadNormalizedGammaTable',w,originalGammaTable);
Screen('CloseAll');

%% clean up
ListenChar(0)
ShowCursor
clear all







 waitDur = 500;

while ~IsQuit & ((GetSecs-presStart) < waitDur )
                                [keyIsDown,secs,keyCode] = KbCheck;
                                if keyIsDown & keyCode(escKey)
                                        IsQuit=1;
                                        break;
                                end
                        end
if IsQuit == 1
                disp('ESC is pressed to abort the program.');
                return;
end

catch
    Screen('CloseAll');
    ShowCursor;
    disp('program error!!!.');
end % try ... catch %