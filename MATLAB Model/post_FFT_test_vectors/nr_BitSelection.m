function e = nr_BitSelection(y)
    N=512; %Number of input bits
    E=864; %Number of output bits
    %-----CASE (E>N)------%
%    if (E>=N)
        for k=0:E-1
            e(k+1)=y(mod(k,N)+1);
        end
%    else 
%         if (K/E <= 7/16) 
%             for k = 0: E-1
%                 e(k+1)=y(k+N-E+1); 
%             end
%         else 
%             for k = 0:E-1 
%                 e(k)=y(k); 
%             end 
%         end 
%     end
end