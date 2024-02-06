function dmrs = nr_DMRS(issb,ncellid,n_hf)
    
    Mpn=144*2;
    v=issb;
    GoldSeq=nr_GoldSeqGen(issb,ncellid,'dmrs',n_hf);
    dmrs=nr_QPSK(GoldSeq(1:288));
%     str="X";
%     for(i=1:2:287)
%         if (dmrs((i+1)/2)== 0.6875+0.6875i)
%             str(i)   = string('01011');
%             str(i+1) = string('01011');
%         elseif (dmrs((i+1)/2)== 0.6875-0.6875i)
%             str(i)   = string('01011');
%             str(i+1) = string('10101');
%         elseif (dmrs((i+1)/2)== -0.6875+0.6875i)
%             str(i)   = string('10101');
%             str(i+1) = string('01011');
%         elseif (dmrs((i+1)/2)== -0.6875-0.6875i)
%             str(i)   = string('10101');
%             str(i+1) = string('10101');
%         end
%         
%     end

end
