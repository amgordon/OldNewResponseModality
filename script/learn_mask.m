ifunction [IsQuit] = learn_mask(subjID, whichStimuli, whichFamily, sequentCode, learnRepeat,multistim,itemDurDefine,blankDur)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% command:
%% learn(subjID, whichStimuli, sequentCode)
%%
%% subjID: subject name (string)
%% whichStimuli: the number following 'axis' (6 or 12 now)
%% sequentCode: 1 for sequential display; 2 for nonsequential display.
%%
%% for example:
%% learn('tt', 6, 1)  % sequential display axis6
%% learn('tt', 12, 2)  % nonsequential display axis12  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subject = subjID;
maxSize = 0;
bgColor = [186 186 186];
fixR = 0.25;
fixColor = [0 0 0];
numberOfFix = 4;

Screen('Preference', 'Verbosity', 1);
if nargin ~= 8
    error('Please input all the parameter for learning: subjID, whichStimuli, sequentCode,multistim');
end
AssertOpenGL; % check for Opengl compatibility, abort otherwise (to verify PTB3)
Screen('Preference', 'SkipSyncTests',1);

% % system specific info
[d hostname]=system('hostname'); 
switch strcat(hostname)
    case 'kalanit-grill-spectors-macbookpro41.local' %powerbook 'Andre the Giant'
        projDir = '/Users/kalanit/Experiments/SpatiotemporalLearning/Pilot14/RunExperiment/';
    case 'kweb-com.local' %george w/ 454dell
        projDir = '/Users/kweb/exp/DynamicStim/eyetracking_pilot/';
    case 'skidder' %remus's desktop, using Dell LCD
        projDir = 'R:\PROJECTS\DynamicStim\eyetracking_pilot';
    otherwise
        error('Unknown host name - is this computer still connected to the network?')
end


tmp = inputdlg({'Enter viewing distance (cm)', 'Which display is being used (1) = LCD, (2) = CRT, (3) = Integrated display'}, 'Display information', 1, {'57.5', '2'} );
viewingDistance = str2double(tmp{1});
displayUsed = str2double(tmp{2});

if displayUsed == 1 %indicates Either Dell 2005FPW
    nativeResolution = [1680 1050]; %script will force the screen to match these dimensions
    pixPerCM = 400/10.35; % %measured by remus @ resolution = 1680x1050 (true for both Dell 2005FPW and 2009Wt)
%     cal = LoadCalFile('EyetrackerDell2005FPW'); %true on Andre, not calibrated on George (remus 10/19/10)
elseif displayUsed == 2
%     load info for CRT
%         nativeResolution = [1600 1200]; %script will force the screen to match these dimensions
%         pixPerCM = 400/9.9; %measured by remus @ resolution = 1600x1200 (7/20/10, on mitsubishi diamondpro2070sb)
    nativeResolution = [1600 1200]; % changed from genuine nativeResolution (1600x1200) since Eyelink DataViewer doesn't scale videos
    pixPerCM = 400/15.05; %measured by remus @ resolution = 1024x768 (11/30/10, on mitsubishi diamondpro2070sb)
    if ~isequal(nativeResolution ,[1600 1200]) &&  ~isequal(nativeResolution,[1024 768])
        disp('Warning: The screen is set to a non native resolution, scaling will not be reliable');
%         to calculate on a different native resolution put an image of 400
%         pixels and divide by the size in cm on the screen
    end
    nativeHz = 85;
%     cal = LoadCalFile('EyeTrackerCRT'); %indicates mitsubishi diamondpro2070sb used with eyelink tracker -- true on Andre, not calibrated on George (remus 10/19/10)
    
