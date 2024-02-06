function y=ErrorsNum(x1,x2)
    error=0;
    for i=1:length(x1)
        if (x1(i) ~= x2(i))
              error = error+1;
        end
    end
    y = error;
end