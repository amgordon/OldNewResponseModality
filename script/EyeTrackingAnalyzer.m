function dat = EyeTrackingAnalyzer(ascfile)

fid = fopen(ascfile);
C = textscan(fid, '%s %s %s %s %s %s %s %s');

thr.left = 400;
thr.up = 750;
thr.down = 750;
thr.right = 400;



xCoords_h = C{6};
yCoords_h = C{7};

xCoords = cell(size(xCoords_h));
yCoords = cell(size(yCoords_h));
for i=1:length(yCoords_h)
    yCoords{i} = str2num(yCoords_h{i});
    xCoords{i} = str2num(xCoords_h{i});
end

%start times of trials
ixTrialID = find(strcmp(C{3}, 'TRIALID'));
ixTrialIDBounded = [ixTrialID; Inf];

%times at which fixation ended
ixFixEnd = find(strcmp(C{1}, 'EFIX'));

resp = -1*ones(size(ixTrialID));
rt = -1*ones(size(ixTrialID));

%loop through trials
for t = 1:length(ixTrialID)
    thisTrialIx = ixTrialID(t);
    nextTrialIx = ixTrialIDBounded(t+1);
    
    trialStartTime = str2num(C{2}{thisTrialIx});
    theseFixs = ixFixEnd((ixFixEnd>=thisTrialIx)&(ixFixEnd<nextTrialIx));
    theseTimepoints = C{3}(theseFixs);
    
    % loop through all fixations within this trial
    for f=1:length(theseFixs)
        
        thisX  = xCoords{theseFixs(f)};
        thisY  = yCoords{theseFixs(f)};
        thisTimePoint = theseTimepoints{f};
        if (~isempty(thisX) && ~isempty(thisY))
            thisCorner = coordsToCorner(thisX, thisY,thr);
            if (thisCorner~=-1)
                % if fixation is in a corner, report resp and rt and break
                % out of for loop
                resp(t) = thisCorner;
                rt(t) =  str2num(thisTimePoint) - trialStartTime;
                
                break
            end
        end
    end
    
end


dat.resp = resp;
dat.rt = rt;

end

function direction = coordsToCorner(xCoord,yCoord, thr)



if ((xCoord < thr.left) && (yCoord < thr.up))
    direction = 1;
elseif ((xCoord > thr.right) && (yCoord < thr.up))
    direction = 2;
elseif ((xCoord > thr.right) && (yCoord > thr.down))
    direction = 3;
elseif ((xCoord < thr.left) && (yCoord > thr.down))
    direction = 4;
else
    direction = -1;
end



end



