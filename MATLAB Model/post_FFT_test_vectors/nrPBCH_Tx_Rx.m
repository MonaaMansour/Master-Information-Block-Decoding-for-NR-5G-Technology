clc;
clear;
close all;
%tic
inputs           = fopen('TOP_INPUTS.txt','w');
fileChEstLSE     = fopen('TOP_LSE.txt','w'); 
fileChEstMMSE    = fopen('TOP_MMSE.txt','w');
fileSymbolsAvg   = fopen('TOP_AVG.txt','w');
fileZeroForceEq  = fopen('TOP_EQ.txt','w');
fileL2Scrambler  = fopen('TOP_SCRMBL.txt','w');
fileRateMatching = fopen('TOP_RATEMATCH.txt','w');
filefftram       = fopen('FFT_RAM.txt','w');


%% Transmitter

for Trials=1:10000 %% Don't Put Trials = 1, at least Trials=1:2
Trials
tic
%% SS/PBCH Generation
 ssblock = zeros([240 4]);
 ssbIndex= randi([0, 3], 1,1);
 issb=mod(ssbIndex,8);
 ncellid= randi([0, 1007], 1,1);
 n_hf= randi([0, 1], 1,1);
 fc=2.5; %GHz
 mu=0;
 
 fprintf(inputs,['%d \n'],ncellid);
 fprintf(inputs,['%d \n'],issb);
 fprintf(inputs,['%d \n'],n_hf);
 
 %% Input Stream
 PolarEncoder = randi([0 1],1,512);
 %% Rate Matching
 SBI=nr_SubBlockInterleaver(PolarEncoder);
 BitSel=nr_BitSelection(SBI);
 RateMatched=nr_CodedBitsInterleaver(BitSel);
 
 %% Scrambler
 Scrambled=nr_L2Scrambler(RateMatched,issb,ncellid,'binary');
 %% QPSK Mapper
 pbchSymbols=nr_QPSK(Scrambled);
 %% PSS Generation
 
 pssSymbols = nr_PSS(ncellid);
% pssIndices = nrPSSIndices;
 pssIndices1 = nr_PSSIndices;
 ssblock(pssIndices1) = pssSymbols;
 
 %% SSS Generation
 
 sssSymbols = nrSSS(ncellid);
 sssIndices = nr_SSSIndices;
 ssblock(sssIndices) =  sssSymbols;
 
 
 %% PBCH Generation
 pbchIndices = nr_PBCHIndices(ncellid);
 ssblock(pbchIndices) =  pbchSymbols;
 
 %% DMRS Generation
 
 dmrsSymbols = nr_DMRS(issb,ncellid,n_hf);
 dmrsIndices = nr_DMRSIndices(ncellid);
 ssblock(dmrsIndices) =  dmrsSymbols;
 
 
 %% Lmax Calculations
if (fc<=3)  
    Lmax=4;
elseif (fc>3 && fc<=6)
    Lmax=8;
else
    Lmax=64;
end

%% First Symbol Index
if(mu==0 || mu==2) %case A or C
    if (Lmax==4) 
        n = [0 1];
    elseif (Lmax==8)
        n = [0 1 2 3];
    end
    firstSymbolIndex = [2; 8;] + 14*n;
    
elseif(mu==1) %case B
    if (Lmax==4) 
        n = [0];
    elseif (Lmax==8)
        n = [0 1];
    end
    firstSymbolIndex = [4; 8; 16; 20;] + 28*n;
    
elseif(mu==3) %case D
    if (Lmax==64) 
        n = [0 1 2 3 5 6 7 8 10 11 12 13 15 16 17 18];
    end
    firstSymbolIndex = [4; 8; 16; 20;] + 28*n;
    
elseif(mu==4) %case E
    if (Lmax==64) 
        n = [0:8];
    end
    firstSymbolIndex = [8; 12; 16; 20; 32; 36; 40; 44;] + 56*n;
