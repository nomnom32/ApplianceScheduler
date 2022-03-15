clear;
%App# TW D FR TO PR
input = [ 1  83.50 24  1 24  4;
          2  70.00  1  5  7  7;
          3  38.66  2 14 20  8;
          4 115.98  3  9 15  2;
          4 115.98  2 21 23  2;
          4 115.98  3  1  5  2;
          6 207.25  1 24  4  9;
          6 207.25  1  4  6  9;
          7  70.11 24  1 24  1;
          8 361.14  3  6 24  5;
          9 141.40  2  6 24  6;
         10 150.00  2  7  9  3;
         10 150.00  4 10 14  3;
         10 150.00  3  1  4  3 ];

%dur = input(:,3);
%TA = input(:,4);
%TB = input(:,5);
%PR = input(:,6);

dur = 3;
TA = 20; 
TB = 5; 
PR = 3;
n = 10;

fprintf('PR=%d, n=%d\n', PR, n);
OperationTime = zeros(2,24);
for i=1:24
    OperationTime(1,i) = i;
    OperationTime(2,i) = i+(dur-1);
end
Satisfaction = zeros(1,24);
tfinish = OperationTime(2,:);
for a=1:24
    if (TA>TB)
        TB=TB+24;
    end
    if (TA>tfinish(a))
        tfinish(a)=tfinish(a)+24;
    end
    if (tfinish(a)>=TA+(dur-1)) && (tfinish(a)<=TB)
        %x = ((tfinish(a))*((n-PR)/(n-1))-(TB+1))/((TA+(dur-1))*((n-PR)/(n-1))-(TB+1)); %with priority
        %x = ((tfinish(a))-(TB+1))/((TA+(dur-1))-(TB+1)); %normal
    else
        x = 0;
    end
    if ((a+dur-1)<=24)
        Satisfaction(1,a+dur-1) = x;
    else 
        Satisfaction(1,a+dur-1-24) = x;
    end
end
Satisfaction
