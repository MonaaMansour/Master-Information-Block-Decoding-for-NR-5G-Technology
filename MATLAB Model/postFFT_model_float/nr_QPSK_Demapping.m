function y= nr_QPSK_Demapping (x)
    for i=1:length(x)
     if(real(x(i))>=0 & imag(x(i))>0)  
          y(2*i-1)=0; y(2*i)=0;
     elseif (real(x(i))>0 & imag(x(i))<=0)
          y(2*i-1)=0; y(2*i)=1;
     elseif (real(x(i))<0 & imag(x(i))>=0)
          y(2*i-1)=1; y(2*i)=0;
     elseif (real(x(i))<=0 & imag(x(i))<0)
          y(2*i-1)=1; y(2*i)=1;
     else y(2*i-1)=1; y(2*i)=1;        
     end
    end
end