function theData = AG3retrieve(thePath,listName,sName, sNum,RetBlock, S)

% This function accepts a list, then loads the images and runs the expt
% Run AG3.m first, otherwise thePath will be undefined.
% This function is controlled by BH1run
%
% To run this function solo:
% theData = AG3retrieve(thePath,listName,'testSub',0);


refreshInterval= Screen('GetFlipInterval', S.Window);

% ListenChar(2); %suppress display of keypresses to command window.

cd(thePath.list);

list = load(listName);

theData.item = list.testList(:,1);
theData.oldNew = [list.testList{:,3}];
theData.absCon = [list.testList{:,2}];
theData.modality = [list.testList{:,4}];

listLength = length(theData.item);

scrsz = get(0,'ScreenSize');

% preallocate:
trialcount = 0;
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

if isfield(S, 'boxType')
    if strcmp (S.boxType, 'handBox')
        fingerOrder = {{'1' '2' '3'} {'4' '5'}};
    elseif strcmp(S.boxType, 'squareBox')
        fingerOrder = {{'8' '9' '4'} {'6' '7'}};
    end
else
    fingerOrder = {{'1' '2' '3'} {'4' '5'}};
end

if ismember(S.scanner, [4])
    
    
    % STEP 4
% Provide Eyelink with details about the graphics environment
% and perform some initializations. The information is returned
% in a structure that also contains useful defaults
% and control codes (e.g. tracker state bit and Eyelink key values).

edfFile = [S.edfFileBase '_' ONTestBlock];

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

% set parser (conservative saccade thresholds)
%     Eyelink('command', 'saccade_velocity_threshold = 35');
%     Eyelink('command', 'saccade_acceleration_threshold = 9500');
% %   this is just to show that you can change thresholds for what qualifie as saccade - changes info in some ini file on host computer

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
% can use the gamepad to dismiss/confirm drift check (can check gamepad
% keynums on host computer by going to Offline mode and pressing buttons.

% If interested in other preferences, to get a list either
% 1) look through each ini file on host computer (c:\elcl\exe) or
% 2) look into log files for a given session (same directory)

% make sure we're still connected to eyetracker
if Eyelink('IsConnected')~=1
    error('Eyetracker lost!!!')
end

end



% Diagram of trial
stimTime = 180*refreshInterval;  % the word and main response time
respEndTime = 30 * refreshInterval;  % for running out of time
fixTime = 30* refreshInterval; % fixation time.  
scanLeadinTime = 12*60*refreshInterval;
modChangeTime = 6*60*refreshInterval;
behLeadinTime = 4*60*refreshInterval;

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

RMCue = {'E', 'H'};
hands = {'Left','Right'};

if S.scanner==2
    fingers = {'q' 'p'};
elseif S.scanner==1
    fingers = {'1!', '5%'};
end

hsn = S.retHandNum;

% for the first block, display instructions
if RetBlock == 1
    ins_txt{1} = sprintf('During this phase of the study, you will view a series of words and will be asked to report your confidence concerning whether each word is "Old" (you encountered it in the first phase) or "New" (you did not encounter it in the first phase).  \n \n High confident new word = pinky finger.  \n  Low confident new word = ring finger. \n  Low confident old word = middle finger. \n High confident old word = pointer finger.   \n Remember word = thumb.  \n \n Please make your response as quickly and as accurately as possible.  You can respond anytime until you see the blink symbol: [].  Please try to avoid blinking when the blink symbol [] is not on the screen.  When you see the [], please blink.');
    DrawFormattedText(S.Window, ins_txt{1},'center','center',255, 55);
    Screen('Flip',S.Window);
    AG3getKey('g',S.kbNum);
end

    
% Test stims: text cannot be preloaded, so stims will be generated on the
% fly

message = 'Press g to begin!';
[hPos, vPos] = AG3centerText(S.Window,S.screenNumber,message);
Screen(S.Window,'DrawText',message, hPos, vPos, S.textColor);
Screen(S.Window,'Flip');

% save output file
cd(S.subData);

matName = ['Acc1_retrieve_' num2str(sNum), '_' sName 'out(1).mat'];

checkEmpty = isempty(dir (matName));
suffix = 1;

while checkEmpty ~=1
    suffix = suffix+1;
    matName = ['Acc1_retrieve_' num2str(sNum), '_' sName 'out(' num2str(suffix) ').mat'];
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

DrawFormattedText(S.Window,'+','center','center',S.textColor);
Screen(S.Window,'Flip');
qKeys(startTime,goTime,S.boxNum);

oldModality = -1;

