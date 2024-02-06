function y = SymbolsAvg_FP(x)
    global fp
    const=fi(1/3, 0, fp+1, fp+1);
    temp1(1:144)=(x(49:192)+x(529:672))/2;
    temp2(1:48)= const.data*(x(1:48)+x(241:288)+x(481:528));
    temp3(1:48)= const.data*(x(193:240) + x(433:480) + x(673:720));
    y1(1:48)=temp2;
    y1(49:192)=temp1;
    y1(193:240)=temp3;
    y=[y1 y1 y1];
 
    y = fi([y], 1, fp+1, fp);
end