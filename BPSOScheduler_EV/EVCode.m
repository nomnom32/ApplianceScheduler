function evcharge_t = EVCode(appsched,appwatt,peak,ev_int_ch)

tempvar = appsched.*appwatt;
appenergy = sum(tempvar,1);
imbalance = peak-appenergy; 

%% TYPE of EV
%e-trike
ev_rating = 3300;
% DOD 80%, 20% Limit
% 48V 70 AH 2000 cycles at 80%
% C = 
% E-Trike in PH: https://gulfnews.com/world/asia/philippines/900-e-trikes-deployed-in-manila-1.2230670
% E-Trike in PH: https://www.bemac-philippines.com/en/updates/news-from-the-web
% E-Trike Specs: https://www.adb.org/sites/default/files/linked-documents/43207-013-phi-oth-12.pdf
% Liffe Cycle: https://www.bimblesolar.com/batterycompare
% Charging Rate: https://www.robotshop.com/media/files/pdf/hyperion-99v-2100mah-lifepo4-transmitter-pack-datasheet.pdf


% e-car
% ev_rating = 34000;
% https://evcompare.io/cars/changan/changan-ev360/

%% Main Function

evcharge_t = zeros(1,12);
HighThresh = 0.8*ev_rating-(ev_int_ch/100)*ev_rating;

[sorted,sorted_index]=sort([imbalance(1,1:2) imbalance(1,15:24)],'descend'); %sort 6pm to 6am
layer = abs(diff([sorted 0]));

ctr=12; 

for a=1:12 % 
    if layer(1,a)>0 && (layer(1,a)*a)+sum(transpose(evcharge_t),1)<HighThresh
        for k=1:a % from 1 to current stair
            evcharge_t(1,sorted_index(1,k))= evcharge_t(1,sorted_index(1,k))+layer(1,a);
        end
    elseif layer(1,a)>0 && (layer(1,a)*a)+sum(transpose(evcharge_t),1)>HighThresh
        excess=HighThresh-sum(transpose(evcharge_t),1);
        ctr=a;
        break
    end
end

for a=1:ctr
    evcharge_t(1,sorted_index(1,a))= evcharge_t(1,sorted_index(1,a))+excess/ctr;
end

evcharge_t = [evcharge_t(1,1:2) zeros(1,12) evcharge_t(1,3:12)]; %positive if charging, 0 or positive lang



