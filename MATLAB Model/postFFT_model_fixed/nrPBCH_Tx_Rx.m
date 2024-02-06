clc;
clear;
close all;
%tic
 %% SS/PBCH Generation
 ssblock = zeros([240 4]);
 ssbIndex=1;
 issb=mod(ssbIndex,8);
 ncellid=0;
 n_hf=0;
 fc=2.5; %GHz
 mu=0;
 
%% Transmitter

for Trials=1:10 %% Don't Put Trials = 1, at least Trials=1:2
Trials
tic
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
 SNR = [-16:16];
 Eb = 0.5;
 Es = 1;
 
 for k=1:length(SNR) 
  
     img=1j;
     No(k)= Eb/(10^(SNR(k)/10));
     noise = randn(1,length(txFRAME)) * sqrt(No(k)/2)+ randn(1,length(txFRAME)) * sqrt(No(k)/2) *img ;
    
    
     rxFRAME=txFRAME+noise; %AWGN
     rxFRAME=rxFRAME/sqrt(mean(abs(rxFRAME).^2))*10^(-12/20);
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
    SSB_received_FP = SSB_fft_FP(:,ssbSymbolIndices);

     %% Padding Removal
    SSB_removed_FP = SSB_received_FP(9:248,:);
    %% Fixed Point Loop
    global fp 
    fp = 7;
    ssblock_FP=fi([ssblock], 1, fp+1, fp);
     %% Extracting DMRS 
    dmrsSymbolsReceived_FP = SSB_removed_FP(dmrsIndices);
    dmrsSymbolsTransmitted_FP = ssblock_FP(dmrsIndices);
     %% Extracting SSS
    sssSymbolsReceived_FP = SSB_removed_FP(sssIndices);
    sssSymbolsTransmitted_FP = ssblock_FP(sssIndices);
    %% Channel Estimation LSE
    ChEstLSE_FP1(k,1:144) = dmrsSymbolsReceived_FP.data .*conj(dmrsSymbolsTransmitted_FP.data);
    ChSSSLSE_FP(k,:) = (sssSymbolsReceived_FP.data) .*conj(sssSymbolsTransmitted_FP.data);

    ChEstLSE_FP(k,1:144) = fi([ChEstLSE_FP1(k,1:144)], 1, fp+1, fp);
    ChSSSLSE_FP(k,:) = fi([ChSSSLSE_FP(k,:)], 1, fp+1, fp);
    
    %% Channel Estimation MMSE
    %Fixed
    ChEstMMSE1_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(1:60),256,SNR(k),1);
    ChEstMMSE2_1_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(61:72),256,SNR(k),1);
    ChEstMMSE2_2_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(73:84),256,SNR(k),1);
    ChEstMMSE2_FP(k,:)=[ChEstMMSE2_1_FP(k,1:48) zeros(1,144) ChEstMMSE2_2_FP(k,1:48)];
    ChEstMMSE3_FP(k,:) = MMSE_FP(ChEstLSE_FP.data(85:144),256,SNR(k),1);
    ChEstMMSE_FP(k,:) = [ChEstMMSE1_FP(k,1:240) ChEstMMSE2_FP(k,1:240) ChEstMMSE3_FP(k,1:240)];
    ChSSSMMSE_FP(k,:)=ChEstMMSE2_FP.data(k,57:183);
    

    %% Linear Interpolation (LSE)
    
    %%%%%%%%%%%%%%%%%%% FP%%%%%%%%%%%%%%%%%%%%%%%%%%
    ChLinearIntrp_LSE_FP(k,1:240)=LinearIntrp_FP(ChEstLSE_FP(k,1:60),ncellid);
    ChLinearIntrp_LSE_FP(k,241:288)=LinearIntrp_FP(ChEstLSE_FP(k,61:72),ncellid);
    ChLinearIntrp_LSE_FP(k,433:480)=LinearIntrp_FP(ChEstLSE_FP(k,73:84),ncellid);
    ChLinearIntrp_LSE_FP(k,481:720)=LinearIntrp_FP(ChEstLSE_FP(k,85:144),ncellid);
    
    ChLinearIntrp_LSE_FP(k,297:423) = ChSSSLSE_FP(k,:);
    ChLinearIntrp_LSE_FP(k,289:296) = ChSSSLSE_FP(k,1) * ones(1,8);
    ChLinearIntrp_LSE_FP(k,424:432) = ChSSSLSE_FP(k,127) * ones(1,9);
    
    %% Symbol Avg (LSE)
    ChLinearIntrp_LSE_FP(k,:)=SymbolsAvg_FP(ChLinearIntrp_LSE_FP(k,:));
    %% Symbol Avg (MMSE)
    ChEstMMSE_avg_FP(k,:)=SymbolsAvg_FP(ChEstMMSE_FP.data(k,:));

     %% Extracting PBCH / Resource Demapping
    pbchSymbolsReceived_FP = SSB_removed_FP(pbchIndices);
    
    %% Zero Force Equalizer
    %LSE Linear
    
    pbchSymbolsTransmitted_ZF_Linear_LSE_FP1=pbchSymbolsReceived_FP.data ./(ChLinearIntrp_LSE_FP.data(k,pbchIndices-240));
    pbchSymbolsTransmitted_ZF_Linear_LSE_FP=fi([pbchSymbolsTransmitted_ZF_Linear_LSE_FP1], 1, fp+1, fp);
    
    %MMSE
    
    pbchSymbolsTransmitted_ZF_MMSE_FP1=pbchSymbolsReceived_FP.data ./(ChEstMMSE_avg_FP.data(k,pbchIndices-240));
    pbchSymbolsTransmitted_ZF_MMSE_FP=fi([pbchSymbolsTransmitted_ZF_MMSE_FP1], 1, fp+1, fp);
    

    %% Hard De-Mapping
    %%Linear LSE
    pbchSymbolsDemapped_Linear_LSE_FP=nr_QPSK_Demapping(pbchSymbolsTransmitted_ZF_Linear_LSE_FP);
    %MMSE
    pbchSymbolsDemapped_MMSE_FP=nr_QPSK_Demapping(pbchSymbolsTransmitted_ZF_MMSE_FP);
    
    %% LLR Values
    No_FP(k)=fi([No(k)], 1, fp+1, fp);
    LLR_MMSE_FP(k,:)=LLR_QPSK_FP(pbchSymbolsTransmitted_ZF_MMSE_FP.data,No_FP(k));
    Descrambled_LLR_MMSE_FP1=nr_L2Scrambler(LLR_MMSE_FP.data(k,:),issb,ncellid,'llr');
    Descrambled_LLR_MMSE_FP = fi(Descrambled_LLR_MMSE_FP1,1, fp+1, fp);
    Deinterleaved_LLR_MMSE_FP=nr_CodedBitsDeInterleaver(Descrambled_LLR_MMSE_FP);
    De_RateMatched_LLR_MMSE_FP = Deinterleaved_LLR_MMSE_FP(1:512);
    
    %%%%%%%%output for the decoder%%%%%%%%%%%%%%%%%%%%%%%%
    PolarEncoderRec_LLR_MMSE_FP = nr_SubBlockDeInterleaver(De_RateMatched_LLR_MMSE_FP);
    
    %% De-Scrambling
    %Linear LSE
    Descrambled_Linear_LSE_FP=nr_L2Scrambler(pbchSymbolsDemapped_Linear_LSE_FP,issb,ncellid,'binary');
    %MMSE
    Descrambled_MMSE_FP=nr_L2Scrambler(pbchSymbolsDemapped_MMSE_FP,issb,ncellid,'binary');
   
    %% DeInterleaver
    Deinterleaved_Linear_LSE_FP=nr_CodedBitsDeInterleaver(Descrambled_Linear_LSE_FP);
    
    Deinterleaved_MMSE_FP=nr_CodedBitsDeInterleaver(Descrambled_MMSE_FP);
 

    %% De-Rate Matching
    De_RateMatched_Linear_LSE_FP = Deinterleaved_Linear_LSE_FP(1:512);
    
    De_RateMatched_MMSE_FP = Deinterleaved_MMSE_FP(1:512);
   
    %% De-SubBlock Interleaver
    PolarEncoderRec_Linear_LSE_FP = nr_SubBlockDeInterleaver(De_RateMatched_Linear_LSE_FP);
  
    PolarEncoderRec_MMSE_FP = nr_SubBlockDeInterleaver(De_RateMatched_MMSE_FP);
    
    
 %% BER Calculations

     Error_Linear_LSE_FP(Trials,k)= ErrorsNum(PolarEncoderRec_Linear_LSE_FP,PolarEncoder);

     Error_MMSE_FP(Trials,k)= ErrorsNum(PolarEncoderRec_MMSE_FP,PolarEncoder);
     
     BER_Ideal(k) = 0.5*erfc(sqrt(Eb/No(k)));
     

 end
toc
end

    BER_Linear_LSE_FP=sum(Error_Linear_LSE_FP)/(Trials*length(PolarEncoder));

    BER_MMSE_FP=sum(Error_MMSE_FP)/(Trials*length(PolarEncoder));

 %% Plots
%BER Plot
figure; 
semilogy(SNR,BER_Linear_LSE_FP,'-or'); hold on; grid on;
semilogy(SNR,BER_MMSE_FP,'-og');hold on; grid on;
semilogy(SNR,BER_Ideal,'-*k');
ylim([1e-4 0.5]);
hold off;

legend('LSE FP','MMSE FP','Theo');
title('BER vs SNR (AWGN)'); xlabel('SNR(dB)'); ylabel('BER');
