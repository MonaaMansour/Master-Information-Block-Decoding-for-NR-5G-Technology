function d_sss = nr_SSS(ncellid)
    
    ncellid_2 = mod(ncellid,3);
    ncellid_1 = ( ncellid - ncellid_2 ) / 3;
    %----------SSS m-sequence------------%
    
    %-----------x initialization----------------%
    x0_init=[1 0 0 0 0 0 0];
    x1_init=[1 0 0 0 0 0 0];
    
    %-----------x generation-------------%
    
    x0=zeros(1,127+7);
    x1=zeros(1,+7);
    
    x0(1:7)=x0_init;
    x1(1:7)=x1_init;
    
    
    m0 = 15 * floor(ncellid_1 / 112) + 5 * ncellid_2 ;
    m1 = mod( ncellid_1 , 112 );
    
    %-----------SSS generation-----------%
    for n=1:127
        x0(n+7) = mod((x0(n+4) + x0(n)),2);
        x1(n+7) = mod((x1(n+1) + x1(n)),2);
        
        d_sss(n) = ( 1-2 * x0( mod(m0+n-1,127) +1) ) * ( 1-2 * x1( mod(m1+n-1,127) +1) );
    end
    
end