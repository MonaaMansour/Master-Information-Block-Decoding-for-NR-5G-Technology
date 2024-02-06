function y = SincIntrp(EstimatedValues)
    %EstimatedValues size = 1*144 (DMRS Values)
    B=4;
    nTaps=1;
    %% First pbch symbol
    f=linspace(0,239,240);
    for i = 1:60
        
        sincs_1(i,:) = EstimatedValues(i)  * sinc((f-B*(i-1))*nTaps/B); 
    end
    y(1:240) = sum(sincs_1);
    %% Second pbch symbol (first 48 SCs)
    f=linspace(0,47,48);
    for i = 1:12
        temp(i,:)=(f-B*(i-1))/256;
        sincs_2_1(i,:) = EstimatedValues(i+60)  * sinc((f-B*(i-1))*nTaps/B); 
    end
    y(241:288) = sum(sincs_2_1);
    %% Mid symbols
    y(289:432) = zeros(1,144);
    %% Second pbch symbol (last 48 SCs)
    f=linspace(0,47,48);
    for i = 1:12
        sincs_2_2(i,:) = EstimatedValues(i+72)  * sinc((f-B*(i-1))*nTaps/B); 
    end
    y(433:480) = sum(sincs_2_2);
    %% Third pbch symbol
    f=linspace(0,239,240);
    for i = 1:60
        sincs_3(i,:) = EstimatedValues(i+84)  * sinc((f-B*(i-1))*nTaps/B); 
    end
    
    y(481:720) = sum(sincs_3);

end