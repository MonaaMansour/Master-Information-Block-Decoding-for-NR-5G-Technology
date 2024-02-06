function indices = nr_DMRSIndices(ncellid)
    
    firstIndex = mod(ncellid,4) + 240 +1;
    
    indices(1)=firstIndex;
    
    for i = 1:143
        
        temp=indices(i);
        indices(i+1) = indices(i) + 4 ;
        if ( ( (indices(i) + 4) > 528 ) && ( indices(i) + 4) < 673 ) 
            indices(i+1)=indices(i)+144+4;
        end
        
    end
end
