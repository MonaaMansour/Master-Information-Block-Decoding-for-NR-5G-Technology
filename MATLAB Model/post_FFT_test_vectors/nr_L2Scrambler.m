function out = nr_L2Scrambler(in,issb,ncellid,type)

c = nr_GoldSeqGen(issb,ncellid,'scrambler');

%---------------------Scrambler-------------------------%
    v=issb;
    Mpn=864;
    
        for i=1:Mpn
            if (type=="binary")
            out(i)=mod ( in(i)+c(i+v*Mpn),2);
            elseif (type=="llr")
                c(i+v*Mpn)= 1-2*c(i+v*Mpn);
                out(i)=in(i)*c(i+v*Mpn);
                
            end
        end
    
    
    
end