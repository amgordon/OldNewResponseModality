
function ONRMrun(thePath, sName, sNum, testType, scanner, startBlock)
% function AG3run(thePath)
% e.g. AG3run(thePath, '66Feb66', 5, 4, 0, 1)
%
% Get experiment info
if nargin == 0
    error('Must specify thePath')
end

sName = 'xxxxxxx';
if nargin<2
    while (length(sName) > 4)
    sName = input('Enter name, max 4 chars (e.g. ''AG'') ','s');
    end
end

if nargin<3
    sNum = input('Enter subject number: ');
end

if nargin<4
    testType = 0;
    while ~ismember(testType,[1,2,3,4,5])
        testType = input('Which task?  ON_S[1] ON_TPrac[2] ON_S2[3] ON_T[4] ON_L[5]? ');
    end
end

if nargin<5
    S.scanner = 0;
    while ~ismember(S.scanner,[1:4])
        S.scanner = input('In scanner [1] behavioral [2] mock scanner [3] or eye-tracker [4]? ');
    end
else
    S.scanner = scanner;
end

if nargin<6
    S.startBlock = 0;
    while ~ismember(S.startBlock,[1:6])
        S.startBlock = input('At which block would you like to start?  ');
    end
else
    S.startBlock = startBlock;
end

S.subData = fullfile(thePath.data, [sName '_' num2str(sNum)]);
if ~exist(S.subData)
    mkdir(S.subData);
end

% Set input device (keyboard or buttonbox)
if S.scanner == 1
    [S.boxNum S.boxType] = AG3getBoxNumber;  % buttonbox
    S.kbNum = AG3getKeyboardNumber; % keyboard
    S.textSize = 30;
elseif S.scanner == 3 % Mock scanner
    [S.boxNum S.boxType] = AG3getBoxNumber;  % buttonbox
    S.kbNum = AG3getKeyboardNumber; % keyboard
    S.textSize = 30;
elseif S.scanner == 4% eye tracker
    [S.boxNum S.boxType] = AG3getBoxNumber;  % buttonbox
    S.kbNum = AG3getKeyboardNumber; % keyboard
    S.textSize = 20;
else
    S.boxNum = AG3getKeyboardNumber;  % buttonbox
    S.kbNum = AG3getKeyboardNumber; % keyboard
    S.textSize = 30;
end

%   Condition numbers
%-------------------------------
% listNum is 1-8, based on sNum (e.g. if sNum=11, listNum=3)
listNum = mod(sNum-1,12)+1;

% encCondNum is 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 2 2 2...
S.encCondNum = 2 - mod(ceil(sNum/8),2);

% respSelCondNum is 1 2 1 2 1 2 1 2
S.respSelCondNum = 2-mod(sNum,2);
S.encHandNum = 2-mod(sNum,2);
S.retHandNum = 2-mod(ceil(sNum/2),2);
S.respSelHandNum = 2-mod(sNum,2);


%-------------------------------
HideCursor;

% Screen commands
S.screenNumber = max(Screen('Screens'));
S.screenColor = 255;
S.textColor = 0;
S.blinkColor  = [0 0 0];
[S.Window, S.myRect] = Screen(S.screenNumber, 'OpenWindow', S.screenColor, [], 32);
Screen('TextSize', S.Window, S.textSize);
% oldFont = Screen('TextFont', S.Window, 'Geneva')
Screen('TextStyle', S.Window, 1);
S.on = 1;  % Screen now on
S.sqsz = 20;
S.maxCharsOnLine = 75;

resolution=Screen('Resolution', S.screenNumber);
S.scrsz = [1 1 resolution.width, resolution.height];
% sca
% 
% scr_h = get(0,'MonitorPositions');
% S.scrsz = scr_h(1,:);
% S.scrsz(2) = 1;

radius = round(min(S.scrsz(3:4)));
xL = S.scrsz(3);
yL = S.scrsz(4);

