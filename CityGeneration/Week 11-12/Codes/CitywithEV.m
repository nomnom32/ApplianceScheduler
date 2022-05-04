clc;
clear;
tic
format long g
%% IMPORT INPUT DATA

%These two lines must be constantly changed to check data from userinputx.m
userinput9
filename = "userinput9"; %change according to input

%Initialize Global Variables to save EV Operation and EC Consumption GRaphs
consumption_matrix = zeros(1,24);
EV_operation = zeros(1,24);
finalcost_orig_value = 0; 
finalcost_orig_and_ev_value = 0;
finalcost_ev_value = 0;


for houses=5601:6300
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



%with EV    
orig_tempvar = orig_sched.*app_TW;
orig_appenergy = sum(orig_tempvar,1);

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
end

orig_appenergy; %orig_sched
orig_ev_op; %ev_op
orig_total2 = orig_ev_op + orig_appenergy; %orig_sched + ev

EV_operation = EV_operation + orig_ev_op;
consumption_matrix = consumption_matrix + orig_ev_op + orig_appenergy;

final_cost_orig = sum(transpose(orig_appenergy.*price(price_code,:)),1);
final_cost_ev = sum(transpose(orig_ev_op.*price(price_code,:)),1);
%%computation of final cost -> orig sched only
final_cost_orig_and_EV = sum(transpose(orig_total2.*price(price_code,:)),1);
%%computation of final cost -> orig sched + EV only


finalcost_orig_value = finalcost_orig_value + final_cost_orig; 
finalcost_orig_and_ev_value = finalcost_orig_and_ev_value + final_cost_orig_and_EV; 
finalcost_ev_value = finalcost_ev_value + final_cost_ev;

%unused code below
%fprintf('final cost %d = %.2f \n',houses, final_cost)
%fprintf('\nEV initial Charge = %d \n',ev_int_ch);
%name = sprintf('original schedule %d:',houses);
%disp(name)
%disp(orig_sched)


end
%EV_operation
figure(1);
bar(EV_operation)
xlabel('Hours of the days');
ylabel('kWh');
title(['Total Energy Consumption from EV Operations Only of', filename])

%consumption_matrix
figure(2);
bar(consumption_matrix)
xlabel('Hours of the days');
ylabel('kWh');
title(['Total Energy Consumption from Appliances and EV Operations of', filename])

finalcost_orig_value
finalcost_orig_and_ev_value
finalcost_ev_value


toc