function y = LinearIntrp(x,ncellid)
    dmrsIndices=nr_DMRSIndices(ncellid)-240;
    y=zeros(1,4*length(x));
    for i = 1:length(x)
        y (dmrsIndices(i))= x(i);
    end
     
    %y(1,1:4*length(x))=temp;
    m=mod(ncellid,4)+1;
    jump=0;
    for i=1:length(x)-1
       
       for j =1:3
           
           %if(m+j > 288)
           %    jump=144;
           %end
           
           y(j+m+jump) = x(i)+( (x(i+1) - x(i) ) / 4)*j;
       end
       m=m+4;
    end
    
    if(mod(ncellid,4)==0)
        y(length(x)*4-2) = x(length(x));
        y(length(x)*4-1) = x(length(x));
        y(length(x)*4)   = x(length(x));
    elseif (mod(ncellid,4)==1)
        y(1) = x(1);
        y(length(x)*4-1) = x(length(x));
        y(length(x)*4) = x(length(x));
    elseif (mod(ncellid,4)==2)
        y(1) = x(1);
        y(2) = x(1);
        y(length(x)*4) = x(length(x));
    else
        y(1) = x(1);
        y(2) = x(1);
        y(3) = x(1);
    end
    
    
    
    
    
    
    
%     if(mod(ncellid,4)==0)
%         y(718) = x(144);
%         y(719) = x(144);
%         y(720) = x(144);
%     elseif (mod(ncellid,4)==1)
%         y(1) = x(1);
%         y(719) = x(144);
%         y(720) = x(144);
%     elseif (mod(ncellid,4)==2)
%         y(1) = x(1);
%         y(2) = x(1);
%         y(720) = x(144);
%     else
%         y(1) = x(1);
%         y(2) = x(1);
%         y(3) = x(1);
%     end
    
    
    
%     if(mod(ncellid,4)==0)
%         y(718) = x(144)+( (x(144) - x(143)) / 4);
%         y(719) = x(144)+( (x(144) - x(143)) / 4)*2;
%         y(720) = x(144)+( (x(144) - x(143)) / 4)*3;
%     elseif (mod(ncellid,4)==1)
%         y(1) = 0+( (x(2) - x(1)) / 4)*3;
%         y(719) = x(144)+( (x(144) - x(143) ) / 4)*1;
%         y(720) = x(144)+( (x(144) - x(143) )/ 4)*2;
%     elseif (mod(ncellid,4)==2)
%         y(1) = 0+( (x(2) - x(1)) / 4)*2;
%         y(2) = 0+( (x(2) - x(1)) / 4)*3;
%         y(720) = x(144)+( x(144) - x(143) ) / 4;
%     else
%         y(1) = 0+( (x(2) - x(1)) / 4);
%         y(2) = 0+( (x(2) - x(1)) / 4)*2;
%         y(3) = 0+( (x(2) - x(1)) / 4)*3;
%     end
end