end
firstSymbolIndex = firstSymbolIndex+1;
firstSymbolIndex = firstSymbolIndex(:).';


%% Location of our Single SSB
 pssSymbolIndex = firstSymbolIndex(ssbIndex+1);
 
 ssbSymbolIndices(1:4) = [pssSymbolIndex : pssSymbolIndex+3];
 
  %% Frame Generation
 SymbolsPerSubframe = 14*2^mu;
 SymbolsNumber = 14*2^mu *10 ;
 frame_temp=randi([0,1],2*240,SymbolsNumber);
 for w= 1:140
 frame(:,w) = nr_QPSK(frame_temp(:,w));
 end
 while( ssbSymbolIndices(4) > length(frame) )
     frame = [frame zeros(240,14*2^mu *10)];
     SymbolsNumber = SymbolsNumber + 14*2^mu *10;
 end
     
 NumberOfFrames = SymbolsNumber/(14*2^mu *10);
 frame(:,ssbSymbolIndices)=ssblock;
 
 
 %% Zero Padding
frame_padded=[zeros(8,SymbolsNumber); frame; zeros(8,SymbolsNumber);];

 %% 256-Point IFFT
frame_ifft= sqrt(256)*ifft(frame_padded,[],1); %ifft column by column


 %% Cyclic Prefix Length

for i=1:SymbolsNumber
    if ( mod( i-1 , 7*2^mu )==0)
        CPlen(i) = 20;
    else
        CPlen(i) = 18;
    end
end

 %% Adding Cyclic Prefix & P/S Conversion
 txFRAME=0;
 clear txFRAME
 prefix = frame_ifft((256-CPlen(1)+1):256,1);
 txFRAME(1:276) = [prefix;  frame_ifft(:,1)];

 
 for i=2:length(CPlen)
     
     prefix = frame_ifft((256-CPlen(i)+1):256,i);
     SymbolCP = [prefix; frame_ifft(:,i)]; 
     txFRAME(length(txFRAME)  +  (1:(256+CPlen(i)))  ) = SymbolCP;
     
 end
 
 
 %% Fading + AWGN Channel
 SNR = [6];
 Eb = 0.5;
 Es = 1;
 
 for k=1:length(SNR) 
  
     img=1j;
     No(k)= Eb/(10^(SNR(k)/10));
     noise = randn(1,length(txFRAME)) * sqrt(No(k)/2)+ randn(1,length(txFRAME)) * sqrt(No(k)/2) *img ;
    
    
     rxFRAME=txFRAME+noise; %AWGN
     rxFRAME=rxFRAME./sqrt(mean(abs(rxFRAME).^2))*10^(-12/20);
