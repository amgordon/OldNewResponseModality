function theData = RM_Loc(thePath,listName,sName, sNum,RetBlock, S)

% This function accepts a list, then loads the images and runs the expt
% Run AG3.m first, otherwise thePath will be undefined.
% This function is controlled by BH1run
%
% To run this function solo:
% theData = AG3retrieve(thePath,listName,'testSub',0);

% This function accepts a list, then loads the images and runs the expt
% Run AG3.m first, otherwise thePath will be undefined.
% This function is controlled by BH1run
%
% To run this function solo:
% theData = AG3retrieve(thePath,listName,'testSub',0);


cd(thePath.list);

list = load(listName);

theData.item = list.locList(:,1);
theData.modality = list.locList(:,2);
theData.desiredDur = list.locList(:,3);

listLength = length(theData.item);



% preallocate:
for preall = 1:listLength
    theData.onset(preall) = 0;
    theData.dur(preall) =  0;
    theData.stimresp{preall} = 'noanswer';
    theData.stimRT{preall} = 0;
    theData.judgeResp{preall} = 'noanswer';
    theData.judgeRT{preall} = 0;
    theData.resp{preall} = 'noanswer';
    theData.respRT{preall} = 0;
    theData.respActual{preall} = 'noanswer';
    theData.endRespActual{preall} = 'noanswer';
    theData.respActual{preall} = 'noanswer';
end




