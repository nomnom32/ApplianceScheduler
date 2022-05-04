clc;
clear;
tic
format long g
%% IMPORT INPUT DATA

%These two lines must be constantly changed to check data from userinputx.m
userinput1
filename = "userinput1"; %change according to input

%Initialize Global Variables to save EV Operation and EC Consumption GRaphs
consumption_matrix = zeros(1,24);
EV_operation = zeros(1,24);
finalcost_orig_value = 0; 
finalcost_orig_and_ev_value = 0; 


for houses=1:700
    data = eval(sprintf('H%d',houses));

price_code=1;%1=M-S(dry),2=M-S(wet),3=Sun(dry),4=Sun(wet)
price = tou_rates24(24); %Time of Use Rates

%Parsing input data
[row_len,col_len]=size(data);
peak_threshold=data(1,4);
total_energy=data(1,5);
user_budget=data(1,6);  

% Counts the number of type of appliances
n=0;
LA = zeros(15,1);
for i=1:row_len 
    if (data(i,1)>0)&&(data(i,1)<98)&&(not(ismember(data(i,1),LA)))
        n=n+1;
        LA(n)=data(i,1);
    elseif(data(i,1)==98)
        batt_own=data(i,2);
        batt_int_ch=data(i,3);
    elseif(data(i,1)==99)
        ev_own=data(i,2);
        ev_int_ch=data(i,3);
    elseif(data(i,1)==100)
        solar_own=data(i,2);
    end
end

%% Battery Sizing
batt = 1020; %batt size for https://www.rollsbattery.com/battery/12-fs-24/ 20 Hour Rate, 
batt_size = batt;

batt_ctr = 1;
while(batt_size<total_energy)
    batt_ctr=batt_ctr+1;
    batt_size = batt*batt_ctr;
end

%% Solar Panel Operation %Assume constant for all households
PV = zeros(24,1);
for a=1:24
    if ((a>=7)&&(a<=11))
        PV(a,1) = 320;
    end
end

PV=PV*solar_own;
% counts number of usage per appliance
app_usage=zeros(n,1);
for a = 1:LA(n,1)
    temp = find(data(:,1)==a);
    pos = find(LA(:,1)==a);
    app_usage(pos) = size(temp,1); 
end

%Wattage Rating, Duration, Start Time, End Time, Rank 
mu=max(app_usage); 
app_TW=zeros(n,1); % Appliance Wattage Ratings
app_dur=zeros(n,mu); %Durations
app_tA=zeros(n,mu); %Start Time
app_tB=zeros(n,mu); %End Time 
app_R=zeros(n,1); % Appliance Rank


use=1;
for a=1:row_len
    if (data(a,1)>0)&&(data(a,1)<98)
        pos=find(LA(:,1)==data(a,1));
        app_TW(pos,1)=data(a,2);
        app_R(pos,1)=data(a,6);
        if use<=app_usage(pos)
            app_dur(pos,use)=data(a,3);
            app_tA(pos,use)=data(a,4);
            app_tB(pos,use)=data(a,5);
            if use==app_usage(pos)
                use=1;
            elseif use<app_usage(pos)
                use=use+1;
            end
        end
    end
end 
%% Original Schedule
orig_sched = zeros(n,24);

for i=1:n
    for j=1:mu
        if app_dur(i,j)==0
            orig_sched(i,j)=orig_sched(i,j);
        else 
            for k=0:app_dur(i,j)-1
                l=app_tA(i,j)+k;
                if l>24
                    l=l-24;
                end
                orig_sched(i,l)=1;
            end
        end
    end
end

%% With EV
orig_tempvar = orig_sched.*app_TW;
orig_appenergy = sum(orig_tempvar,1);
orig_batt_op = BatteryCode(orig_sched,app_TW, PV,batt_int_ch,ev_op,total_energy,batt_ctr); %battery charge rate
orig_batt_op_charging = orig_batt_op; %initialization of battery charge rate (walang discharge data)
ev_op = zeros(1,24);

orig_ev_op = zeros(1,24);
ev_needcharge = 3300*0.8-(ev_int_ch/100)*3300;
for i=15:24
    if ev_needcharge>1200
        orig_ev_op(i)=1200;
        ev_needcharge=ev_needcharge-1200;
    else
        orig_ev_op(i)=ev_needcharge;
        break
    end
end
    
orig_batt_op2 = BatteryCode(orig_sched,app_TW, PV,batt_int_ch,orig_ev_op,total_energy,batt_ctr); %battery charge rate

orig_total2 = orig_ev_op+orig_appenergy;
orig_batt_op_charging2 = orig_batt_op2; %initialization of battery charge rate (walang discharge data)

for k=1:24 % Find total consumption from utility
    if PV(k,1)>0
        orig_total2(1,k) = orig_total2(1,k)-PV(k,1);
    end
    if orig_batt_op2(1,k) < 0
        orig_total2(1,k) = orig_total2(1,k)+orig_batt_op2(1,k);
        orig_batt_op_charging(1,k)=0;
    end
    if orig_total2(1,k) <0
        orig_total2(1,k)=0;
    end    
end

orig_excess = transpose(PV)-orig_appenergy-orig_ev_op-orig_batt_op_charging; %computation of PV excess energy
for k=1:24
    if orig_excess(1,k)<0
        orig_excess(1,k)=0;
    end
end

final_cost = sum(transpose(orig_total2.*price(price_code,:)),1)-sum(transpose(orig_excess.*price(price_code,:))); %computation of final cost for conumer

fprintf('\nEV initial Charge = %d \n',ev_int_ch);



%Original Schedule + EV Operation
fprintf("Original Cost with EV = %d\n",final_cost);
fprintf("Original Peak with EV = %d\n",max(orig_total2));
fprintf("Original PAR with EV = %d\n\n",max(orig_total2)/(sum(orig_total2,2)/24));


x = linspace(1,24,24);
t = tiledlayout(5,2);
nexttile
bar(x,orig_appenergy)
title('Original App Sched')
nexttile
bar(x,[orig_appenergy;orig_ev_op],'stacked')
title('Original App Sched+EV')
nexttile
bar(x,orig_total)
title('Original App Sched with PV and Batt')
nexttile
bar(x,orig_total2)
title('Original App Sched+EV with PV and Batt')
nexttile
bar(x,orig_batt_op)
title('Battery Charge(+)/Discharge(-) Rates')
nexttile
bar(x,orig_batt_op2)
title('Battery Charge(+)/Discharge(-) Rates + EV')
nexttile
bar(x,orig_ev_op)
title('EV Charge Rate without Control')
nexttile
bar(x,transpose(PV))
title('PV Energy Production')
nexttile
bar(x,orig_excess)
title('PV Selling Production')

end
toc