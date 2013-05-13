function EyelinkExample

% Short MATLAB example program that uses the Eyelink and Psychophysics
% Toolboxes to create a real-time gaze-dependent display.
% This is the example as shown in the EyelinkToolbox article in BRMIC
% Cornelissen, Peters and Palmer 2002), but updated to use new routines
% and functionality.
%
% History
% ~2006     fwc    created it, to use updated functions
% 15-06-10  fwc    updated to enable eye image display
% 17-06-10  fwc    made colour of the gaze dot change, just for fun

clear all;
commandwindow;

try
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
            projDir = '/Users/alangordon/Studies/OldNewResponseModality/';
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
    
    
    fprintf('EyelinkToolbox Example\n\n\t');
    dummymode=0;       % set to 1 to initialize in dummymode (rather pointless for this example though)
    
    
    if Eyelink('initialize') ~= 0
        fprintf('error in connecting to the eye tracker\n\n');
        return;
    end
    
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
    
    
    
    % STEP 1
    % Open a graphics window on the main screen
    % using the PsychToolbox's Screen function.
    screenNumber=max(Screen('Screens'));
    
    if exist('nativeHz','var') %if using CRT
        oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2), nativeHz);
        disp('refresh set to nativeHz');
    else
        oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2));
    end
    
    
    window=Screen('OpenWindow', screenNumber);
    
    [w, rect] = Screen('OpenWindow', screenNumber, bgColor);
    Priority(MaxPriority(w));
    ListenChar(0)

    originalGammaTable = Screen('ReadNormalizedGammaTable',w);

    %%Initial flip
    Screen('Flip', w);
    FlushEvents('keyDown'); %initial flush
    
    %%locate screen center
    [center(1), center(2)] = RectCenter(rect);

    % STEP 2
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    el=EyelinkInitDefaults(window);
    % Disable key output to Matlab window:
    ListenChar(2);
        
    % STEP 3
    % Initialization of the connection with the Eyelink Gazetracker.
    % exit program if this fails.
    if ~EyelinkInit(dummymode, 1)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end
    
    [v vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    
    % make sure that we get gaze data from the Eyelink
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    
    % open file to record data to
    i = Eyelink('Openfile', edfFile);
    if i~=0
        printf('Cannot create EDF file ''%s'' ', edffilename);
        Eyelink( 'Shutdown');
        return;
    end
    
    Eyelink('command', 'add_file_preamble_text ''dynamic stim eyetracking''');
    
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

    % STEP 4
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
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


%% save workspace
tmp = clock;
ptbVer = PsychtoolboxVersion;
cd (fullfile(projDir,'data','workspaces'))
save (edfFile);
cd (projDir)


%% close screens when escape key is hit
WaitSecs(10);

% KbWait
Screen('LoadNormalizedGammaTable',w,originalGammaTable);
Screen('CloseAll');

%% clean up
ListenChar(0)
ShowCursor
clear all

    % do a final check of calibration using driftcorrection
%    EyelinkDoDriftCorrection(el);
    
%     % STEP 5
%     % start recording eye position
%     Eyelink('StartRecording');
%     % record a few samples before we actually start displaying
%     WaitSecs(0.1);
%     % mark zero-plot time in data file
%     Eyelink('Message', 'SYNCTIME');
%     stopkey=KbName('space');
%     eye_used = -1;
% 
%     Screen('FillRect', el.window, el.backgroundcolour);
%     Screen('TextFont', el.window, el.msgfont);
%     Screen('TextSize', el.window, el.msgfontsize);
%     [width, height]=Screen('WindowSize', el.window);
%     message='Press space to stop.';
%     Screen('DrawText', el.window, message, 200, height-el.msgfontsize-20, el.msgfontcolour);
%     Screen('Flip',  el.window, [], 1);
%     
%     % STEP 6
%     % show gaze-dependent display
%     while 1 % loop till error or space bar is pressed
%         % Check recording status, stop display if error
%         err=Eyelink('CheckRecording');
%         if(err~=0)
%             break;
%         end
%         % check for keyboard press
%         [keyIsDown, secs, keyCode] = KbCheck;
%         % if spacebar was pressed stop display
%         if keyCode(stopkey)
%             break;
%         end
%         % check for presence of a new sample update
%         if Eyelink( 'NewFloatSampleAvailable') > 0
%             % get the sample in the form of an event structure
%             evt = Eyelink( 'NewestFloatSample');
%             if eye_used ~= -1 % do we know which eye to use yet?
%                 % if we do, get current gaze position from sample
%                 x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
%                 y = evt.gy(eye_used+1);
%                 % do we have valid data and is the pupil visible?
%                 if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
%                     % if data is valid, draw a circle on the screen at current gaze position
%                     % using PsychToolbox's Screen function
%                     gazeRect=[ x-9 y-9 x+10 y+10];
%                     colour=round(rand(3,1)*255); % coloured dot
%                     Screen('FillOval', window, colour, gazeRect);
%                     Screen('Flip',  el.window, [], 1); % don't erase
%                 else
%                     % if data is invalid (e.g. during a blink), clear display
%                     Screen('FillRect', window, el.backgroundcolour);
%                     Screen('DrawText', window, message, 200, height-el.msgfontsize-20, el.msgfontcolour);
%                     Screen('Flip',  el.window, [], 1); % don't erase
%                 end
%             else % if we don't, first find eye that's being tracked
%                 eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
%                 if eye_used == el.BINOCULAR; % if both eyes are tracked
%                     eye_used = el.LEFT_EYE; % use left eye
%                 end
%             end
%         end % if sample available
%     end % main loop
%     % wait a while to record a few more samples
%     WaitSecs(0.1);
%     
%     % STEP 7
%     % finish up: stop recording eye-movements,
%     % close graphics window, close data file and shut down tracker
%     Eyelink('StopRecording');
%     Eyelink('CloseFile');
%     % download data file
%     try
%         fprintf('Receiving data file ''%s''\n', edfFile );
%         status=Eyelink('ReceiveFile');
%         if status > 0
%             fprintf('ReceiveFile status %d\n', status);
%         end
%         if 2==exist(edfFile, 'file')
%             fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
%         end
%     catch rdf
%         fprintf('Problem receiving data file ''%s''\n', edfFile );
%         rdf;
%     end
%     
%     cleanup;
    
catch myerr
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    cleanup;
    commandwindow;
    myerr;
    myerr.message
    myerr.stack.line

end %try..catch.


% Cleanup routine:
function cleanup
% Shutdown Eyelink:
Eyelink('Shutdown');

% Close window:
sca;

% Restore keyboard output to Matlab:
ListenChar(0);
