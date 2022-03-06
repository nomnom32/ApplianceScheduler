clear;
%App# TW D FR TO PR
input = [ 1  83.50 24  4  4  4;
          2  70.00  1  5  7  7;
          3  38.66  2 14 20  8;
          4 115.98  3  9 15  2;
          4 115.98  2 21 23  2;
          4 115.98  3  1  5  2;
          6 207.25  1 24  4  9;
          6 207.25  1  4  6
          7  70.11 24 24 24  1;
          8 361.14  3  6 24  5;
          9 141.40  2  6 24  6;
         10 150.00  2  7  9  3;
         10 150.00  4 10 14  3;
         10 150.00  3  1  4  3 ];

N = input(:,3);
TA = input(:,4);
TB = input(:,5);
PR = input(:,6);

Satisfaction = zeros(height(TA),24);
for j=1:height(TA)
    for i=1:24
        tfinish = i;
        if (tfinish>=TA(j,1)+(N(j,1)-1)) && (tfinish<TB(j,1))
            x = (1/PR(j,1))*(tfinish-(TB(j,1)+1))/(TA(j,1)+(N(j,1)-1)-(TB(j,1)+1));
        elseif (tfinish<(TA(j,1)+N(j,1))) || (tfinish>=TB(j,1))
            x = 0;
        end
    Satisfaction(j,i) = x;
    end
end
Satisfaction
