function [H_MMSE]=MMSE(H_tilde,Nfft,SNR,nTaps)
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
snr =10^(SNR*0.1);
N=Np*4;
K1=repmat([0:N-1].',1,Np); K2=repmat([0:Np-1],N,1);
Kx=(K1-K2);
if (length(H_tilde)==60)
    K=Kx(:,1:60)-[0:3:177];

else
    K(:,1:12)=Kx(:,1:12)-[0:3:33];
    %K(:,13:24)=Kx(:,13:24)-[0:3:33]-180;
end
temp=K*nTaps /Nfft;
rf= sinc( (K*nTaps) /Nfft);
K3=repmat([0:Np-1].',1,Np); K4=repmat([0:Np-1],Np,1);
rf2= sinc((K3-K4)*nTaps/64);

Rhp=rf;
Rpp=rf2 + eye(length(H_tilde),length(H_tilde))/snr; % Eq.(6.14)
H_MMSE=transpose(Rhp*inv(Rpp)*H_tilde.'); % MMSE estimate Eq.(6.15)
%H_MMSE=(sum(H_MMSE)/length(H_MMSE))*ones(1,length(H_MMSE));