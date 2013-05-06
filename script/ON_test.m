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

for Trial = 1:listLength

    ons_start = GetSecs;    
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
    
    cmd = ['save ' matName];
    eval(cmd);
    
end


DrawFormattedText(S.Window,'Saving...','center','center', [100 100 100]);

cmd = ['save ' matName];
eval(cmd);
res = ON_analyzer(theData);

%fprintf(['\npct correct = ' num2str(res.pctCor)]);
%fprintf(['\npct legit = ' num2str(res.pctLegit)]);

Screen(S.Window,'FillRect', S.screenColor);	% Blank Screen
Screen(S.Window,'Flip');

ListenChar(1); % tell the command line to listen to key responses again.
Priority(0);

