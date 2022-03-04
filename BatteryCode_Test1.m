clear
t = 24;
batteryoperation=zeros(1,t);
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

PVsched = zeros(24,1);
for a=1:24
    if ((a>=10)&&(a<=14))
    PVsched(a,1) = 320;
    end
end
PVsched;

tempvar = appsched.*appwatt;
appenergy = sum(tempvar,1);
imbalance = transpose(PVsched)-appenergy; 

household_load = 6086;
BattCharge = 0.4*household_load;
battcharge_t = zeros(1,t);
HighThresh = 1*household_load;
LowThresh = 0.4*household_load; % Threshold na sinet
MaxBattCharge = 1*household_load;
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
imbalance
battcharge_t
batteryoperation
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

