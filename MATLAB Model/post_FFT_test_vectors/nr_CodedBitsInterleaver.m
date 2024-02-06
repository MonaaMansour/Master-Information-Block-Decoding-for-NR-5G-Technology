function f = nr_CodedBitsInterleaver(e)
    E=864; %Number of input bits
    T=42; %T is the smallest integer such that T(T+1)≥ 2E
    I_BIL=1;
    if (I_BIL==1)
        k = 0 ; 
        for i=0:T-1
            for j=0:T-1-i
                if (k<E)
                    v(i+1,j+1)=e(k+1);
                else 
                    v(i+1,j+1)=NaN;
                end 
                k=k+1 ;
            end  
        end 
            k = 0;
           
        for j = 0:T-1
            for i=0:T-1-j
                if (~isnan(v(i+1,j+1)))
                    f(k+1)=v(i+1,j+1);
                    k=k+1;
                end 
            end     
        end    
    else 
        for i = 0:E-1
            f(i+1)=e(i+1) ; 
        end 
    end
end