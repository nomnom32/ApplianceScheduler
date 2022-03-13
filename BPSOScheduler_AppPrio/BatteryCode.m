function battcharge_r = BatteryCode(appsched, appwatt, PV, initial_charge, h_load)
%% Test Input
t = 24; 
batteryoperation=zeros(1,t);

%% DATA INPUT
tempvar = appsched.*appwatt;
appenergy = sum(tempvar,1);
imbalance = transpose(PV)-appenergy;


BattCharge = (initial_charge/100)*h_load; % initial charge
battcharge_r = zeros(1,t);
battcharge_t = zeros(1,t); % 24 hour battery current charge
HighThresh = 1*h_load; 
LowThresh = 0.4*h_load; 
MaxBattCharge = 1*h_load;
% MinBattCharge = 0; 
MinBattCharge = LowThresh; 

for a=1:t
    if (HighThresh<BattCharge)&&(BattCharge<MaxBattCharge) %If greater than highthreshold and less than maxbatt charge
        BattCharge = discharging(BattCharge,imbalance(1,a),MinBattCharge); % {Discharge}
        batteryoperation(1,a) = -1;
    elseif (LowThresh<=BattCharge)&&(BattCharge <=HighThresh) %if higher than low threshold and lower than high threshol 
        if (imbalance(1,a)>0) % if PV-Appliance >0 {Charge}
            BattCharge = charging(BattCharge,imbalance(1,a),MaxBattCharge);
            batteryoperation(1,a) = 1;
        elseif (imbalance(1,a)<0) % if Appliance > PV  {Discharge}
            BattCharge = discharging(BattCharge,imbalance(1,a),MinBattCharge);
            batteryoperation(1,a) = -1;
        elseif (imbalance(1,a)==0) 
            batteryoperation(1,a)= 0;
        end
    elseif (BattCharge<LowThresh) %If lower than low thresh
        if (imbalance(1,a)>0) % If PV-App > 0 {Charge}
            BattCharge = charging(BattCharge,imbalance(1,a),MaxBattCharge);
            batteryoperation(1,a) = 1;
        elseif (imbalance(1,a)<=0) % If PV <= App {Idle}
            batteryoperation(1,a)= 0;
        end
    end
    battcharge_t(1,a)=BattCharge; % Save Battcharge
end

battcharge_r = diff([(initial_charge/100)*h_load battcharge_t]); %positive if charging, %negative if charging


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

