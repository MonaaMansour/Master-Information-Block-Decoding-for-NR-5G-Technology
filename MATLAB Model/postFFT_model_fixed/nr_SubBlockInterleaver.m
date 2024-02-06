function y = nr_SubBlockInterleaver(d)
    N=512; %Number of input bits
    P=[0 1 2 4 3 5 6 7 8 16 9 17 10 18 11 19 12 20 13 21 14 22 15 23 24 25 26 28 27 29 30 31];
    for n=0:N-1
        i=floor(32*n/N);
        J(n+1)=P(i+1)*(N/32)+mod(n,N/32);
        y(n+1)=d(J(n+1)+1);
    end
end