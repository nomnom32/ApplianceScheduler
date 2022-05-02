function price_rate = tou_rates24(t)
%Jan-Jun(Dry)/Monday to Saturday Rate: P(8am-9pm)7.48 kW/h OP(9pm-8am)3.55
%Jul-Dec(Wet)/Monday to Saturday Rate: P(8am-9pm)7.28 OP(9pm-8am)3.55
%Jan-Jun(Dry)/Sunday Rate: P(6pm-8pm)7.48 OP(8pm-6pm)3.55
%Jul-Dec(Wet)/Sunday Rate: P(6pm-8pm)7.28 OP(8pm-6pm)3.55
% ? / kWhr * 1kW/1000W * %%%%%%%%1hr/60 min * 15 min
%t=24;
P1=0.00748;
P2=0.00728;
OP=0.00355;
price_rate=zeros(4,t);
for a=1:4 %1=M-S(dry),2=M-S(wet),3=Sun(dry),4=Sun(wet)
    for b=1:t
        if ((a==1)&&(b>=5)&&(b<=17))||((a==3)&&(b>=15)&&(b<=16))
            price_rate(a,b)=P1;
        elseif ((a==2)&&(b>=5)&&(b<=17))||((a==4)&&(b>=15)&&(b<=16))
            price_rate(a,b)=P2;
        else
            price_rate(a,b)=OP;
        end
    end
end
end