S.bottomSquare = [(xL-S.sqsz)/2, (yL+radius-S.sqsz)/2, (xL+S.sqsz)/2, (yL+radius+S.sqsz)/2];
S.rightSquare = [(xL+radius-S.sqsz)/2, (yL-S.sqsz)/2, (xL+radius+S.sqsz)/2, (yL+S.sqsz)/2];
S.topSquare = [(xL-S.sqsz)/2, (yL-radius-S.sqsz)/2, (xL+S.sqsz)/2, (yL-radius+S.sqsz)/2];
S.leftSquare = [(xL-radius-S.sqsz)/2, (yL-S.sqsz)/2, (xL-radius+S.sqsz)/2, (yL+S.sqsz)/2];

S.bottomRightSquare = [(xL+radius-S.sqsz)/2, (yL+radius-S.sqsz)/2, (xL+radius+S.sqsz)/2, (yL+radius+S.sqsz)/2];
S.bottomLeftSquare = [(xL-radius-S.sqsz)/2, (yL+radius-S.sqsz)/2, (xL-radius+S.sqsz)/2, (yL+radius+S.sqsz)/2];
S.topRightSquare = [(xL+radius-S.sqsz)/2, (yL-radius-S.sqsz)/2, (xL+radius+S.sqsz)/2, (yL-radius+S.sqsz)/2];
S.topLeftSquare = [(xL-radius-S.sqsz)/2, (yL-radius-S.sqsz)/2, (xL-radius+S.sqsz)/2, (yL-radius+S.sqsz)/2];

fixRad = 12;
S.centerFix = [(xL-fixRad)/2, (yL-fixRad)/2, (xL+fixRad)/2, (yL+fixRad)/2];
S.leftFix = [(xL-radius-fixRad)/2, (yL-fixRad)/2, (xL-radius+fixRad)/2, (yL+fixRad)/2];
S.rightFix = [(xL+radius-fixRad)/2, (yL-fixRad)/2, (xL+radius+fixRad)/2, (yL+fixRad)/2];

textRad = 30;
S.leftText = (xL-radius-textRad)/2;
S.rightText = (xL+radius-110)/2;

if ismember(S.scanner, [1,4])
    S.useEL = 1;
else
    S.useEL = 0;
end

if testType == 1
    saveName = ['ONRMStudy' sName '_' num2str(sNum) '.mat'];
    
    for RespSelBlock = 1
        listName = sprintf('192_words_Study_List_%g_1.mat', mod(sNum, 16));
        respSelData(RespSelBlock) = ON_study(thePath,listName,sName,sNum,S,RespSelBlock, 1);
    end
    
    checkEmpty = isempty(dir (saveName));
    suffix = 1;
    
    while checkEmpty ~=1
        suffix = suffix+1;
        saveName = ['ONRMStudy_' sName '_' num2str(sNum) '(' num2str(suffix) ')' '.mat'];
        checkEmpty = isempty(dir (saveName));
    end
    
    eval(['save ' saveName]);

    
elseif testType == 2
    if S.useEL
