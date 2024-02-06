function y = nr_SubBlockDeInterleaver(d)
    N=512; %Number of input bits
    P=[0 1 2 4 3 5 6 7 8 10 12 14 16 18 20 22 9 11 13 15 17 19 21 23 24 25 26 28 27 29 30 31];
    for n=0:N-1
        i=floor(32*n/N);
        J(n+1)=P(i+1)*(N/32)+mod(n,N/32);
        y(n+1)=d(J(n+1)+1);
    end
end