clc;
clear;
tic
format long g
%% IMPORT INPUT DATA
userinput1
userinput2
userinput3
userinput4
userinput5
userinput6
userinput7
userinput8
userinput9
userinput10
userinput11
userinput12
userinput13
userinput14
userinput15
userinput16
userinput17
userinput18
userinput19
userinput20

%Initialize Global Variables to save EV Operation and EC Consumption GRaphs
city_EV_PV_ESS = zeros(20,25);
city_EV = zeros(20,25);
city = zeros(20,25);
EV_operation = zeros(20,25);
PV_operation = zeros(20,25);
ESS_operation = zeros(20,25);
Excess_operation = zeros(20,25);

%Intialize placeholders
holder_city_EV_PV_ESS = 0;
holder_city_EV = 0;
holder_city = 0;
holder_ev = 0;
holder_pv = 0;
holder_ess = 0;
holder_excess = 0;

cost_holder_city_EV_PV_ESS = 0;
cost_holder_city_EV = 0;
cost_holder_city = 0;
cost_holder_ev = 0;
cost_holder_pv = 0;
cost_holder_ess = 0;
cost_holder_excess = 0;
%---------------------------------------------------------------
for iteration = 1:20

start_identifier = 1 + (iteration-1)*700;
if iteration == 20
    end_identifier = 761 + (iteration-1)*700;
else
    end_identifier = 700 + (iteration-1)*700;
end

%---------------------------------------------------------------

for houses=start_identifier:end_identifier

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

%% Without EV

ev_op = zeros(1,24); % No EV
orig_tempvar = orig_sched.*app_TW; 
orig_appenergy = sum(orig_tempvar,1);



%% With EV

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
%+EV

for k=1:24 % Find total consumption from utility
    if PV(k,1)>0
        orig_total2(1,k) = orig_total2(1,k)-PV(k,1);
    end
    if orig_batt_op2(1,k) < 0
        orig_total2(1,k) = orig_total2(1,k)+orig_batt_op2(1,k);
        orig_batt_op_charging2(1,k)=0;
    end
    if orig_total2(1,k) <0
        orig_total2(1,k)=0;
    end    
end

orig_excess = transpose(PV)-orig_appenergy-orig_ev_op-orig_batt_op_charging2; %computation of PV excess energy
for k=1:24
    if orig_excess(1,k)<0
        orig_excess(1,k)=0;
    end
end


%EV only
holder_ev = holder_ev + orig_ev_op;
cost_holder_ev = cost_holder_ev + sum(transpose(orig_ev_op.*price(price_code,:)),1);

%ESS only
holder_ess = holder_ess + orig_batt_op2;
cost_holder_ess = cost_holder_ess + sum(transpose(orig_batt_op2.*price(price_code,:)),1);

%PV only
PV = transpose(PV); 
holder_pv = holder_pv + PV;
cost_holder_pv = cost_holder_pv + sum(transpose(PV.*price(price_code,:)),1); 


%excess only
holder_excess = holder_excess + orig_excess; 
cost_holder_excess = cost_holder_excess + sum(transpose(orig_excess.*price(price_code,:)),1); 


%Appliances only
holder_city = holder_city + orig_appenergy;
cost_holder_city = cost_holder_city + sum(transpose(orig_appenergy.*price(price_code,:)),1);

%EV + Appliances
holder_city_EV = holder_city_EV + orig_appenergy + orig_ev_op;
cost_holder_city_EV = cost_holder_city_EV + sum(transpose((orig_appenergy+orig_ev_op).*price(price_code,:)),1);

%EV + PV + ESS + Appliances
holder_city_EV_PV_ESS = holder_city_EV_PV_ESS + orig_total2; 
cost_holder_city_EV_PV_ESS = cost_holder_city_EV_PV_ESS + sum(transpose(orig_total2.*price(price_code,:)),1)-sum(transpose(orig_excess.*price(price_code,:))); %computation of final cost for conumer


end

city_EV_PV_ESS(iteration,:) = [holder_city_EV_PV_ESS,cost_holder_city_EV_PV_ESS];
city_EV(iteration,:) = [holder_city_EV,cost_holder_city_EV]; 
city(iteration,:) = [holder_city,cost_holder_city]; 
EV_operation(iteration,:) = [holder_ev,cost_holder_ev]; 
PV_operation(iteration,:) = [holder_pv,cost_holder_pv];
ESS_operation(iteration,:) = [holder_ess,cost_holder_ess];
Excess_operation(iteration,:) = [holder_excess,cost_holder_excess];


%Reintialize placeholders
holder_city_EV_PV_ESS = 0;
holder_city_EV = 0;
holder_city = 0;
holder_ev = 0;
holder_pv = 0;
holder_ess = 0;
holder_excess = 0;

cost_holder_city_EV_PV_ESS = 0;
cost_holder_city_EV = 0;
cost_holder_city = 0;
cost_holder_ev = 0;
cost_holder_pv = 0;
cost_holder_ess = 0;
cost_holder_excess = 0;

end

toc
