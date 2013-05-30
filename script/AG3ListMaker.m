y = load('160_words_Test_List');
testSessLength = 80;
testTotalLength = 320;
numLists = 8;
numSess = 5;
numItems = 64;
nItemsPerBlock = 4;

for i = 1:numLists;
    thisShuffleIdx = randperm(testTotalLength);
    wordList_all = y.studyList(thisShuffleIdx,1);
    absCon_all = y.studyList(thisShuffleIdx,2);
    
    oldNew_all = [];
    for j = 1:numSess
        oldNew = ceil(randperm(testSessLength-1)/(numItems/2));
        oldNew(oldNew>2)=0;
        
        wordList = cell(size(oldNew));
        absCon = cell(size(oldNew));
        wordList(oldNew>0) = wordList_all(1+(j-1)*numItems:(j)*numItems);
        wordList(oldNew==0) = {'+'};
        absCon(oldNew>0) = absCon_all(1+(j-1)*numItems:(j)*numItems);
        absCon(oldNew==0) = {0};
             
        %The last event is a '+'
        wordList{testSessLength} = '+';
        absCon{testSessLength} = 0;
        oldNew(testSessLength) = 0;
        
        modality = 2 - mod(ceil((1:(length(oldNew)))/nItemsPerBlock),2);
        
        testList = [wordList' absCon' num2cell(oldNew') num2cell(modality)'];
        save (sprintf('160_words_Test_List_%g_%g', i,j), 'testList' );
        
        % now make the 2nd half of lists, this time switching which is old and which
        % new.
        testList = [wordList' absCon' num2cell(mod(3-oldNew',3)) num2cell(modality)'];
        save (sprintf('160_words_Test_List_%g_%g', i+numLists, j), 'testList' );
        
        oldNew_all = [oldNew_all oldNew];
        
    end
    oldNew_all(oldNew_all==0) = [];
    
    wordListStudy = wordList_all(oldNew_all==1);
    absConStudy = absCon_all(oldNew_all==1);
    
    p = randperm(length(wordListStudy));
    wordListStudy = wordListStudy(p);
    absConStudy = absConStudy(p);
    
    studyList = [wordListStudy absConStudy];
    
    save (sprintf('160_words_Study_List_%g', i), 'studyList');
    
    % now make the 2nd half of lists, switching old and new.
    wordListStudy = wordList_all(oldNew_all==2);
    absConStudy = absCon_all(oldNew_all==2);
    wordListStudy = wordListStudy(p);
    absConStudy = absConStudy(p);
    studyList = [wordListStudy absConStudy];
    save (sprintf('160_words_Study_List_%g', i+numLists), 'studyList');
end