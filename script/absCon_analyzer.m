function res = absCon_analyzer(datStruct)

hsn = datStruct.S.encHandNum;
fingers = {'q', 'p'};

theData = datStruct.respSelData;

conds = [theData.cond{:}];
resps = theData.stimResp;

respAbs = strcmp(resps, fingers{3-hsn});
respCon = strcmp(resps, fingers{hsn});
respLegit = respAbs + respCon;

res.corAbs = sum(respAbs .* (conds==1) ) / sum(conds==1 .* respLegit);
res.corCon = sum(respCon.* (conds==2) ) / sum(conds==2 .* respLegit);

res.pctLegit = mean(respLegit);