%      Power=(norm(rxFRAME((256+20)*+1:(256+20)*9+256+18)))^2/(256+18);
%      Power_db=pow2db(Power);
%      
     %% Perfect Time&Frequency Synchronization   
      %OFDM Symbols indices of the SSB & fc & mu & ncellid are known%
     
     %% CP Removal
    CPold=0;
    for i = 1 : length(CPlen)
        FRAME_CP_removed (256*(i-1) + (1:256)) = rxFRAME( (256*(i-1)+CPold) + CPlen(i) + (1:256) );
        CPold=CPold+CPlen(i);
    end
 
       %% S/P Conversion
    j=0;
    for i = 1 : 256 : length(FRAME_CP_removed)-255
        j=j+1;
        FRAME_P(1:256,j) = FRAME_CP_removed(i:i+255);
    end
    

     %% 256-Point FFT
    SSB_fft=(1/sqrt(256))*fft(FRAME_P,[],1); 
    SSB_fft_FP=fi([SSB_fft], 1, 12, 11);
     
     %% SSB Extraction
    SSB_received = SSB_fft(:,ssbSymbolIndices);
    SSB_received_FP = SSB_fft_FP(:,ssbSymbolIndices);

     %% Padding Removal
    SSB_removed = SSB_received(9:248,:);
    SSB_removed_FP = SSB_received_FP(9:248,:);
       fmt=['%s \n'];

    %% Fixed Point Loop
    global fp 
    fp = 7;
    ssblock_FP=fi([ssblock], 1, fp+1, fp);
     %% Extracting DMRS
    dmrsSymbolsReceived = SSB_removed(dmrsIndices);
    dmrsSymbolsTransmitted = ssblock(dmrsIndices);
     
    dmrsSymbolsReceived_FP = SSB_removed_FP(dmrsIndices);
    dmrsSymbolsTransmitted_FP = ssblock_FP(dmrsIndices);
     %% Extracting SSS
    sssSymbolsReceived = SSB_removed(sssIndices);
    sssSymbolsTransmitted = ssblock(sssIndices);
   
    sssSymbolsReceived_FP = SSB_removed_FP(sssIndices);
    sssSymbolsTransmitted_FP = ssblock_FP(sssIndices);
    %% Channel Estimation LSE
    ChEstLSE(k,1:144) = (dmrsSymbolsReceived).*conj(dmrsSymbolsTransmitted);
    %ChSSSLSE(k,:) = (sssSymbolsReceived) .*conj(sssSymbolsTransmitted);
    
    ChEstLSE_FP1(k,1:144) = dmrsSymbolsReceived_FP.data .*conj(dmrsSymbolsTransmitted_FP.data);
    %ChSSSLSE_FP(k,:) = (sssSymbolsReceived_FP.data) .*conj(sssSymbolsTransmitted_FP.data);

    
    ChEstLSE_FP(k,1:144) = fi([ChEstLSE_FP1(k,1:144)], 1, fp+1, fp);
    %ChSSSLSE_FP(k,:) = fi([ChSSSLSE_FP(k,:)], 1, fp+1, fp);
    
%     %-----------writing test vectors-----%
    fft_3 = SSB_received_FP(1:256,2:4);
    fft_reshaped= reshape(fft_3, 256*3,1);
    fft_FP_real = real(fft_reshaped);
    fft_FP_imag = imag(fft_reshaped);
    
    for i= 1:256*3
        fprintf(filefftram,'%s',fft_FP_real.bin(i,:));
        fprintf(filefftram,fmt,fft_FP_imag.bin(i,:));    
    end
    dmrsSymbolsTransmitted_FP_real =real(dmrsSymbolsTransmitted_FP.');
    dmrsSymbolsTransmitted_FP_imag = imag(dmrsSymbolsTransmitted_FP.');
    ChEstLSE_FP_real = real(ChEstLSE_FP.');
    ChEstLSE_FP_imag = imag(ChEstLSE_FP.');
    %fprintf(fileChEstLSE,'*******Symbol_1*******\n');
    for i=1:60
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_imag.bin(i,:));    
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_real.bin(i,:));
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_imag.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_imag.bin(i,:));
    end
    %fprintf(fileChEstLSE,'\n\n*******Symbol_2*******\n');
    for i=61:72
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_imag.bin(i,:));    
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_real.bin(i,:));
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_imag.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_imag.bin(i,:));
    end
    %fprintf(fileChEstLSE,'\n\n*******Symbol_3*******\n');
    for i=73:84
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_imag.bin(i,:));    
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_real.bin(i,:));
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_imag.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_imag.bin(i,:));
    end
    %fprintf(fileChEstLSE,'\n\n*******Symbol_4*******\n');
    for i=85:144
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,dmrsSymbolsTransmitted_FP_imag.bin(i,:));    
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_real.bin(i,:));
    %fprintf(fileChEstLSE,fmt,dmrsSymbolsReceived_FP_imag.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_real.bin(i,:));
    fprintf(fileChEstLSE,fmt,ChEstLSE_FP_imag.bin(i,:));
    end
    
    %% Channel Estimation MMSE
    %Floating
    ChEstMMSE1(k,:) = MMSE(ChEstLSE(1:60),256,SNR(k),1);
    ChEstMMSE2_1(k,:) = MMSE(ChEstLSE(61:72),256,SNR(k),1);
    ChEstMMSE2_2(k,:) = MMSE(ChEstLSE(73:84),256,SNR(k),1);
    ChEstMMSE2(k,:)=[ChEstMMSE2_1(k,1:48) zeros(1,144) ChEstMMSE2_2(k,1:48)];
    ChEstMMSE3(k,:) = MMSE(ChEstLSE(85:144),256,SNR(k),1);
    ChEstMMSE(k,:) = [ChEstMMSE1(k,1:240) ChEstMMSE2(k,1:240) ChEstMMSE3(k,1:240)];
    %ChSSSMMSE(k,:)=ChEstMMSE2(k,57:183);
    %Fixed
    ChEstMMSE1_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(1:60),256,SNR(k),1);
    ChEstMMSE2_1_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(61:72),256,SNR(k),1);
    ChEstMMSE2_2_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(73:84),256,SNR(k),1);
    ChEstMMSE2_FP(k,:)=[ChEstMMSE2_1_FP(k,1:48) zeros(1,144) ChEstMMSE2_2_FP(k,1:48)];
    ChEstMMSE3_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(85:144),256,SNR(k),1);
    ChEstMMSE_FP(k,:) = [ChEstMMSE1_FP(k,1:240) ChEstMMSE2_FP(k,1:240) ChEstMMSE3_FP(k,1:240)];
    %ChSSSMMSE_FP(k,:)=ChEstMMSE2_FP.data(k,57:183);
    
