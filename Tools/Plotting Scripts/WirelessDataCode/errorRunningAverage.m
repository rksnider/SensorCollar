function [avgArr, varArr, varError] = errorRunningAverage(x,e,N)
    avgArr = [];
    varArr = [];
    for i = 1:(length(x)-N)
        inds = i:(i+N-1);
        goodinds = inds(find(e(inds) == 0));
        badinds = setdiff(inds,goodinds);
        avgArr(i) = 1/N*sum(x(inds)); 
        varArr(i) = var(x(goodinds));
        if ~isempty(badinds)
            varError(i) = var(x(inds));
        else
            varError(i) = 0;
        end
        if isempty(goodinds)
            goodinds
            avgArr(i) = 1/N*sum(x(inds));
            varError(i) = 100*var(x(inds));
        end
    end