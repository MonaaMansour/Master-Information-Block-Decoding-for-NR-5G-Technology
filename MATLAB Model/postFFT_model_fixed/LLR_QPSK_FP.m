function LLR=LLR_QPSK(x,No)
    global fp
    r=reshape(x,1,[]);
    rI=real(r);
    rQ=imag(r);
    A=1/sqrt(2);
    for i = 1 : length(r)
        LLR_first_bit(i)  = ( rI(i) ); %+ve = 0 , -ve = 1
        LLR_second_bit(i) = ( rQ(i) ); %+ve = 0 , -ve = 1
    end

    Soft(1,:) = LLR_first_bit;
    Soft(2,:) = LLR_second_bit;
    
    LLR=reshape(Soft,[1,2*length(r)]);
    LLR=fi([LLR], 1, 8, 7);
%      %hard decision
%      for i = 1 : 2 : num
%      LLR(i) = LLR_first_bit(i) < 0 ;
%      LLR(i+1) = LLR_second_bit(i+1) > 0 ;
%      end

end