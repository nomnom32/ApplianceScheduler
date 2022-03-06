function battcharge_t = BatteryCode(appsched, appwatt, PV, initial_charge, h_load)

%% Test Input
t = 24; 
batteryoperation=zeros(1,t);

%% DATA INPUT
tempvar = appsched.*appwatt;
appenergy = sum(tempvar,1);
imbalance = transpose(PV)-appenergy; 


BattCharge = (initial_charge/100)*h_load;
battcharge_t = zeros(1,t);
HighThresh = 1*h_load;
LowThresh = 0.4*h_load; 
MaxBattCharge = 1*h_load;
% MinBattCharge = 0; 
MinBattCharge = LowThresh; 

for a=1:t
    if (HighThresh<=BattCharge)&&(BattCharge<=MaxBattCharge) %If greater than highthreshold and less than maxbatt charge
        BattCharge = discharging(BattCharge,imbalance(a),MinBattCharge);
        batteryoperation(a) = -1;
    elseif (LowThresh<BattCharge)&&(BattCharge <HighThresh)
        if (imbalance(a)>0)
            BattCharge = charging(BattCharge,imbalance(a),MaxBattCharge);
            batteryoperation(a) = 1;
        elseif (imbalance(a)<0)
            BattCharge = discharging(BattCharge,imbalance(a),MinBattCharge);
            batteryoperation(a) = -1;
        elseif (imbalance(a)==0)
            batteryoperation(a)= 0;
        end
    elseif (BattCharge<=LowThresh)
        if (imbalance(a)>0)
            BattCharge = charging(BattCharge,imbalance(a),MaxBattCharge);
            batteryoperation(a) = 1;
        elseif (imbalance(a)<=0)
            batteryoperation(a)= 0;
        end
    end
    battcharge_t(1,a)=BattCharge;
end

%% Charging Function Code

function EnergyCharged = charging(BattCharge,imbalance,MaxBattCap)
    NewBattCharge= BattCharge+abs(imbalance);
    if (NewBattCharge>MaxBattCap)
        NewBattCharge=MaxBattCap;
    end
EnergyCharged = NewBattCharge;
end


%% Discharging Function
function EnergyDischarged = discharging(BattCharge,imbalance,MinBattCap)
    NewBattCharge= BattCharge-abs(imbalance);
    if (NewBattCharge<MinBattCap)
        NewBattCharge = MinBattCap;
    end
EnergyDischarged = NewBattCharge;
end

end
