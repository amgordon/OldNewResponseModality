function res = ON_analyzer(theData)

idxOld = theData.oldNew==1;
idxNew = theData.oldNew==2;

for i =1:length(theData.stimresp)
    if strcmp(theData.stimresp{i}, 'noanswer')
        recordedResp = theData.judgeResp{i};
    else
        recordedResp = theData.stimresp{i};
    end
    
    if iscell (recordedResp(1))
        firstResp{i} = recordedResp{1}(1);
    else
        firstResp{i} = recordedResp(1);
    end
end

firstResp = firstResp;
idx.respNew = ismember(firstResp, {'5' '4'});
idx.respOld = ismember(firstResp, {'1' '2' '3'});

idx.old = (theData.oldNew == 1);
idx.new = (theData.oldNew == 2);

idx.cor = idx.old .* idx.respOld + idx.new .* idx.respNew;

idx.legitResp = idx.respOld + idx.respNew;
idx.memoryTrials = idx.old + idx.new;

res.pctCor = sum(idx.cor) / sum(idx.legitResp);
res.pctLegit = sum(idx.legitResp) / sum(idx.memoryTrials);

res.pctCorRem = sum(strcmp(firstResp, '1') .* idx.old) / sum(strcmp(firstResp, '1'));
res.pctCorHiConfOld = sum(strcmp(firstResp, '2') .* idx.old) / sum(strcmp(firstResp, '2'));
res.pctCorLoConfOld = sum(strcmp(firstResp, '3') .* idx.old) / sum(strcmp(firstResp, '3'));
res.pctCorLoConfNew = sum(strcmp(firstResp, '4') .* idx.new) / sum(strcmp(firstResp, '4'));
res.pctCorHiConfNew = sum(strcmp(firstResp, '5') .* idx.new) / sum(strcmp(firstResp, '5'));

res.pctOldResp = sum(idx.respOld) / sum(idx.legitResp);