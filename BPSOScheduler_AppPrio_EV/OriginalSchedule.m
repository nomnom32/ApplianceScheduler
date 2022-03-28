clear;
%% IMPORT INPUT DATA
data=load('UserInput_T4.m');
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

%Battery Sizing
batt = 1020; %batt size for https://www.rollsbattery.com/battery/12-fs-24/ 20 Hour Rate, 
batt_size = batt;

batt_ctr = 1;
while(batt_size<total_energy)
    batt_ctr=batt_ctr+1;
    batt_size = batt*batt_ctr;
end

%Solar Panel Operation %Assume constant for all households
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

orig_tempvar = orig_sched.*app_TW;
orig_appenergy = sum(orig_tempvar,1);
orig_ev_op = EVCode(orig_sched,app_TW, peak_threshold,ev_int_ch);
orig_cost = sum(transpose(orig_appenergy.*price(price_code,:)),1);
orig_cost_withev = orig_cost+sum(orig_ev_op.*price(price_code,:),2);

fprintf('EV initial Charge = %d% \n',ev_int_ch);

%Original Schedule
fprintf("Original Cost without EV = %d\n",orig_cost);
fprintf("Original Peak without EV = %d\n",max(orig_appenergy));
fprintf("Original PAR without EV = %d\n\n",max(orig_appenergy)/(sum(orig_appenergy,2)/24));

%Original Schedule + EV Operation
fprintf("Original Cost with EV = %d\n",orig_cost_withev);
fprintf("Original Peak with EV = %d\n",max(orig_appenergy+orig_ev_op));
fprintf("Original PAR with EV = %d\n\n",max(orig_appenergy+orig_ev_op)/(sum(orig_appenergy+orig_ev_op,2)/24));