if S.useEL
    % STEP 4
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    
    edfFile = [S.edfFileBase '_' num2str(RetBlock)];
    

    % open file to record data to
    trialFile = Eyelink('Openfile', edfFile);
    if trialFile~=0
        printf('Cannot create EDF file ''%s'' ', edffilename);
        Eyelink( 'Shutdown');
        return;
    end
    
    Eyelink('command', 'add_file_preamble_text ''dynamic stim eyetracking''');
    
    % STEP 5
    % SET UP TRACKER CONFIGURATION
    % Setting the proper recording resolution, proper calibration type,
    % as well as the data file content;
    [width, height]=Screen('WindowSize', S.screenNumber);
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
    % SETS 'screen_pixel_coords' field in *.ini file on host computer (in this case,
    % 'physical.ini' to selected values
    
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
    % notes that last change in edf file via message
    
    % set calibration type.
    Eyelink('command', 'calibration_type = HV9');
    % determines how many dots we will be using for calibration , set in calibr.ini
    
    % set EDF file contents
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    % choosing the info that is written to each column of edf file - here
    % this is filtered data for events (L & R are samples, other = events)
    
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
    % choosing the info that is written to each column for raw data
    
    
    % set link data (used for gaze cursor)
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
    % choosing the info that is available to stimulus computer in real time
    % via ethernet
    
    % allow to use the big button on the eyelink gamepad to accept the
    % calibration/drift correction target
    Eyelink('command', 'button_function 5 "accept_target_fixation"');
    
    
    % make sure we're still connected to eyetracker
    if Eyelink('IsConnected')~=1
        error('Eyetracker lost!!!')
    end
    
end


% Diagram of trial
stimTime = 3;  % the word and main response time
respEndTime = .5;  % for running out of time
fixTime = .5; % fixation time.  
scanLeadinTime = 12;
modChangeTime = 4;
behLeadinTime = 4;

centerX = S.myRect(3)/2;
centerY = S.myRect(4)/2 - 12; 

% Screen commands
Screen(S.Window,'FillRect', S.screenColor);
Screen(S.Window,'Flip');

cd(thePath.stim);

% Load fixation
fileName = 'fix.jpg';
pic = imread(fileName);
fix = Screen(S.Window,'MakeTexture', pic);

% Load blank
fileName = 'blank.jpg';
pic = imread(fileName);
blank = Screen(S.Window,'MakeTexture', pic);

% Load blank
fileName = 'eye.jpg';
pic = imread(fileName);
eye = Screen(S.Window,'MakeTexture', pic);

% Load blank
fileName = 'hand.jpg';
pic = imread(fileName);
hand = Screen(S.Window,'MakeTexture', pic);

RMCue = {'Eye', 'Hand'};
hands = {'Left','Right'};
ONStatus = {'OLD' 'NEW'};
confDir = {'+' 'Old' 'New'};

if S.scanner==2
    fingers = {'q' 'p'};
elseif S.scanner==1
    fingers = {'1!', '5%'};
end

S.hsn = 2-mod(RetBlock+S.respSelHandNum,2);

% for the first block, display instructions
ins_txt{1} = sprintf('During each trial of this phase of the study, you will be given a judgment, and you will be asked to identify the correct response for that judgment using either your eyes or your hands.  \n \n For EYE blocks of trials you will respond by moving your eyes to one of two sides of the screen.  For HAND blocks, you will respond by pressing one of two buttons.  Your responses are as follows: \n \n OLD = %s.  \n  NEW = %s.   \n \n Please make your response as quickly and as accurately as possible.  While you are not making a response with your eyes, please look at the fixation dot in the center of the screen.', hands{S.hsn}, hands{3-S.hsn});
DrawFormattedText(S.Window, ins_txt{1},'center','center',S.textColor, S.maxCharsOnLine);
Screen('Flip',S.Window);
AG3getKey('g',S.kbNum);


    
% Test stims: text cannot be preloaded, so stims will be generated on the
% fly

message = 'Press g to begin!';
[hPos, vPos] = AG3centerText(S.Window,S.screenNumber,message);
Screen(S.Window,'DrawText',message, hPos, vPos, S.textColor);
Screen(S.Window,'Flip');

% save output file
cd(S.subData);

matName = ['practiceTest' num2str(sNum), '_' sName 'out(1).mat'];

checkEmpty = isempty(dir (matName));
suffix = 1;

while checkEmpty ~=1
    suffix = suffix+1;
    matName = ['practiceTest_' num2str(sNum), '_' sName 'out(' num2str(suffix) ').mat'];
    checkEmpty = isempty(dir (matName));
end

diary ([matName '_diary']);


% Present test trials
goTime = 0;

if S.scanner==1
    % *** TRIGGER ***
    while 1
        AG3getKey('g',S.kbNum);
        [status, startTime] = AG3startScan; % startTime corresponds to getSecs in startScan
        fprintf('Status = %d\n',status);
        if status == 0  % successful trigger otherwise try again
            break
        else
            message = 'Trigger failed, "g" to retry';
            DrawFormattedText(S.Window,message,'center','center',S.textColor);
            Screen(S.Window,'Flip');
        end
    end
else
    AG3getKey('g',S.kbNum);
    startTime = GetSecs;
end


Priority(MaxPriority(S.Window));

% present initial  fixation
if S.scanner == 1
    goTime = goTime + scanLeadinTime;
elseif S.scanner ==2;
    goTime = goTime + behLeadinTime;
end

Screen('FillOval', S.Window, S.textColor, S.centerFix);
%DrawFormattedText(S.Window,'+','center','center',S.textColor);
Screen(S.Window,'Flip');
qkeys(startTime,goTime,S.boxNum);

oldModality = -1;
cumulativeCueTime = 0;

ons_init = GetSecs;
for Trial = 1:listLength
    
    ons_start = GetSecs;
    
    newModality = theData.modality(Trial);
    if newModality ~= oldModality;
        message = RMCue{theData.modality(Trial)};
        DrawFormattedText(S.Window,message,'center','center',S.textColor);
        %         DrawFormattedText(S.Window,ONStatus{S.hsn}, S.leftText,'center',S.textColor);
        %         DrawFormattedText(S.Window,ONStatus{3-S.hsn}, S.rightText,'center',S.textColor);
        goTime = modChangeTime;
        Screen(S.Window,'Flip');
        qkeys(ons_start,goTime,S.boxNum);
        cumulativeCueTime = cumulativeCueTime + modChangeTime;
    else
        goTime = 0;
    end
    oldModality = newModality;
    
    if S.useEL
        % STEP 7.1
        % Sending a 'TRIALID' message to mark the start of a trial in Data
        % Viewer.  This is different than the start of recording message
        % START that is logged when the trial recording begins. The viewer
        % will not parse any messages, events, or samples, that exist in
        % the data file prior to this message.
        Eyelink('Message', 'TRIALID %d', Trial);
        
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', Trial, listLength);
        % Before recording, we place reference graphics on the host display
        
        %tell me what trial just started (to matlab command line)
        fprintf('trial # %i of %i\n', Trial, listLength)
        
        % STEP 7.3
        % start recording eye position (preceded by a short pause so that
        % the tracker can finish the mode transition - used mainly if we're doing driftcorrection)
        % The paramerters for the 'StartRecording' call controls the
        % file_samples, file_events, link_samples, link_events availability
        Eyelink('Command', 'set_idle_mode');
        
        Eyelink('StartRecording', 1, 1, 1, 1);
        
    end
    
    
    theData.onset(Trial) = GetSecs - startTime; %precise onset of trial presentation
    
    % Fixation
    goTime = fixTime + goTime;
    Screen('FillOval', S.Window, S.textColor, S.centerFix);
    Screen(S.Window,'Flip');
    [keys RT] = qkeys(ons_start,goTime,S.boxNum);
    
    % Stim
    message = confDir{1+theData.item(Trial)};
    
    if ~strcmp(message, '+')
        DrawFormattedText(S.Window,message,'center','center',S.textColor);
        Screen('FillOval', S.Window, S.textColor, S.leftFix);
        Screen('FillOval', S.Window, S.textColor, S.rightFix);
        goTime = goTime + stimTime;
    else
        Screen('FillOval', S.Window, S.textColor, S.centerFix);
        goTime = goTime + theData.desiredDur(Trial) - respEndTime - fixTime;
    end
    
    Screen(S.Window,'Flip');
    [keys RT] = qkeys(ons_start,goTime,S.boxNum);
    theData.stimresp{Trial} = keys;
    theData.stimRT{Trial} = RT;
    
    % Delay
    desiredEndTime = ons_init + sum(theData.desiredDur(1:Trial)) + cumulativeCueTime - GetSecs;
    goTime = goTime + desiredEndTime;
    Screen('FillOval', S.Window, S.textColor, S.centerFix);
    Screen(S.Window,'Flip');
    [keys RT] = qkeys(ons_start,goTime,S.boxNum);  % not collecting keys, just a delay
    theData.judgeResp{Trial} = keys;
    theData.judgeRT{Trial} = RT;
    
    if S.useEL
        Eyelink('StopRecording');
        Eyelink('Message', 'TRIAL_RESULT 0');
    end
    cmd = ['save ' matName];
    eval(cmd);
    
    % record
    theData.num(Trial) = Trial;
    theData.dur(Trial) = GetSecs - ons_start;  %records precise trial duration
end

DrawFormattedText(S.Window,'Saving...','center','center', [100 100 100]);

cmd = ['save ' matName];
eval(cmd);

%% shut down eyetracker
if S.useEL
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    
    
    % download data file
    cd (S.subData)
    try
        fprintf('Receiving data file ''%s''\n', edfFile );
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
    
end


Screen(S.Window,'FillRect', S.screenColor);	% Blank Screen
Screen(S.Window,'Flip');

ListenChar(1); % tell the command line to listen to key responses again.
Priority(0);

