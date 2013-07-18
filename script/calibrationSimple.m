function [] = calibrationSimple(thePath,subject)

% Calibrate eye tracker
% Adapted from KGS lab by A Gordon and then by K LaRocque 05/2013

try

    cd(thePath.main)

    % initialize eye tracker
    if Eyelink('initialize') ~= 0
        fprintf('error in connecting to the eye tracker\n\n');
        return;
    end

    Window = Screen('OpenWindow',max(Screen('Screens')));
    Priority(MaxPriority(Window));

    %%Initial flip

    Screen('Flip', Window);
    FlushEvents('keyDown'); %initial flush
    ListenChar(2);

    %Eyelink
    el=EyelinkInitDefaults(Window); % give eyelink info about graphics, perform initializations

    if ~EyelinkInit(1, 1) % initialize eyelink
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end

    % open file to record data to
    edfFile = [subject,'cl',datestr(clock,'MM')];
    edff = Eyelink('Openfile', edfFile);
    if edff~=0
        printf('Cannot create EDF file ''%s'' ', edfFile);
        Eyelink( 'Shutdown');
        return;
    end

    Eyelink('command', 'add_file_preamble_text ''dynamic stim eyetracking''');

    [width, height]=Screen('WindowSize',Window); % returns in pixels
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1); % sets physical.ini to screen pixels
    % NEED TO CHANGE PHYSICAL DISTANCE?
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
    Eyelink('command', 'calibration_type = HV5'); % 9 point calibration, set in calibr.ini
    % set EDF file contents
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); % what events (columns) are recorded in EDF
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS'); % what samples (columns) are recorded in EDF
    % set data available in real time
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); % events available for real time
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS'); % samples available for real time
    Eyelink('command', 'button_function 5 "accept_target_fixation"'); % allow to use eyelink gamepad to accept fixations/targets

    %If interested in other preferences, to get a list either
    % 1) look through each ini file on host computer (c:\elcl\exe) or
    % 2) look into log files for a given session (same directory)

    % make sure we're still connected to eyetracker
    if Eyelink('IsConnected')~=1
        error('Eyetracker lost!!!')
    end

    EyelinkDoTrackerSetupAG(el); % calibrate
    fprintf('done calibrating')
    cd(fullfile(thePath.data))

    WaitSecs(1);

    Eyelink('CloseFile');

    % download data file
    cd(fullfile(thePath.data,'eyetracking'))
    try
        fprintf('Receiving data file ''%s''\n', edfFile);
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
        end
    catch ME1
        fprintf('Problem receiving data file ''%s''\n', edfFile );
    end


    %% clean up
    ListenChar(0)
    ShowCursor
    sca

catch myerr
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    cleanup;
    commandwindow;
    myerr;
    myerr.message
    myerr.stack.line

end %try..catch.
end

% Cleanup routine:
function cleanup

    Eyelink('Shutdown');
    sca;
    ListenChar(0);

end