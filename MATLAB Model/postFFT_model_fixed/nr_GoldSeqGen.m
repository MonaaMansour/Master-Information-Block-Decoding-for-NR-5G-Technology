function c = nr_GoldSeqGen(issb,ncellid,type,n_hf)

%---------X1 initialization------------%
    x1_init(1)=1;
    x1_init(2:31)=0;
    
%---------X2 initialization------------%
%---------X2 = binary value of ncellid-%
    if(type=="scrambler")
        
        c_init=ncellid;
        
        Mpn = 864; % Mpn is the length of the final sequence c
    elseif(type=="dmrs")
        issb_bar=issb+4*n_hf;
        
        Mpn = 144*2; % Mpn is the length of the final sequence c
        
        c_init=(2^11) * (issb_bar+1) * (floor(ncellid/4)+1) + (2^6) * (issb_bar+1) + mod(ncellid,4);  
    elseif(type=='MIBScrambler')
        c_init=ncellid;
        Mpn = 32+0*29;
        %v_internal= v;
    end
    
    x2_init(1:31)=[0:30];
    
    %if(ncellid==0)
    %    x2_init(1:31)=zeros(1,31);
    %else
        for i = 31:-1:1
            if ( (c_init/ (2^x2_init(i) ) ) >= 1)
                c_init=c_init-2^x2_init(i);
                x2_init(i)=1;   
            else
                x2_init(i)=0;
            end
        end
    %end
    
    %--------------generating gold-sequence C-------------%
    
    
    Nc = 1600;
    v=issb;
    
    x1 = zeros(1,Nc+(Mpn)*(v+1));
    x2 = zeros(1,Nc+(Mpn)*(v+1));
    c = zeros(1,Mpn*(v+1));

    % Initialize x1() and x2()
    x1(1:31) = x1_init;
    x2(1:31) = x2_init;

    % generate the m-sequences x1,x2
    % each 31 elements are generated from the previous 31
    for n = 1 : Nc+Mpn*(v+1)-31
        x1(n+31) = mod(x1(n+3) + x1(n),2);
        x2(n+31) = mod(x2(n+3) + x2(n+2) + x2(n+1) + x2(n),2);
    end

    % generate the resulting sequence (Gold Sequence)
    for n = 1 : Mpn*(v+1)
        c(n) = mod(x1(n+Nc) + x2(n+Nc),2);
    end
end