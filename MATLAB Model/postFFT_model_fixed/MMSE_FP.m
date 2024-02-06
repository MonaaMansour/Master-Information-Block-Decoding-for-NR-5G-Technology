function [H_MMSE]=MMSE_FP(H_tilde,Nfft,SNR,nTaps)
global fp;
% MMSE channel estimation function
% Inputs:
% Y Frequency-domain received signal
% Xp Pilot signal
% pilot loc Pilot location
% Nfft FFT size
% Np Pilots number
% SNR [dB]
% H MMSE MMSE channel estimate
Np=length(H_tilde);
snr_FP = 10^(SNR*0.1);
N=Np*4; %Required output size
K1=repmat([0:N-1].',1,Np); K2=repmat([0:Np-1],N,1);
Kx=(K1-K2);
if (length(H_tilde)==60)
    K=Kx(:,1:60)-[0:3:177];
    
% elseif (length(H_tilde)==151)
%     K(:,1:12)=Kx(:,1:12)-[0:3:33];
%     K(:,13:139)=Kx(:,1:127)-56;
%     K(:,140:151)=Kx(:,140:151)-[53:3:86];
%     
else
    K(:,1:12)=(Kx(:,1:12)-[0:3:33]);
    
end

temp1=K*nTaps/Nfft;
rf= sinc(temp1); 

K3=repmat([0:Np-1].',1,Np); K4=repmat([0:Np-1],Np,1); KK=K3-K4;
temp2=KK*nTaps/64;
rf2= sinc(temp2); 

Rhp=rf;
Rpp=rf2 + (eye(length(H_tilde),length(H_tilde))/snr_FP); 
rhp_inv_rpp=fi([Rhp*inv(Rpp)], 1, fp+1, fp);
H_MMSE=transpose(rhp_inv_rpp.data*H_tilde.'); % MMSE estimate Eq.(6.15)
H_MMSE=fi([H_MMSE], 1, fp+1, fp);
