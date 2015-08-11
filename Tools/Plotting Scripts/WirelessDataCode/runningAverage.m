function [avgArr, varArr] = runningAverage(x,N)
    avgArr = [];
    varArr = [];
    for i = 1:(length(x)-N)
       avgArr(i) = 1/N*sum(x(i:(i+N-1))); 
       varArr(i) = var(x(i:(i+N-1)));
    end
end