elseif displayUsed == 3
    if ~strcmpi(hostname, 'kalanit-grill-spectors-macbookpro41.local') %using George (15" macbook) or some other machine
        error('Integrated screen dimensions not yet measured - see code for examples')
    end
%     presuming we're using Andre
    nativeResoultion = [1920 1200];
    pixPerCM = 400/7.7; %measured by remus @ resolution = 1920X1200 (for Andre (17" macbook) integrated display)
else
    error('unknown display')
end

% calculate pixels/degree so that we can define stimuli based on visual angle
cmPerDegree = viewingDistance * tan(deg2rad(1));%this is cm from center to 1 degree out in a single direction (calculation for 1degree spanning center is slightly different)
pixPerDegree = pixPerCM * cmPerDegree;
pixPerSide = round(maxSize*pixPerDegree); %maximum pix per side of images or videos

'endpoint'

% % Do eyetracker setup
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
month = num2str(tmp(2), '%02.0f');
days = num2str(tmp(3), '%02.0f');
hours = num2str(tmp(4), '%02.0f');
minutes = num2str(tmp(5), '%02.0f');
def     = {strcat(month,days,hours,minutes)};
answer  = inputdlg(prompt,dlg_title,1,def);
edfFile = answer{1};

% % Initialize Screens & continue with eyetracker setup
screens=Screen('Screens');
screenNumber=max(screens);   

% if screenNumber < 2
%     HideCursor;	% Hide the mouse cursor
% end

if exist('nativeHz','var') %if using CRT
    oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2), nativeHz);
    disp('refresh set to nativeHz');
else  
    oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2));
end

[w, rect] = Screen('OpenWindow', screenNumber, bgColor);
Priority(MaxPriority(w));
ListenChar(2)


% %%do gamma correction (modified from CalDemo)
originalGammaTable = Screen('ReadNormalizedGammaTable',w);
% cal = SetGammaMethod(cal,0);
% % Make the desired linear output, then convert.
% linearValues = ones(3,1)*linspace(0,1,length(cal.gammaTable));
% clutValues = PrimaryToSettings(cal,linearValues);
% Screen('LoadNormalizedGammaTable',w,clutValues');

% %Initial flip
Screen('Flip', w);
FlushEvents('keyDown'); %initial flush

% %locate screen center
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


'endpoint';
%% Experiment parameter
% itemDurDefine = 1/8;% 1/multistim; % Unit: second
% blankDur = 1/30; % duration of blank screen between learning stimuli; % Unit: second
whetherfix = 0; % whetherfix=1, have a fixation during trials; if ~=1, no fixation
firstFixationDurDefine = 1; % Unit: second
ISIDurDefine = 0.3; % Unit: second
% nonsequenInter = 4; %% the minimum interval between two nonsequential stimuli
itemsPerBlock = 12*multistim;
pixRect = [0 0 800 600]; 
numBlocks = 3;
imgScale = 1.2;
sKey = KbName('space');
escKey = KbName('ESCAPE');


rootDir = '/Users/kalanit/Experiments/SpatiotemporalLearning/Pilot14/RunExperiment/';
fmt = 'jpg';

'endpoint1';

BeginTime=tmp;
Filefix = [subjID, '_Learning', '_', num2str(BeginTime(1)),num2str(BeginTime(2),'%02d'), ...
   num2str(BeginTime(3),'%02d'), '_H', num2str(BeginTime(4), '%02d'),'M', num2str(BeginTime(5),'%02d'), '_axis', num2str(whichStimuli), '_', num2str(sequentCode)];

% Duration for each picture
itemDur =  itemDurDefine;  

% Inter stimulus interval
ISIDur = ISIDurDefine;
% trialDur = itemDur + ISIDur;
firstFixationDur = firstFixationDurDefine;

% Initial screen
screens = Screen('Screens');
screenNumber = max(screens);
%screenNumber = 1;
screenRect  = Screen(screenNumber, 'rect');

% % Initialize Screens & continue with eyetracker setup
% screens=Screen('Screens');
% screenNumber=max(screens);   
% 
% if screenNumber < 2
%     HideCursor;	% Hide the mouse cursor
% end
% 
% if exist('nativeHz','var') %if using CRT
%     oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2), nativeHz);
%     disp('refresh set to nativeHz');
% else
%     oldResolution = Screen('Resolution', screenNumber, nativeResolution(1), nativeResolution(2));
% end
% 
% [w, rect] = Screen('OpenWindow', screenNumber, bgColor);
% Priority(MaxPriority(w));
% ListenChar(2)

