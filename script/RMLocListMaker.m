function [  ] = RMLocListMaker(thePath)

% RM Localizer
numSessLoc = 4;
numListsLoc = 8;
nOptSeqPatternsPerRunLoc = 12;
blockOrderLoc = {[1 2 1 2 1 2 1 2 1 2 1 2] [2 1 2 1 2 1 2 1 2 1 2 1]};

for i = 1:numListsLoc;
    for j = 1:numSessLoc
        
        thisBlock = blockOrderLoc{1 + mod(j,length(blockOrderLoc))};
        
        modality = [];
        for o=1:nOptSeqPatternsPerRunLoc
            thisPattern = (j-1)*nOptSeqPatternsPerRunLoc+o;
            fid = fopen(fullfile(thePath.start, 'optseq', ['ex2-' prepend(thisPattern,3) '.par']));
            txt = textscan(fid, '%s %s %s');
            
            cond_h{o} = txt{2}(1:2:end);
            dur_h{o} = txt{3}(1:2:end);
            cond_h{o} = [cond_h{o}; '0'];
            if o==nOptSeqPatternsPerRunLoc
                dur_h{o} = [dur_h{o}; '10.00'];
            else
                dur_h{o} = [dur_h{o}; '4.000'];
            end
            
            thisModality = repmat(thisBlock(o), length(cond_h{o}), 1);
            modality = [modality; thisModality];
        end
        fclose('all');
        
        cond_h2 = vertcat(cond_h{:});
        dur_h2 = vertcat(dur_h{:});
        
        cond = str2num(vertcat(cond_h2{:}));
        dur = str2num(vertcat(dur_h2{:}));
        
        locList = [cond modality dur];
        save (sprintf('RM_Loc_List_%g_%g', i, j), 'locList' );
    end
end

