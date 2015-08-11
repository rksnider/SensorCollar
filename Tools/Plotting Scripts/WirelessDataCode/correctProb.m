function [P,avgDbm,N] = correctProb(errorArray,yvals,dBm,lowerLim,upperLim)
    inds = find(yvals < upperLim & yvals > lowerLim);
    avgDbm = mean(dBm(inds));
    P = sum(errorArray(inds))./size(inds,1);
    N = size(inds,1);
end