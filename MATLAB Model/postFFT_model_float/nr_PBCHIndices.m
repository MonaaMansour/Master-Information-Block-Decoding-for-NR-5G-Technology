function indices = nr_PBCHIndices(ncellid)
if(mod(ncellid,4)==0)
    index=242;
    j=1;
    for i=1:145
        if(index==530)
            index=674;
            j=j-3;
        else
        indices(j:j+2)=[index index+1 index+2];
        index=index+4;
        end
        j=j+3;
    end
end

if(mod(ncellid,4)==1)
    index=241;
    j=1;
    for i=1:144
        if(index==241)
            indices(j)=index;
            index=243;
            j=j+1;
        end
        if(index==527)
            indices(j:j+2)=[index index+1 673];
            index=675;
        else
            if(index==959)
                indices(j:j+1)=[index index+1];
            else
                indices(j:j+2)=[index index+1 index+2];
                index=index+4;
            end
        end
        j=j+3;
    end
end

if(mod(ncellid,4)==2)
    index=241;
    j=1;
    for i=1:144
        if(index==241)
            indices(j:j+1)=[index index+1];
            index=244;
            j=j+2;
        end
        if(index==528)
            indices(j:j+2)=[index 673 674] ;
            index=676;
        else
            if(index==960)
                indices(j)=index;
            else
                indices(j:j+2)=[index index+1 index+2];
                index=index+4;
            end
        end
        j=j+3;
    end
end

if(mod(ncellid,4)==3)
    index=241;
    j=1;
    for i=1:144
        if(index==241)
            indices(j:j+2)=[index index+1 index+2];
            index=245;
            j=j+3;
        end
        if(index==529)
            index=673;
            j=j-3;
        else
            indices(j:j+2)=[index index+1 index+2];
            index=index+4;
        end
        j=j+3;
    end
end
end