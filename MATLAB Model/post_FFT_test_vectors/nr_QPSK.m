function qpsk_mapped = nr_QPSK(in)
    
    for i=1:length(in)
        if mod(i,2) == 0
            var2=in(i);
            qpsk_mapped(i/2)=(1/sqrt(2)) * ( (1-2*var1)+(1-2*var2)*1i);
        else var1=in(i);
        end
    end
    
end