%     %---------------------test vectors------------%
    ChEstMMSE1_FP_real=real(ChEstMMSE1_FP.');
    ChEstMMSE1_FP_imag=imag(ChEstMMSE1_FP.');
    ChEstMMSE2_1_FP_real=real(ChEstMMSE2_1_FP.');
    ChEstMMSE2_1_FP_imag=imag(ChEstMMSE2_1_FP.');
    ChEstMMSE2_2_FP_real=real(ChEstMMSE2_2_FP.');
    ChEstMMSE2_2_FP_imag=imag(ChEstMMSE2_2_FP.');
    ChEstMMSE3_FP_real=real(ChEstMMSE3_FP.');
    ChEstMMSE3_FP_imag=imag(ChEstMMSE3_FP.');
     
    for i=1:240
    fprintf(fileChEstMMSE,fmt,ChEstMMSE1_FP_real.bin(i,:));
    fprintf(fileChEstMMSE,fmt,ChEstMMSE1_FP_imag.bin(i,:));
    end
    %fprintf(fileChEstMMSE,'\n\nChEstMMSE SecondSymbol*******\n');
    for i=1:48
    fprintf(fileChEstMMSE,fmt,ChEstMMSE2_1_FP_real.bin(i,:));
    fprintf(fileChEstMMSE,fmt,ChEstMMSE2_1_FP_imag.bin(i,:));
    end
    %fprintf(fileChEstMMSE,'\n\nChEstMMSE ThirdSymbol*******\n');
    for i=1:48
    fprintf(fileChEstMMSE,fmt,ChEstMMSE2_2_FP_real.bin(i,:));
    fprintf(fileChEstMMSE,fmt,ChEstMMSE2_2_FP_imag.bin(i,:));
    end
    %fprintf(fileChEstMMSE,'\n\nChEstMMSE ForthSymbol*******\n');
    for i=1:240
    fprintf(fileChEstMMSE,fmt,ChEstMMSE3_FP_real.bin(i,:));
    fprintf(fileChEstMMSE,fmt,ChEstMMSE3_FP_imag.bin(i,:));
    end
    
    %% Linear Interpolation (LSE)
    ChLinearIntrp_LSE(k,1:240)=LinearIntrp(ChEstLSE(k,1:60),ncellid);
    ChLinearIntrp_LSE(k,241:288)=LinearIntrp(ChEstLSE(k,61:72),ncellid);
    ChLinearIntrp_LSE(k,433:480)=LinearIntrp(ChEstLSE(k,73:84),ncellid);
    ChLinearIntrp_LSE(k,481:720)=LinearIntrp(ChEstLSE(k,85:144),ncellid);
    
%    ChLinearIntrp_LSE(k,297:423) = ChSSSLSE(k,:);
%    ChLinearIntrp_LSE(k,289:296) = ChSSSLSE(k,1) * ones(1,8);
 %   ChLinearIntrp_LSE(k,424:432) = ChSSSLSE(k,127) * ones(1,9);
    
    ChLinearIntrp_LSE(k,:)=SymbolsAvg(ChLinearIntrp_LSE(k,:));
    
    %%%%%%%%%%%%%%%%%%% FP%%%%%%%%%%%%%%%%%%%%%%%%%%
    ChLinearIntrp_LSE_FP(k,1:240)=LinearIntrp_FP(ChEstLSE_FP(k,1:60),ncellid);
    ChLinearIntrp_LSE_FP(k,241:288)=LinearIntrp_FP(ChEstLSE_FP(k,61:72),ncellid);
    ChLinearIntrp_LSE_FP(k,433:480)=LinearIntrp_FP(ChEstLSE_FP(k,73:84),ncellid);
    ChLinearIntrp_LSE_FP(k,481:720)=LinearIntrp_FP(ChEstLSE_FP(k,85:144),ncellid);
    
    %ChLinearIntrp_LSE_FP(k,297:423) = ChSSSLSE_FP(k,:);
    %ChLinearIntrp_LSE_FP(k,289:296) = ChSSSLSE_FP(k,1) * ones(1,8);
    %ChLinearIntrp_LSE_FP(k,424:432) = ChSSSLSE_FP(k,127) * ones(1,9);
    
    %% Symbol Avg (LSE)
    ChLinearIntrp_LSE_FP(k,:)=SymbolsAvg_FP(ChLinearIntrp_LSE_FP(k,:));
    %% Symbol Avg (MMSE)
    ChEstMMSE_avg(k,:)=SymbolsAvg(ChEstMMSE(k,:));
    ChEstMMSE_avg_FP(k,:)=SymbolsAvg_FP(ChEstMMSE_FP.data(k,:));
    ChEstMMSE_avg_FP_real=real(ChEstMMSE_avg_FP.');
    ChEstMMSE_avg_FP_imag=imag(ChEstMMSE_avg_FP.');
    for i= 1:240
    fprintf(fileSymbolsAvg,fmt,ChEstMMSE_avg_FP_real.bin(i,:));
    fprintf(fileSymbolsAvg,fmt,ChEstMMSE_avg_FP_imag.bin(i,:));
    end
    
    %% Sinc Interpolation LSE
%    ChSincIntrp_LSE(k,1:720)=SincIntrp(ChEstLSE(k,:));
%    ChSincIntrp_LSE2(k,1:240) = interp1(dmrsIndices(1:60)-240,ChEstLSE(k,1:60),4,'linear');
%     ChSincIntrp_LSE(k,297:423)=ChSSSLSE(k,:);
%     ChSincIntrp_LSE(k,289:296) = ChSSSLSE(k,1) * ones(1,8);
%     ChSincIntrp_LSE(k,424:432) = ChSSSLSE(k,127) * ones(1,9);
%    ChSincIntrp_LSE(k,:)=SymbolsAvg(ChSincIntrp_LSE(k,:));
    
     %% Extracting PBCH / Resource Demapping
    
    pbchSymbolsReceived = SSB_removed(pbchIndices);
    pbchSymbolsReceived_FP = SSB_removed_FP(pbchIndices);
    
    %% Zero Force Equalizer
    %LSE Linear
    pbchSymbolsTransmitted_ZF_Linear_LSE= pbchSymbolsReceived .*conj(ChLinearIntrp_LSE(k,pbchIndices-240));

    pbchSymbolsTransmitted_ZF_Linear_LSE_FP1=pbchSymbolsReceived_FP.data .*conj(ChLinearIntrp_LSE_FP.data(k,pbchIndices-240));
    pbchSymbolsTransmitted_ZF_Linear_LSE_FP=fi([pbchSymbolsTransmitted_ZF_Linear_LSE_FP1], 1, fp+1, fp);
    
    
    %LSE Sinc
 %   pbchSymbolsTransmitted_ZF_Sinc_LSE= pbchSymbolsReceived ./ ChSincIntrp_LSE(k,pbchIndices-240);
    
    %MMSE
    pbchSymbolsTransmitted_ZF_MMSE= pbchSymbolsReceived .*conj(ChEstMMSE_avg(k,pbchIndices-240));
    
    pbchSymbolsTransmitted_ZF_MMSE_FP1=pbchSymbolsReceived_FP.data .* conj(ChEstMMSE_avg_FP.data(k,pbchIndices-240));
    pbchSymbolsTransmitted_ZF_MMSE_FP=fi([pbchSymbolsTransmitted_ZF_MMSE_FP1], 1, fp+1, fp);
    
    %-------test vectors-------------------%
    pbchSymbolsTransmitted_ZF_MMSE_FP_real=real(pbchSymbolsTransmitted_ZF_MMSE_FP.');
    pbchSymbolsTransmitted_ZF_MMSE_FP_imag=imag(pbchSymbolsTransmitted_ZF_MMSE_FP.');
    for i=1:432
     fprintf(fileZeroForceEq,fmt,pbchSymbolsTransmitted_ZF_MMSE_FP_real.bin(i,:) );
     fprintf(fileZeroForceEq,fmt,pbchSymbolsTransmitted_ZF_MMSE_FP_imag.bin(i,:) );
    end

    %% LLR MMSE 
    LLR_MMSE(k,:)=LLR_QPSK(pbchSymbolsTransmitted_ZF_MMSE,No(k));
    No_FP(k)=fi([No(k)], 1, fp+1, fp);
    LLR_MMSE_FP(k,:)=LLR_QPSK_FP(pbchSymbolsTransmitted_ZF_MMSE_FP.data,No_FP(k));
    %% De-Scrambling LLR
    %LLR MMSE DEScrambler
    Descrambled_LLR_MMSE=nr_L2Scrambler(LLR_MMSE(k,:),issb,ncellid,'llr');
    Descrambled_LLR_MMSE_FP1=nr_L2Scrambler(LLR_MMSE_FP.data(k,:),issb,ncellid,'llr');
    Descrambled_LLR_MMSE_FP = fi(Descrambled_LLR_MMSE_FP1,1, fp+1, fp);
    %------------test vectors----------------%
    Descrambled_LLR_MMSE_FP_transpose =Descrambled_LLR_MMSE_FP.';
    for i= 1:864
    fprintf(fileL2Scrambler,fmt,Descrambled_LLR_MMSE_FP_transpose.bin(i,:));
    end
    
    %% DeRateMAtching LLR
   
    Deinterleaved_LLR_MMSE=nr_CodedBitsDeInterleaver(Descrambled_LLR_MMSE);
    Deinterleaved_LLR_MMSE_FP=nr_CodedBitsDeInterleaver(Descrambled_LLR_MMSE_FP);
    
    De_RateMatched_LLR_MMSE = Deinterleaved_LLR_MMSE(1:512);
    De_RateMatched_LLR_MMSE_FP = Deinterleaved_LLR_MMSE_FP(1:512);
    
    PolarEncoderRec_LLR_MMSE = nr_SubBlockDeInterleaver(De_RateMatched_LLR_MMSE);
    PolarEncoderRec_LLR_MMSE_FP = nr_SubBlockDeInterleaver(De_RateMatched_LLR_MMSE_FP);
  
     %------------test vectors----------------%
    PolarEncoderRec_LLR_MMSE_FP_transpose =PolarEncoderRec_LLR_MMSE_FP.';
    for i= 1:512
    fprintf(fileRateMatching,fmt,PolarEncoderRec_LLR_MMSE_FP_transpose.bin(i,:));
    end

    
%     %% Hard De-Mapping
%     %%Linear LSE
%     pbchSymbolsDemapped_Linear_LSE=nr_QPSK_Demapping(pbchSymbolsTransmitted_ZF_Linear_LSE);
%     pbchSymbolsDemapped_Linear_LSE_FP=nr_QPSK_Demapping(pbchSymbolsTransmitted_ZF_Linear_LSE_FP);
%     %Sinc LSE
% %    pbchSymbolsDemapped_Sinc_LSE=nr_QPSK_Demapping(pbchSymbolsTransmitted_ZF_Sinc_LSE);
%     %MMSE
%     pbchSymbolsDemapped_MMSE=nr_QPSK_Demapping(pbchSymbolsTransmitted_ZF_MMSE);
%     pbchSymbolsDemapped_MMSE_FP=nr_QPSK_Demapping(pbchSymbolsTransmitted_ZF_MMSE_FP);
%     %% De-Scrambling
%     %Linear LSE
%     Descrambled_Linear_LSE=nr_L2Scrambler(pbchSymbolsDemapped_Linear_LSE,issb,ncellid,'binary');
%     Descrambled_Linear_LSE_FP=nr_L2Scrambler(pbchSymbolsDemapped_Linear_LSE_FP,issb,ncellid,'binary');
%     %Sinc LSE
%  %   Descrambled_Sinc_LSE=nr_L2Scrambler(pbchSymbolsDemapped_Sinc_LSE,issb,ncellid,'binary');
%     %MMSE
%     Descrambled_MMSE=nr_L2Scrambler(pbchSymbolsDemapped_MMSE,issb,ncellid,'binary');
%     Descrambled_MMSE_FP=nr_L2Scrambler(pbchSymbolsDemapped_MMSE_FP,issb,ncellid,'binary');
%     
%          %% LLR Values
%     LLR_Linear_LSE(k,:)=LLR_QPSK(pbchSymbolsTransmitted_ZF_Linear_LSE,No(k));
%     No_FP(k)=fi([No(k)], 1, fp+1, fp);
%     LLR_Linear_LSE_FP(k,:)=LLR_QPSK_FP(pbchSymbolsTransmitted_ZF_Linear_LSE_FP,No_FP(k));
%    
%     %% DeInterleaver
%     Deinterleaved_Linear_LSE=nr_CodedBitsDeInterleaver(Descrambled_Linear_LSE);
%     Deinterleaved_Linear_LSE_FP=nr_CodedBitsDeInterleaver(Descrambled_Linear_LSE_FP);
%     
%   %  Deinterleaved_Sinc_LSE=nr_CodedBitsDeInterleaver(Descrambled_Sinc_LSE);
%     
%     Deinterleaved_MMSE=nr_CodedBitsDeInterleaver(Descrambled_MMSE);
%     Deinterleaved_MMSE_FP=nr_CodedBitsDeInterleaver(Descrambled_MMSE_FP);
%  
% 
%     %% De-Rate Matching
%     De_RateMatched_Linear_LSE = Deinterleaved_Linear_LSE(1:512);
%     De_RateMatched_Linear_LSE_FP = Deinterleaved_Linear_LSE_FP(1:512);
%     
% %    De_RateMatched_Sinc_LSE = Deinterleaved_Sinc_LSE(1:512);
%     
%     De_RateMatched_MMSE = Deinterleaved_MMSE(1:512);
%     De_RateMatched_MMSE_FP = Deinterleaved_MMSE_FP(1:512);
%    
% 
%     %% De-SubBlock Interleaver
%     PolarEncoderRec_Linear_LSE = nr_SubBlockDeInterleaver(De_RateMatched_Linear_LSE);
%     PolarEncoderRec_Linear_LSE_FP = nr_SubBlockDeInterleaver(De_RateMatched_Linear_LSE_FP);
%     
% %    PolarEncoderRec_Sinc_LSE = nr_SubBlockDeInterleaver(De_RateMatched_Sinc_LSE);
%     
%     PolarEncoderRec_MMSE = nr_SubBlockDeInterleaver(De_RateMatched_MMSE);
%     PolarEncoderRec_MMSE_FP = nr_SubBlockDeInterleaver(De_RateMatched_MMSE_FP);
%     
%  %% BER Calculations
%    
%      Error_Linear_LSE(Trials,k)= ErrorsNum(PolarEncoderRec_Linear_LSE,PolarEncoder);
%      Error_Linear_LSE_FP(Trials,k)= ErrorsNum(PolarEncoderRec_Linear_LSE_FP,PolarEncoder);
% 
% %     Error_Sinc_LSE(Trials,k)= ErrorsNum(PolarEncoderRec_Sinc_LSE,PolarEncoder);
% 
%      Error_MMSE(Trials,k)= ErrorsNum(PolarEncoderRec_MMSE,PolarEncoder);
%      Error_MMSE_FP(Trials,k)= ErrorsNum(PolarEncoderRec_MMSE_FP,PolarEncoder);
%      BER_Ideal(k) = 0.5*erfc(sqrt(Eb/No(k)));
     
 end
toc
end


%     BER_Linear_LSE=sum(Error_Linear_LSE)/(Trials*length(PolarEncoder));
%     BER_Linear_LSE_FP=sum(Error_Linear_LSE_FP)/(Trials*length(PolarEncoder));
% %    BER_Sinc_LSE=sum(Error_Sinc_LSE)/(Trials*length(PolarEncoder));
%     BER_MMSE=sum(Error_MMSE)/(Trials*length(PolarEncoder));
%     BER_MMSE_FP=sum(Error_MMSE_FP)/(Trials*length(PolarEncoder));
% 
%  %% Plots
% %BER Plot
% figure; 
% semilogy(SNR,BER_Linear_LSE,'-or'); hold on; grid on;
% semilogy(SNR,BER_Linear_LSE_FP,'-xm');
% semilogy(SNR,BER_MMSE,'-og');hold on; grid on;
% semilogy(SNR,BER_MMSE_FP,'-xc');
% %semilogy(SNR,BER_Sinc_LSE,'-ob'); %hold on; grid on;
% semilogy(SNR,BER_Ideal,'-*k');
% ylim([1e-4 0.5]);
% hold off;
% 
% legend('LSE','LSE FP','MMSE','MMSE FP','Theo');
% title('BER vs SNR (AWGN)'); xlabel('SNR(dB)'); ylabel('BER');
% 

% figure;
% subcarriers=[1:720];
% plot(subcarriers,real(ChLinearIntrp_LSE(10,subcarriers)),'b');
% title('Linear vs Sinc interpolation at SNR=20 dB');
% xlabel('Subcarriers');
% ylabel('Channel Estimates');
% hold on;
% grid on;
% plot(subcarriers,real(ChSincIntrp_LSE(10,subcarriers)),'r');    
% legend('Linear Interpolation','Sinc Interpolation');
% hold off;



%FRAME Plot
% figure;   
% imagesc(abs(frame));
% caxis([0 4]);
% axis xy;
% xlabel('OFDM symbol');
% ylabel('Subcarrier');
% title('Frame after Generation');
fclose(fileChEstLSE);
fclose(fileChEstMMSE);
fclose(fileSymbolsAvg);
fclose(inputs);
fclose(fileZeroForceEq);
fclose(fileL2Scrambler);
fclose(fileRateMatching);
fclose(filefftram);