%         if S.scanner==1
%             Eyelink('SetAddress', '10.0.3.2');
%         end

        if Eyelink('initialize') ~= 0
            fprintf('error in connecting to the eye tracker\n\n');
            return;
        end
        
        S.edfFileBase = [sName '_L'];
        
        S.el=EyelinkInitDefaults(S.Window);
        
        [v vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    end
    
    for RMLocBlock = S.startBlock:4
        %listName = ['Test_List_' num2str(listNum)  '.mat'];
        listName = ['RM_Loc_List_' num2str(1+mod(sNum,16)) '_' num2str(RMLocBlock) '.mat'];
        testPracData(RMLocBlock) = RM_Loc(thePath,listName,sName,sNum,RMLocBlock, S);
    end

   
    checkEmpty = isempty(dir (saveName));
    suffix = 1;
    
    while checkEmpty ~=1
        suffix = suffix+1;
        saveName = ['testPrac_' sName '_' num2str(sNum) '(' num2str(suffix) ')' '.mat'];
        checkEmpty = isempty(dir (saveName));
    end
    
    eval(['save ' saveName]);
    
    if S.useEL
        Eyelink('ShutDown');
    end
 
elseif testType == 3
    saveName = ['ONRMStudyRound2' sName '_' num2str(sNum) '.mat'];
    
    for RespSelBlock = 1
        listName = sprintf('192_words_Study_List_%g_2.mat', mod(sNum, 16));
        respSelData(RespSelBlock) = ON_study(thePath,listName,sName,sNum,S,RespSelBlock, 1);
    end
    
    checkEmpty = isempty(dir (saveName));
    suffix = 1;
    
    while checkEmpty ~=1
        suffix = suffix+1;
        saveName = ['ONRMStudyRound2_' sName '_' num2str(sNum) '(' num2str(suffix) ')' '.mat'];
        checkEmpty = isempty(dir (saveName));
    end
    
    eval(['save ' saveName]);
    
elseif testType == 4
    saveName = ['ONRMTest' sName '_' num2str(sNum) '.mat'];
    
    if S.useEL
%         if S.scanner==1
%             Eyelink('SetAddress', '10.0.3.2');
%         end
        
        if Eyelink('initialize') ~= 0
            fprintf('error in connecting to the eye tracker\n\n');
            return;
        end
        
        S.edfFileBase = [sName '_T'];
        
        S.el=EyelinkInitDefaults(S.Window);
        
        [v vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    end
    
    for ONTestBlock = S.startBlock:6
        %listName = ['Test_List_' num2str(listNum)  '.mat'];
        listName = ['192_words_Test_List_' num2str(mod(sNum,16)) '_' num2str(ONTestBlock) '.mat'];
        ONTestData(ONTestBlock) = ON_test(thePath,listName,sName,sNum,ONTestBlock, S);
    end
    
    checkEmpty = isempty(dir (saveName));
    suffix = 1;
    
    while checkEmpty ~=1
        suffix = suffix+1;
        saveName = ['AG3_ONTest_' sName '_' num2str(sNum) '(' num2str(suffix) ')' '.mat'];
        checkEmpty = isempty(dir (saveName));
    end
    
    eval(['save ' saveName]);
    
    if S.useEL
        Eyelink('ShutDown');
    end
    % Output file for each block is saved within BH1test; full file saved
    % here
    
    
elseif testType == 5
        saveName = ['RMLoc' sName '_' num2str(sNum) '.mat'];
    
    if S.useEL
%         if S.scanner==1
%             Eyelink('SetAddress', '10.0.3.2');
%         end
        
        if Eyelink('initialize') ~= 0
            fprintf('error in connecting to the eye tracker\n\n');
            return;
        end
        
        S.edfFileBase = [sName '_L'];
        
        S.el=EyelinkInitDefaults(S.Window);
        
        [v vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    end
    
    for RMLocBlock = S.startBlock:4
        %listName = ['Test_List_' num2str(listNum)  '.mat'];
        listName = ['RM_Loc_List_' num2str(1+mod(sNum-1,16)) '_' num2str(RMLocBlock) '.mat'];
        RMLocData(RMLocBlock) = RM_Loc(thePath,listName,sName,sNum,RMLocBlock, S);
    end

   
    checkEmpty = isempty(dir (saveName));
    suffix = 1;
    
    while checkEmpty ~=1
        suffix = suffix+1;
        saveName = ['RMLoc_' sName '_' num2str(sNum) '(' num2str(suffix) ')' '.mat'];
        checkEmpty = isempty(dir (saveName));
    end
    
    eval(['save ' saveName]);
    
    if S.useEL
        Eyelink('ShutDown');
    end

end

message = 'End of script. Press any key to exit.';
[hPos, vPos] = AG3centerText(S.Window,S.screenNumber,message);
Screen(S.Window,'DrawText',message, hPos, vPos, 255);
Screen(S.Window,'Flip');
pause;
Screen('CloseAll');

