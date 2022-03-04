clear
t = 24;
ev_operation=zeros(1,t);
appsched = [0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     1     1     1     1     0     0     0
            0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     1     1     1     1     1     0     0     0
            0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     1     1     1     1     0     0     0
            1     1     1     1     1     1     0     0     0     0     0     0     0     0     0     0     0     1     1     1     1     1     1     0
            0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     1     0     0     0
            1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1
            0     0     0     0     0     0     0     0     0     0     0     0     0     1     0     0     0     0     0     0     0     0     0     0
            0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     1     0     0     0     0     0
            0     0     0     0     0     0     0     0     0     1     0     0     0     0     0     0     0     0     0     0     0     0     0     0];
appwatt = [33.4
           77.3
           116
           220.8
           207.3
           70.1
           361.1
           141.4
           60];

total_watt = appsched.*appwatt;
kwH = sum(total_watt,1);
peak = max(kwH);


tempvar = appsched.*appwatt;
appenergy = sum(tempvar,1);
imbalance = peak-appenergy; 

%e-trike
% ev_rating = 3300;
%https://gulfnews.com/world/asia/philippines/900-e-trikes-deployed-in-manila-1.2230670

%e-car
ev_rating = 34000;
%https://evcompare.io/cars/changan/changan-ev360/

EVCharge = 0.2*ev_rating;
evcharge_t = zeros(1,t);
HighThresh = 0.8*ev_rating;
LowThresh = 0.2*ev_rating; % Threshold na sinet
MaxBattCharge = 1*ev_rating;
MinBattCharge = 0;

for a=1:t
    if (a<=6)||(a>=18)
        if (HighThresh<=EVCharge)&&(EVCharge<=MaxBattCharge)
            ev_operation(a) = 0;
        elseif (LowThresh<EVCharge)&&(EVCharge <HighThresh)
            if (imbalance(a)>0)
                EVCharge = charging(EVCharge,imbalance(a),HighThresh);
                ev_operation(a) = 1;
            else
                ev_operation(a)= 0;
            end
        elseif (EVCharge<=LowThresh)
            if (imbalance(a)>0)
                EVCharge = charging(EVCharge,imbalance(a),HighThresh);
                ev_operation(a) = 1;
            elseif (imbalance(a)<=0)
                ev_operation(a)= 0;
            end
        end
    else
        ev_operation(a) = 0;
    end
    evcharge_t(1,a)=EVCharge;
end
imbalance
evcharge_t
ev_operation
%% Charging Function Code

function EnergyCharged = charging(BattCharge,imbalance,MaxBattCap)
%     if abs(imbalance)>MaxBattCap
%         NewBattCharge= BattCharge+MaxBattCap;
%     else
%         NewBattCharge= BattCharge+abs(imbalance);
%     end
    NewBattCharge= BattCharge+abs(imbalance);
    if (NewBattCharge>MaxBattCap)
        NewBattCharge=MaxBattCap;
    end
EnergyCharged = NewBattCharge;
end


%% Discharging Function
function EnergyDischarged = discharging(BattCharge,imbalance,MinBattCap)
%     if abs(imbalance)>MaxBattCap %magdischarge lang kapag mas malaki consumption sa PV generated
%         NewBattCharge= BattCharge-MaxBattCap;
%     else
%         NewBattCharge= BattCharge-abs(imbalance);
%     end
    NewBattCharge= BattCharge-abs(imbalance);
    if (NewBattCharge<MinBattCap)
        NewBattCharge = MinBattCap;
    end
EnergyDischarged = NewBattCharge;
end

