function d_pss = nr_PSS(ncellid)
    
    n_id_2 = mod(ncellid,3);
    %----------PSS m-sequence------------%
    
    %-----------x initialization----------------%
    x_init=[0 1 1 0 1 1 1];
    
    %-----------x generation-------------%
    x=zeros(1,127+7);
    x(1:7)=x_init;
    
    %-----------PSS generation-----------%
    for n=1:127
        x(n+7) = mod((x(n+4) + x(n)),2);
        
        m = mod( ( n-1 + 43 * n_id_2) ,127);
        
        d_pss(n) = 1-2*x(m+1);
    end
    
end