function [  ] = AG3ListMaker()


y = load('192_words_Test_List');

%testSessLength = 80;
testTotalLength = 384;
numLists = 8;
numSess = 6;
numItems = 64;
nItemsPerBlock = 16;
nOptSeqPatternsPerRun = 4;
blockOrder = Shuffle({[1 2 1 2] [2 1 2 1] [1 2 2 1] [2 1 1 2] [1 1 2 2] [2 2 1 1]});

for i = 1:numLists;
    thisShuffleIdx = randperm(testTotalLength);
    wordList_all = y.testList(thisShuffleIdx,1);
    absCon_all = y.testList(thisShuffleIdx,2);
    
    oldNew_all = [];
    for j = 1:numSess
        
        %% opt seq stuff
        for o=1:nOptSeqPatternsPerRun
            thisPattern = (j-1)*nOptSeqPatternsPerRun+o;
            fid = fopen(['../optseq/' 'ex1-' prepend(thisPattern,3) '.par']);
            txt = textscan(fid, '%s %s %s');
            cond_h{o} = txt{2}(1:2:end);
            dur_h{o} = txt{3}(1:2:end);
            
            cond_h{o} = [cond_h{o}; '0'];
            
            if o==nOptSeqPatternsPerRun
                dur_h{o} = [dur_h{o}; '10.00'];
            else
                dur_h{o} = [dur_h{o}; '4.000'];
            end
            
            dur_h{o} = cellfun(@(x) x(1:5), dur_h{o}, 'UniformOutput',false);
        end
        cond_h2 = vertcat(cond_h{:});
        dur_h2 = vertcat(dur_h{:});
        
        oldNew = str2num(vertcat(cond_h2{:}));
        dur = str2num(vertcat(dur_h2{:}));
        
        %
        %oldNew = ceil(randperm(testSessLength-1)/(numItems/2));
        %oldNew(oldNew>2)=0;
        
        wordList = cell(size(oldNew));
        absCon = cell(size(oldNew));
        wordList(oldNew>0) = wordList_all(1+(j-1)*numItems:(j)*numItems);
        wordList(oldNew==0) = {'+'};
        absCon(oldNew>0) = absCon_all(1+(j-1)*numItems:(j)*numItems);
        absCon(oldNew==0) = {0};
                     
        %modality = 2 - mod(ceil((1:(length(oldNew)))/nItemsPerBlock),2);
        thisBlock = blockOrder{1 + mod(j,length(blockOrder))};
        
        modality = [];
        for o=1:nOptSeqPatternsPerRun
            thisModality = repmat(thisBlock(o), length(cond_h{o}), 1);
            modality = [modality; thisModality];
        end
        
        
        testList = [wordList absCon num2cell(oldNew) num2cell(modality) num2cell(dur)];
        save (sprintf('192_words_Test_List_%g_%g', i,j), 'testList' );
        
        % now make the 2nd half of lists, this time switching which is old and which
        % new.
        testList = [wordList absCon num2cell(mod(3-oldNew,3)) num2cell(modality) num2cell(dur)];
        save (sprintf('192_words_Test_List_%g_%g', i+numLists, j), 'testList' );
        
        oldNew_all = [oldNew_all; oldNew];
        
    end
    oldNew_all(oldNew_all==0) = [];
    
    wordListStudy = wordList_all(oldNew_all==1);
    absConStudy = absCon_all(oldNew_all==1);
    
    p = randperm(length(wordListStudy));
    wordListStudy = wordListStudy(p);
    absConStudy = absConStudy(p);
    
    studyList = [wordListStudy absConStudy];
    
    save (sprintf('192_words_Study_List_%g', i), 'studyList');
    
    % now make the 2nd half of lists, switching old and new.
    wordListStudy = wordList_all(oldNew_all==2);
    absConStudy = absCon_all(oldNew_all==2);
    wordListStudy = wordListStudy(p);
    absConStudy = absConStudy(p);
    studyList = [wordListStudy absConStudy];
    save (sprintf('192_words_Study_List_%g', i+numLists), 'studyList');
end

% code for making the second, shuffled, study list.
for i=1:16
    
    d = dir(sprintf('192_words_Study_List_%g.mat', i));
    
    y = load(d(1).name);
    
    studyList = y.studyList; 
    save (sprintf('192_words_Study_List_%g_1', i), 'studyList');
    
    nItems = size(y.studyList,1);
    shfIdx = Shuffle(1:nItems);
    
    words = y.studyList(shfIdx,1);
    absCon = y.studyList(shfIdx,2);
    
    studyList = [words absCon]; 
    save (sprintf('192_words_Study_List_%g_2', i), 'studyList');
    
end
         