stimuliDir = char([rootDir, 'stim/axis' num2str(whichStimuli)]);
dataDir = char([rootDir, 'data/']);
codeDir = char([rootDir, 'code/']);
maskDir = char([rootDir, 'stim/mask'])

IsQuit = 0;
'endpoint2'

try		

	% Open a fullscreen window
	backgroundcolor= [186 186 186];
	[window, screenRect] = Screen('OpenWindow',screenNumber,backgroundcolor,screenRect);
	%refresh = Screen('GetFlipInterval', window);

	%% create enough offscreen windows for each picture in the experiment
    
   
    
    
	for i = 1:(itemsPerBlock)
	  offScrPtr(i) = Screen('OpenOffscreenWindow',window,  [255 255 255], pixRect);
	end

	fixation = Screen('OpenOffscreenWindow',window, [186 186 186], pixRect);
	Screen('FillOval',fixation,  [255 255 255], CenterRect([0 0 12 12], pixRect));
	Screen( 'FillOval',fixation, [0 0 0], CenterRect([0 0 8 8], pixRect));
	blank =    Screen('OpenOffscreenWindow',window,  [186 186 186], pixRect);
    maskScrPtr = Screen('OpenOffscreenWindow', window, [186 186 186], pixRect);

	cd(stimuliDir);
	StimuliFile = dir('*.jpg');
	[numitems junk] = size(StimuliFile);
	if numitems~=itemsPerBlock, error('Not the right number of items.'); end
	[itemlist{1:numitems}] = deal(StimuliFile.name);
	for theitem = 1:itemsPerBlock
		filename = itemlist{theitem};
		[imgArray] = imread(filename, fmt);
        [height width junk] = size(imgArray);
        height = imgScale*height;
        width = imgScale*width;
		Screen('PutImage',offScrPtr(theitem), imgArray, pixRect);
        
    end
    
    %% read mask stim
    cd(maskDir);
    StimuliFile = dir('*.jpg');
    [numitems junk] = size(StimuliFile);
    [itemlist_mask{1:numitems}] = deal(StimuliFile.name);
    filename_mask = itemlist_mask{1};
		[imgArray] = imread(filename_mask, fmt);
    	Screen('PutImage',maskScrPtr, imgArray, pixRect);
        
        
	cd(codeDir);
 'endpoint3';
	theorder{1} = zeros(itemsPerBlock*2, numBlocks);
	theorder{2} = zeros(itemsPerBlock*2, numBlocks);
    theorder{3} = zeros(itemsPerBlock*2, numBlocks);
	theorder{4} = zeros(itemsPerBlock*2, numBlocks);
	for i = 1:numBlocks
		firstpict = 1;
		lastpict = itemsPerBlock;
		interpict = [2:(itemsPerBlock-1)]';
		switch sequentCode
			case 1 % sequential
				thelist = [firstpict;interpict;lastpict];
			case 2 % nonsequential
				thelist = randperm(itemsPerBlock);
		end
		theorder{1}(1:itemsPerBlock, i) = thelist;
        theorder{1}(itemsPerBlock+1:itemsPerBlock*2, i) = flipud(thelist);
    end
    
    for i = 1:numBlocks
		firstpict = 1;
		lastpict = itemsPerBlock;
		interpict = [(itemsPerBlock-1):-1:2]';
		switch sequentCode
			case 1 % sequential
				thelist = [lastpict;interpict;firstpict];
			case 2 % nonsequential
				thelist = randperm(itemsPerBlock);
		end
		theorder{2}(1:itemsPerBlock, i) = thelist;
        theorder{2}(itemsPerBlock+1:itemsPerBlock*2, i) = flipud(thelist);
    end
	
    theorder{3} = theorder{1};
    theorder{4} = theorder{2};
    
    'endpoint5';
    
	%% start display
	HideCursor;
	%% Cue word to remind task and check screen orientation
	Screen('TextSize',window,30);
	Screen('TextFont',window,'Arial');
	Screen('TextStyle', window ,1);
    Screen('DrawText',window,'You will see different views of an object, just look at them and pay close attention to the object.',(screenRect(3)/2-700),screenRect(4)/2-80);
    Screen('DrawText',window, ['Now we will start the learning phase of Object' num2str(whichFamily) '. Press space key when you are ready.'],(screenRect(3)/2-600),screenRect(4)/2-34); 
