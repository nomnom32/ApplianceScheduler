clc
clear
tic
format long g

%DATA INPUT
probability_data


% DATA PROCESSING
fileID = fopen('userinput.m','w');
for identifier = 1:2000

%di parin ata updated yung household_size probabilities
pd = makedist('PiecewiseLinear', 'x', [1 2 3 4 5], 'Fx', [0 0.034 0.185 0.723 1]);
Household_size = fix(random(pd));

if Household_size ==1
final(AO1,AU1,ST1,D1,PR1,ETF1)
apps=ans;

elseif Household_size ==2
final(AO2,AU2,ST2,D2,PR2,ETF2)
apps=ans;

elseif Household_size ==3
final(AO3,AU3,ST3,D3,PR3,ETF3)
apps=ans;

elseif Household_size ==4
final(AO4,AU4,ST4,D4,PR4,ETF4)
apps=ans;

end

%-----------------------------------------
ESS = [7.14 6.67 9.05 19.86];
EV = [28.57 22.67 21.11 22.6];
SP = [16.67 41.67 16.67 25
      26.23 13.11 39.34 21.31
      22.929 8.9171 33.757 34.394
      17.272 10.909 30.909 40.909];
charge = [40 30 20 10]; %20 / 40 / 60 / 80 -> invented probability palang ito must be changed

ESS_possess = 0;
EV_possess = 0;
EV_charge = 0;
ESS_charge = 0;
SP_num = 0;

pd = makedist('PiecewiseLinear', 'x', [0 1 2], 'Fx', [0 ESS(1,Household_size)/100 1]);
ESS_possess = fix(random(pd));
if ESS_possess>0
    pd = makedist('PiecewiseLinear', 'x', [1 2 3 4 5], 'Fx', [0 0.25 0.5 0.75 1]);
    ESS_charge = fix(random(pd))*20;
end
%------------------
pd = makedist('PiecewiseLinear', 'x', [0 1 2], 'Fx', [0 EV(1,Household_size)/100 1]);
EV_possess = fix(random(pd));
if EV_possess>0
    pd = makedist('PiecewiseLinear', 'x', [1 2 3 4 5], 'Fx', [0 0.25 0.5 0.75 1]);
    EV_charge = fix(random(pd))*20;
end
%------------------
pd = makedist('PiecewiseLinear', 'x', [0 1 2 3 4], 'Fx', [0 SP(Household_size,1)/100 (SP(Household_size,1)+SP(Household_size,2))/100 (SP(Household_size,1)+SP(Household_size,2)+SP(Household_size,3))/100 1]);
SP_num = fix(random(pd));

%-----------------------------------------------------------
%Dynamic Threshold Portion
TW = transpose([16.7 70 38.66 57.99 220.75 207.25 70.11 361.14 141.4 50 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
schedule = zeros(56,24);
for x = 1:size(apps,1)
    %go to row# based on 1st column
    %go to column# based on 4th column
    %change the numbers to 1 based on 3rd column
    for y = 0:apps(x,3)-1
        z = apps(x,4)+y;
        if z > 24
            z = z - 24;
        end
        schedule(apps(x,1),z) = 1;
    end
end
%uncomment to see schedule
schedule;
%TW temp was
%used!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
kWh = schedule.*TW;
threshold = 0.8*max(sum(kWh));
%--------------------------------------------------------------

%Writing on a .m file

%budget temporary
budget = 1;



%fprintf(fileID,'%%Household \n');
%fprintf(fileID,'%d\n',identifier);

%fprintf(fileID,'%%Household size: \n');
%fprintf(fileID,'%d\n',Household_size);


%threshold = 1200; %fixed threshold
%fprintf(fileID,'%% 80%% Peak Threshold \n');
%fprintf(fileID,'%.2f\n',threshold);


%fprintf(fileID,'%%Total Wattage: \n');
total_wattage = sum(apps(:,2).*apps(:,3));
%fprintf(fileID,'%.2f\n',total_wattage);

fprintf(fileID,'%%ID H# HT PT TotW B \n');
fprintf(fileID,'0 %d %d %.2f %.2f %.2f\n', identifier, Household_size, threshold, total_wattage, budget);

fprintf(fileID, '%%APPno TW D FR TO PR\n');

for x=1:size(apps,1)
    for y=1:6
        if y ~=6 && y ~=2
            fprintf(fileID, '%d ',apps(x,y));
        elseif y == 2
            fprintf(fileID, '%.2f ',apps(x,y));
        else
            fprintf(fileID, '%d\n',apps(x,y));
        end
    end
end

fprintf(fileID,'%%ESS and Charge: \n');
fprintf(fileID,'98 %d %d 0 0 0\n',ESS_possess,ESS_charge);
fprintf(fileID,'%%EV and Charge: \n');
fprintf(fileID,'99 %d %d 0 0 0\n',EV_possess, EV_charge);
fprintf(fileID,'%%Solar Panels: \n');
fprintf(fileID,'100 %d 0 0 0 0\n\n',SP_num);
end
toc


