function [ ] = RMListMaker()

nSess = 2;
nListIts = 16;
nTrialsEachMod = 6;
nTrialsFix = 8;
nConds = 4;
nTrialsPerBlock = 4;
nBlocksPerRun = 16;
condLabels = {'OLD' 'OLD' 'NEW' 'NEW' '+'};

for n = 1:nListIts
    for s = 1:nSess
          
        for c=1:nConds
            stims_h{c} = c*ones(1, nTrialsEachMod);
        end
        
        stims_h2 = [stims_h{:} 5*ones(1,nTrialsFix)];
        
        for b = 1:nBlocksPerRun
            modality_label = 2-mod(b,2);
            modality_h{b} = modality_label*ones(1, nTrialsPerBlock);            
        end
        
        [stims_Mod1] = Shuffle(stims_h2);
        [stims_Mod2] = Shuffle(stims_h2);
        
        modality = [modality_h{:}];
        
        stims = NaN(size(modality));
        stims(modality==1) = stims_Mod1;
        stims(modality==2) = stims_Mod2;
        
        
        for c=1:length(condLabels)
            stimTxt(stims==c) = condLabels(c); 
        end
        
        for m = 1:length(modality)
            modTxt{m} = modality(m);
        end
        
        RMList = [stimTxt' modTxt'] ;
        save (sprintf('RM_List_%g_%g', n, s), 'RMList' );
    end
end

end