% 	Screen('CopyWindow', fixation, window, [], CenterRect(pixRect, screenRect));
	Screen('Flip',window);

	while kbcheck, end;
	while 1
	    [keyIsDown,secs,keyCode] = KbCheck;
	    if keyIsDown & keyCode(sKey) 
		break; % start only when start key is pressed
	    elseif keyIsDown & keyCode(escKey)  
	    	IsQuit=1;
		break;
	    end
	end
'endpoint6'
	experimentStart = GetSecs;
	for theBlock = 1:numBlocks
% 		
% 		Screen('CopyWindow', fixation, window, [], CenterRect(pixRect, screenRect));
% 		startTime = GetSecs;
%         Screen('Flip',window); % display first fixation 
% 		
% 		while ~IsQuit & ((GetSecs - startTime)<firstFixationDur) 
% 			[keyIsDown,secs,keyCode] = KbCheck;
% 			if keyIsDown & keyCode(escKey),
% 		    		IsQuit=1;
% 				break;
% 			end
% 		end
'endpoint7'
		for i = 1:itemsPerBlock*2
            
        timepoints(i,1)  =  GetSecs;  
    thepic = theorder{learnRepeat}(i, theBlock);
                    timepoints(i,8)  =  GetSecs;           
    % STEP 7.1
    % Sending a 'TRIALID' message to mark the start of a trial in Data
    % Viewer.  This is different than the start of recording message
    % START that is logged when the trial recording begins. The viewer
    % will not parse any messages, events, or samples, that exist in
    % the data file prior to this message.
    Eyelink('Message', 'TRIALID %d', 2*i-1);
            timepoints(i,2)  =  GetSecs;  
    % This supplies the title at the bottom of the eyetracker display
    Eyelink('command', 'record_status_message "TRIAL %d/%d"', 2*i-1, itemsPerBlock*2);
    % Before recording, we place reference graphics on the host display
            timepoints(i,3)  =  GetSecs;  
    %tell me what trial just started (to matlab command line)
    fprintf('trial # %i of %i\n', 2*i-1, itemsPerBlock*2)
            timepoints(i,4)  =  GetSecs;  
    % STEP 7.3
    % start recording eye position (preceded by a short pause so that
    % the tracker can finish the mode transition - used mainly if we're doing driftcorrection)
    % The paramerters for the 'StartRecording' call controls the
    % file_samples, file_events, link_samples, link_events availability
    Eyelink('Command', 'set_idle_mode');
            timepoints(i,5)  =  GetSecs;  
    WaitSecs(0.05);
            timepoints(i,6)  =  GetSecs;  

    Eyelink('StartRecording', 1, 1, 1, 1);    
    Eyelink('Message', '!V TRIAL_VAR category %s', 'object');
    Eyelink('Message', '!V TRIAL_VAR whetherwithmask %s', num2str(blankDur));
    if thepic<=9
    Eyelink('Message', '!V TRIAL_VAR whichimage %s%s',num2str(0), num2str(thepic));
    elseif thepic>=10
    Eyelink('Message', '!V TRIAL_VAR whichimage %s', num2str(thepic)); 
    end
    Eyelink('Message', '!V TRIAL_VAR whichAxis %s', num2str(whichStimuli));
    Eyelink('Message', '!V TRIAL_VAR whichSequence %s', num2str(sequentCode));
            timepoints(i,7)  =  GetSecs;  
    % record a few samples before we actually start displaying
    % otherwise you may lose a few msec of data
    
  
    % mark zero-plot time in data file
    Eyelink('Message', 'image_start');
    

		'endpoint7.1'
			
%             Eyelink('Message', 'start image: %s', thepic);
            
            
             
        
        if maxSize == 0 %should we present at encoded resolution?
            stimRect = round([center(1)-(width/2) center(2)-(height/2) center(1)+(width/2) center(2)+(height/2)]); % should center image
        else
                    timepoints(i,9)  =  GetSecs;  
            %dummy for the size of stimuli will be adjusted in the next step
            stimRect = round([center-(pixPerSide/2) center+(pixPerSide/2)]);
                    timepoints(i,10)  =  GetSecs;  
            %adjust stimRect to accomidate any aspect ratio
            if height > width
                adjustment = width/height;
                stimRect(1) = center(1)-(pixPerSide/2)*adjustment;
                stimRect(3) = center(1)+(pixPerSide/2)*adjustment;
            elseif width > height
                adjustment = height/width;
                stimRect(2) = center(2)-(pixPerSide/2)*adjustment;
                stimRect(4) = center(2)+(pixPerSide/2)*adjustment;
            end
        end
        'endpoint7.1.1'
    
        'endpoint7.1.2'
%     %Get the name of the IA template as well as the category to be used for the image.
%     [tempName catname]= getIAName(itemlist(thepic), n);
    'endpoint7.1.3'
    % Sends an integration message to link the appropriate interest area template
    % with each displayed picture.
    Eyelink('Message', '!V IAREA FILE InterestAreas/%s.ias', itemlist{thepic});
    
    'endpoint7.1.4'
    % Send an integration message so that an image can be loaded as
    % overlay backgound when performing Data Viewer analysis.  This
    % message can be placed anywhere within the scope of a trial (i.e.,
    % after the 'TRIALID' message and before 'TRIAL_RESULT')
    % See "Protocol for EyeLink Data to Viewer Integration -> Image
    % Commands" section of the EyeLink Data Viewer User Manual.
    Eyelink('Message', '!V IMGLOAD CENTER %s%s%s%s %d %d %d %d', 'axis',num2str(whichStimuli),'/',itemlist{thepic}, 800, 600, 800, 600 );
    %Eyelink('Message', '-%d !V IAREA FILE /InterestAreas/%s.ias', n,  
    %note that '!V' indicates a message to DataViewer (see chp. 7 Eyelink Data Vierwer user's manual 'Protocol for eyelink to dataviwer integration')
    
                timepoints(i,11)  =  GetSecs;  
         'endpoint7.2'  
			Screen('CopyWindow', offScrPtr(thepic), window, [], stimRect);
                    timepoints(i,12)  =  GetSecs;  
			presStart = GetSecs;
                    timepoints(i,13)  =  GetSecs;  
            Screen('Flip',window);  % display learning pictures
                    timepoints(i,14)  =  GetSecs;  
			while ~IsQuit & ((GetSecs - presStart)<itemDur)
				[keyIsDown,secs,keyCode] = KbCheck;
				if keyIsDown & keyCode(escKey),
					IsQuit=1;
					break;
				end
            end
                    timepoints(i,15)  =  GetSecs;  
            'endpoint7.3' 
            
      
            
                Eyelink('StopRecording');

    Eyelink('Message', 'TRIAL_RESULT 0');
    
         %% start recording mask trial 
    
    if blankDur > 0
    Eyelink('Message', 'TRIALID %d', 2*i);
            timepoints(i,2)  =  GetSecs;  
    % This supplies the title at the bottom of the eyetracker display
    Eyelink('command', 'record_status_message "TRIAL %d/%d"', i, itemsPerBlock*2);
    % Before recording, we place reference graphics on the host display
            timepoints(i,3)  =  GetSecs;  
    %tell me what trial just started (to matlab command line)
    fprintf('trial # %i of %i\n', i, itemsPerBlock*2)
            timepoints(i,4)  =  GetSecs;  
    % STEP 7.3
    % start recording eye position (preceded by a short pause so that
    % the tracker can finish the mode transition - used mainly if we're doing driftcorrection)
    % The paramerters for the 'StartRecording' call controls the
    % file_samples, file_events, link_samples, link_events availability
    Eyelink('Command', 'set_idle_mode');
            timepoints(i,5)  =  GetSecs;  
    WaitSecs(0.05);
            timepoints(i,6)  =  GetSecs; 

    Eyelink('StartRecording', 1, 1, 1, 1);    
    Eyelink('Message', '!V TRIAL_VAR category %s', 'mask');
    if thepic<=9
    Eyelink('Message', '!V TRIAL_VAR whichimage %s%s',num2str(0), num2str(thepic));
    elseif thepic>=10
    Eyelink('Message', '!V TRIAL_VAR whichimage %s', num2str(thepic)); 
    end
    Eyelink('Message', '!V TRIAL_VAR whichAxis %s', num2str(whichStimuli));
    Eyelink('Message', '!V TRIAL_VAR whichSequence %s', num2str(sequentCode));
            timepoints(i,7)  =  GetSecs;  
    % record a few samples before we actually start displaying
    % otherwise you may lose a few msec of data
    
  
    % mark zero-plot time in data file
    Eyelink('Message', 'image_start');
    
    %     %Get the name of the IA template as well as the category to be used for the image.
%     [tempName catname]= getIAName(itemlist(thepic), n);
    'endpoint7.1.3'
    % Sends an integration message to link the appropriate interest area template
    % with each displayed picture.
    Eyelink('Message', '!V IAREA FILE InterestAreas/%s.ias', itemlist_mask{1});
    
    'endpoint7.1.4'
    % Send an integration message so that an image can be loaded as
    % overlay backgound when performing Data Viewer analysis.  This
    % message can be placed anywhere within the scope of a trial (i.e.,
    % after the 'TRIALID' message and before 'TRIAL_RESULT')
    % See "Protocol for EyeLink Data to Viewer Integration -> Image
    % Commands" section of the EyeLink Data Viewer User Manual.
    Eyelink('Message', '!V IMGLOAD CENTER %s%s %d %d %d %d', 'mask/',itemlist_mask{1}, 800, 600, 800, 600 );
    %Eyelink('Message', '-%d !V IAREA FILE /InterestAreas/%s.ias', n,  
    %note that '!V' indicates a message to DataViewer (see chp. 7 Eyelink Data Vierwer user's manual 'Protocol for eyelink to dataviwer integration')

    
            
			Screen('CopyWindow', maskScrPtr, window, [], stimRect);
            Screen('Flip',window);  % display blank screen
			while ~IsQuit & ((GetSecs - presStart)<(itemDur+blankDur))
				[keyIsDown,secs,keyCode] = KbCheck;
				if keyIsDown & keyCode(escKey),
					IsQuit=1;
					break;
				end
            end
    end
                    timepoints(i,16)  =  GetSecs;  
 'endpoint7.4' 
 
%   stop the recording of eye-movements for the current trial
    Eyelink('StopRecording');
    Eyelink('Message', 'TRIAL_RESULT 0');
        
%                     if whetherfix == 1
% 			Screen('CopyWindow', fixation, window, [], CenterRect(pixRect, screenRect));
% 			Screen('Flip',window); % display fixation
%                     end
                    timepoints(i,17)  =  GetSecs;  
		    	
			if IsQuit==1
				break;
            end 
                    timepoints(i,18)  =  GetSecs;  
            	end		
		if IsQuit==1
			break;
		end
    end
    
    'endpoint8'
	experimentEnd = GetSecs;
	experimentDuration = experimentEnd - experimentStart;
    cd(dataDir);
	save( [Filefix, '.mat']);
	Screen('CloseAll');
	ShowCursor;
	cd(codeDir);
    
    
    %% shut down eyetracker
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.5);
Eyelink('CloseFile');

% download data file
cd (fullfile(rootDir,'data','eyetracking'))
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
cd (codeDir)

%close the eye tracker.
Eyelink('ShutDown');
	if IsQuit == 1
		disp('ESC is pressed to abort the program.');
		return;
	end

catch
    Screen('CloseAll');
    ShowCursor;
    cd(codeDir);
    disp('program error!!!.');
end % try ... catch %