for Trial = 1:10%listLength
    
    ons_start = GetSecs;
    
    if ismember(S.scanner, [4])
        % STEP 7.1
        % Sending a 'TRIALID' message to mark the start of a trial in Data
        % Viewer.  This is different than the start of recording message
        % START that is logged when the trial recording begins. The viewer
        % will not parse any messages, events, or samples, that exist in
        % the data file prior to this message.
        Eyelink('Message', 'TRIALID %d', Trial);
        timepoints(Trial,2)  =  GetSecs;
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', Trial, listLength);
        % Before recording, we place reference graphics on the host display
        timepoints(Trial,3)  =  GetSecs;
        %tell me what trial just started (to matlab command line)
        fprintf('trial # %i of %i\n', Trial, listLength)
        timepoints(Trial,4)  =  GetSecs;
        % STEP 7.3
        % start recording eye position (preceded by a short pause so that
        % the tracker can finish the mode transition - used mainly if we're doing driftcorrection)
        % The paramerters for the 'StartRecording' call controls the
        % file_samples, file_events, link_samples, link_events availability
        Eyelink('Command', 'set_idle_mode');
        timepoints(Trial,5)  =  GetSecs;
        WaitSecs(0.05);
        timepoints(Trial,6)  =  GetSecs;
        
        Eyelink('StartRecording', 1, 1, 1, 1);
        Eyelink('Message', '!V TRIAL_VAR category %s', 'object');
%         Eyelink('Message', '!V TRIAL_VAR whetherwithmask %s', num2str(blankDur));
%         if thepic<=9
%             Eyelink('Message', '!V TRIAL_VAR whichimage %s%s',num2str(0), num2str(thepic));
%         elseif thepic>=10
%             Eyelink('Message', '!V TRIAL_VAR whichimage %s', num2str(thepic));
%         end
%         Eyelink('Message', '!V TRIAL_VAR whichAxis %s', num2str(whichStimuli));
%         Eyelink('Message', '!V TRIAL_VAR whichSequence %s', num2str(sequentCode));
        timepoints(Trial,7)  =  GetSecs;
        % record a few samples before we actually start displaying
        % otherwise you may lose a few msec of data
        
        
        % mark zero-plot time in data file
        Eyelink('Message', 'image_start');
        
%         Eyelink('Message', '!V IAREA FILE InterestAreas/%s.ias', itemlist{thepic});
        
        
        
        'endpoint7.1.4'
        % Send an integration message so that an image can be loaded as
        % overlay backgound when performing Data Viewer analysis.  This
        % message can be placed anywhere within the scope of a trial (i.e.,
        % after the 'TRIALID' message and before 'TRIAL_RESULT')
        % See "Protocol for EyeLink Data to Viewer Integration -> Image
        % Commands" section of the EyeLink Data Viewer User Manual.
        %Eyelink('Message', '!V IMGLOAD CENTER %s%s%s%s %d %d %d %d', 'axis',num2str(whichStimuli),'/',itemlist{thepic}, 800, 600, 800, 600 );
        %Eyelink('Message', '-%d !V IAREA FILE /InterestAreas/%s.ias', n,
        %note that '!V' indicates a message to DataViewer (see chp. 7 Eyelink Data Vierwer user's manual 'Protocol for eyelink to dataviwer integration')
        
        
    end
    
    newModality = theData.modality(Trial);
    if newModality ~= oldModality;
        message = RMCue{theData.modality(Trial)};
        DrawFormattedText(S.Window,message,'center','center',S.textColor);
        goTime = modChangeTime;
        Screen(S.Window,'Flip');
        qKeys(ons_start,goTime,S.boxNum); 
    else
        goTime = 0;
    end
    oldModality = newModality;
    
    
    theData.onset(Trial) = GetSecs - startTime; %precise onset of trial presentation
    
    % Fixation
    goTime = fixTime + goTime;
    DrawFormattedText(S.Window,'+','center','center',S.textColor);
    Screen(S.Window,'Flip');
    [keys RT] = qKeys(ons_start,goTime,S.boxNum); 
    
    % Stim
    goTime = goTime + stimTime;
    message = theData.item{Trial};
    DrawFormattedText(S.Window,message,'center','center',S.textColor);
    Screen('FrameRect', S.Window, 255, [0, 0, 100, 100])
    Screen('FrameRect', S.Window, 255, [0, scrsz(4)-100, 100, scrsz(4)])
    Screen('FrameRect', S.Window, 255, [scrsz(3)-100, 0, scrsz(3), 100])
    Screen('FrameRect', S.Window, 255, [scrsz(3)-100, scrsz(4)-100, scrsz(3), scrsz(4)])
    Screen(S.Window,'Flip');
    [keys RT] = qKeys(ons_start,goTime,S.boxNum);    
    theData.stimresp{Trial} = keys;
    theData.stimRT{Trial} = RT;
    
    % Delay
    goTime = goTime + respEndTime;
    DrawFormattedText(S.Window,'+','center','center', S.textColor);
    Screen(S.Window,'Flip');
    [keys RT] = qKeys(ons_start,goTime,S.boxNum);  % not collecting keys, just a delay
    theData.judgeResp{Trial} = keys;
    theData.judgeRT{Trial} = RT;

    % record
    theData.num(Trial) = Trial; 
    theData.dur(Trial) = GetSecs - ons_start;  %records precise trial duration
    

    if S.scanner == 4
        Eyelink('StopRecording');
        
        Eyelink('Message', 'TRIAL_RESULT 0');
    end
    cmd = ['save ' matName];
    eval(cmd);
    
    
end

DrawFormattedText(S.Window,'Saving...','center','center', [100 100 100]);

cmd = ['save ' matName];
eval(cmd);

    %% shut down eyetracker
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


%close the eye tracker.
Eyelink('ShutDown');
%fprintf(['\npct correct = ' num2str(res.pctCor)]);
%fprintf(['\npct legit = ' num2str(res.pctLegit)]);

Screen(S.Window,'FillRect', S.screenColor);	% Blank Screen
Screen(S.Window,'Flip');

ListenChar(1); % tell the command line to listen to key responses again.
Priority(0);

