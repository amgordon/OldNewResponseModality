
function theData = ON_study(thePath,listName,sName, sNum, S,EncBlock, startTrial)


% Read in the list
cd(thePath.list);
list = load(listName);
theData.item = list.studyList(:,1);
theData.cond = list.studyList(:,2);
listLength = length(theData.cond);

% Diagram of trial
stimTime = 3.5;  % the word
blankTime = 1.5;
behLeadinTime = 4;

Screen(S.Window,'FillRect', S.screenColor);
Screen(S.Window,'Flip');

% preallocate:
trialcount = 0;
for preall = startTrial:listLength
    theData.onset(preall) = 0;
    theData.dur(preall) =  0;
    theData.stimResp{preall} = 'noanswer';
    theData.stimRT{preall} = 0;
end

hands = {'Left','Right'};
S.hsn = S.encHandNum;

% for the first block, display instructions
if EncBlock == 1
    ins_txt =  sprintf('On each trial of this task, you will be asked to make judgments about whether the displayed word is abstract or concrete.  If the word is abstract, please press the %s button.  If the word is concrete please press the %s button.  Please make your response before the fixation dot appears. ', hands{S.hsn}, hands{3-S.hsn});
    DrawFormattedText(S.Window, ins_txt, 'center','center',S.textColor, 75);
    Screen('Flip',S.Window);
    AG3getKey('g',S.kbNum);
end

% get ready screen
message = 'Press g to begin!';
[hPos, vPos] = AG3centerText(S.Window,S.screenNumber,message);
Screen(S.Window,'DrawText',message, hPos, vPos, S.textColor);
Screen(S.Window,'Flip');

% give the output file a unique name
cd(thePath.data);
matName = ['Acc1_encode_sub' num2str(sNum), '_date_' sName 'out.mat'];
checkEmpty = isempty(dir (matName));
suffix = 1;
while checkEmpty ~=1
    suffix = suffix+1;
    matName = ['Acc1_encode_' num2str(sNum), '_' sName 'out(' num2str(suffix) ').mat'];
    checkEmpty = isempty(dir (matName));
end

% Present test trials
goTime = 0;

Priority(MaxPriority(S.Window));

%initial fixation
AG3getKey('g',S.kbNum);
startTime = GetSecs;
goTime = goTime + behLeadinTime;
Screen('FillOval', S.Window, S.textColor, S.centerFix);
Screen(S.Window,'Flip');
AG3recordKeys(startTime,goTime,S.kbNum);  % not collecting keys, just a delay

%loop through trials
for Trial = startTrial:listLength
       trialcount = trialcount + 1;       
       ons_start = GetSecs;
       theData.onset(Trial) = GetSecs - startTime; %precise onset of trial presentation        
       
        % ITI
        goTime = blankTime;
        Screen('FillOval', S.Window, S.textColor, S.centerFix);
        Screen(S.Window,'Flip');
        AG3recordKeys(ons_start,goTime,S.boxNum);  % not collecting keys, just a delay     
        
        % Stim
        goTime = goTime + stimTime;
        stim = theData.item{Trial};
        DrawFormattedText(S.Window,stim,'center','center',S.textColor);
        Screen(S.Window,'Flip');
        [keys1 RT1] = AG3recordKeys(ons_start,goTime,S.boxNum); % not collecting keys, just a delay
        theData.stimResp{Trial} = keys1;
        theData.stimRT{Trial} = RT1;
                
        theData.dur(Trial) = GetSecs - ons_start;  %records precise trial duration
        cmd = ['save ' matName];
        eval(cmd);
        fprintf('%d\n',Trial);
end

eval(cmd);


Screen(S.Window,'FillRect', S.screenColor);	% Blank Screen
Screen(S.Window,'Flip');

% ------------------------------------------------
Priority(0);
