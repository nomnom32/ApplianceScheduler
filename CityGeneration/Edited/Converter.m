clc
clear
tic
format long g

%DATA INPUT
probability_data

% DATA PROCESSING
consumption_matrix = zeros(20,24);
for output_file_name = 1:1 %modift to 1:3 if needed then run multiple times

filename = sprintf('%s%d.m','userinput',output_file_name);
fileID = fopen(filename,'w');
plot = zeros(1,24);
start_identifier = 1 + (output_file_name-1)*700;
end_identifier = 700 + (output_file_name-1)*700;
for identifier = start_identifier:end_identifier

pd = makedist('PiecewiseLinear', 'x', [1 2 3 4 5], 'Fx', [0 0.0777 0.376 0.7328 1]);
Household_size = fix(random(pd));

if Household_size ==1
apps=final(AO1,AU1,ST1,D1,PR1,ETF1);

elseif Household_size ==2
apps=final(AO2,AU2,ST2,D2,PR2,ETF2);

elseif Household_size ==3
apps=final(AO3,AU3,ST3,D3,PR3,ETF3);

elseif Household_size ==4
apps=final(AO4,AU4,ST4,D4,PR4,ETF4);

end

%-----------------------------------------
%these are the probabilities na wala per household size [dahil sa makedist
%function]
ESS = [7.14 6.67 9.05 19.86];
EV = [28.57 22.67 21.11 22.6];
%probs na based on household size (by row) and number (by column)
SP = [16.67 41.67 16.67 25
      26.23 13.11 39.34 21.31
      22.929 8.9171 33.757 34.394
      17.272 10.909 30.909 40.909];

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
    pd = makedist('PiecewiseLinear', 'x', [1 2 3 4 5 6], 'Fx', [0 0.63212 0.86466 0.95021 0.98168 1]); %based on expontentially devaying probability from 1 to 5
    EV_charge = (fix(random(pd))+7)*5;
end
%------------------
pd = makedist('PiecewiseLinear', 'x', [0 1 2 3 4], 'Fx', [0 SP(Household_size,1)/100 (SP(Household_size,1)+SP(Household_size,2))/100 (SP(Household_size,1)+SP(Household_size,2)+SP(Household_size,3))/100 1]);
SP_num = fix(random(pd));

%-----------------------------------------------------------
%Peak Threshold Portion
%TW is yet to be updated

TW = transpose([16.7 70 38.66 57.99 220.75 207.25 70.11 361.14 141.4 60 276 26.5 7.8 320 166 47.3 576.7 10 23.23 150 8.5 152 20 333.7 1.1 412.2 3 25 30.2 596.8 302.9 185 1500 80.8 1500 10.3 30.2 1500 24 504.5 660 440 4.9 105.5 26.8 120 35 150 75 10 361.14 1200]);
%52 total appliances and 24 hours in a day
schedule = zeros(52,24);
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
%schedule will displays 0's and 1's
schedule;
%TW temp was used!
kWh = schedule.*TW;
%finding the peak
threshold = 0.8*max(sum(kWh));

%--------------------------------------------------------------
%Plotting 
store = sum(kWh);
plot = store + plot;

%--------------------------------------------------------------
%Writing on a .m file

%fprintf(fileID,'%%Household \n');
%fprintf(fileID,'%d\n',identifier);

%fprintf(fileID,'%%Household size: \n');
%fprintf(fileID,'%d\n',Household_size);


%threshold = 1200; %fixed threshold
%fprintf(fileID,'%% 80%% Peak Threshold \n');
%fprintf(fileID,'%.2f\n',threshold);


%fprintf(fileID,'%%Total Wattage: \n');
%--------------------------------------------------------------
%total wattage as sum product of TW and Duration
total_wattage = sum(apps(:,2).*apps(:,3));

%Setting the budget (needs to be after schedule generation)
if Household_size ==1
budget = (0.2705*total_wattage-119.83)/30;

elseif Household_size ==2
budget = (0.0956*total_wattage+1667.6)/30;

elseif Household_size ==3
budget = (0.1918*total_wattage+1249.5)/30;

elseif Household_size ==4
budget = (0.2459*total_wattage+1263.6)/30;

end
%--------------------------------------------------------------
%fprintf(fileID,'%.2f\n',total_wattage);


%printing on the files
%fprintf(fileID,'%%ID H# HT PT TotW B \n');
%fprintf(fileID,'0 %d %d %.2f %.2f %.2f\n', identifier, Household_size, threshold, total_wattage, budget);

%fprintf(fileID, '%%APPno TW D FR TO PR\n');

%for x=1:size(apps,1)
%    for y=1:6
%        if y ~=6 && y ~=2
%            fprintf(fileID, '%d ',apps(x,y));
%        elseif y == 2
%            fprintf(fileID, '%.2f ',apps(x,y));
%        else
%            fprintf(fileID, '%d\n',apps(x,y));
%        end
%    end
%end

%fprintf(fileID,'%%ESS and Charge: \n');
%fprintf(fileID,'98 %d %d 0 0 0\n',ESS_possess,ESS_charge);
%fprintf(fileID,'%%EV and Charge: \n');
%fprintf(fileID,'99 %d %d 0 0 0\n',EV_possess, EV_charge);
%fprintf(fileID,'%%Solar Panels: \n');
%fprintf(fileID,'100 %d 0 0 0 0\n\n',SP_num);


%printing on the files in matrix form
fprintf(fileID,'H%d = [0 %d %d %.2f %.2f %.2f\n',identifier, identifier, Household_size, threshold, total_wattage, budget);
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

fprintf(fileID,'98 %d %d 0 0 0\n',ESS_possess,ESS_charge);
fprintf(fileID,'99 %d %d 0 0 0\n',EV_possess, EV_charge);
fprintf(fileID,'100 %d 0 0 0 0];\n\n',SP_num);


end

%plotting continued
%once multiple files are needed I will need to save the plot variable
%elsewhere then rerun the code then re-add
figure(output_file_name);
plot;
consumption_matrix(output_file_name,:) = plot;
bar(plot)
xlabel('Hours of the days');
ylabel('kWh');
title(['Total Energy Consumption of ', filename])

end
toc


