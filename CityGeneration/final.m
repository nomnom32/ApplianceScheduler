function [apps,total_wattage] = input(AO,AU,ST,D,PR,ETF)

%outside the function ipapasok yung inputs based sa number of household size  
owner = [];
pr = [];
for x = 1:size(AO,1)
    %check the ownership if meron ba talaga nitong appliance or wala
    data = [0,AO(x,:)];
    pd = makedist('PiecewiseLinear', 'x', [0 1 2 3 4 5 6], 'Fx', [data]);
    num = fix(random(pd));
    owner = [owner,num];
    
    %since no ownership zero priority dapat
    if num == 0
        pr = [pr,0];
    else
    data = [0,PR(x,:)];
    %debug for priority ranking error
    if data == zeros(size(data))
        data(end) = 1;
    end
    %malupit na pinagbabawal na technique
    pd = makedist('PiecewiseLinear', 'x', [100 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600], 'Fx', [data]);
    num = fix(random(pd));
    pr = [pr,num];
    end
end

%manipulating the MCA_AO para maincorporate yung OA
MCA_AO = owner(:,1:10);
randomizer = randperm(46) + 10;
randomizer = randomizer(:,1:5);

MCA_AO_template = zeros(size(owner));
for x = 1:5
    MCA_AO_template(1,randomizer(1,x)) = owner(1,randomizer(1,x)); 
end
MCA_AO = [MCA_AO, MCA_AO_template(:,11:56)];

%CHECKER;
MCA_AO;
pr;
%------------------------------------------------------------------------------------
%processing col6
col6_template = zeros(size(pr));

%sorting lang naman while preserving the index
[B,index] = sortrows(transpose(pr)); %you can call index as is rin
num_zero = sum(~pr(:)); %number of zeros
size(pr,2); %number of entries sa pr

%for loop that prints the answer
for x = (num_zero+1):size(col6_template,2)
    col6_template(1,index(x,1)) = x-num_zero; %something sa index
end
col6_template;%rankings of similar appliances will be the same regardless of time frame

%------------------------------------------------------------------------------------
col1 = [];
col3 = [];
col4 = [];
col5 = [];
col6 = [];
%loop tayo sa ownership
for z = 1:size(MCA_AO,2)
    %ensure na non-zero ~you own this appliance
    if MCA_AO(1,z) ~= 0
            %how many times will this be used
            data = [0,AU(z,:)];
            pd = makedist('PiecewiseLinear', 'x', [1 2 3 4 5 6], 'Fx', [data]);
            num_fix = fix(random(pd));
            col3_temp = [];
            %loop so that you can make multiple rows
            for y = 1:num_fix
                %col1 is made here
                col1 = [col1,z];
                
                %col3 is made here
                data = [0,ST(z,:)];
                a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                num = fix(random(pd));
                col3_temp = [col3_temp,num];

                col6 = [col6,col6_template(1,z)];
            end
            %col3_temp

            %while loop kasi need namin tanggalin yung consecutive hours
            %(ayaw namin ng durations na 4-5pm tas 5-6pm eh)
            consecutive = true;
            test = zeros(size(col3_temp)-1); %can be replaced with col1 and deleted
    
            while consecutive == true
                col3_temp = transpose(sortrows(transpose(col3_temp)));
    
                tracker = not(any(col3_temp(:)==1) & any(col3_temp(:)==24)); %special case to consider na 1 and 24 are consecutive; so check if may 1 and 24
                x = diff(col3_temp)==1; %check for consecutive numbers in the matrix 
                y = diff(col3_temp)==0; %check for duplitcates in the matrix
   
                if any(x(:)==1) == false && tracker == true && any(y(:)==1) == false
                    consecutive = false; %exit kasi wala na consecutive numbers
                else
                    col3_temp = [];
                    %reroll the col3_temp entries
                    for y = 1:size(test,2)+1
                        data = [0,ST(z,:)];
                        a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                        pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                        num = fix(random(pd));
                        col3_temp = [col3_temp,num];
                    end
                end
                col3_temp;
                col3_revised = col3_temp;
            end

            col3 = [col3,col3_revised];

            %col4 edits na
            difference = [diff(col3_revised),24-col3_revised(end)+col3_revised(1,1)];
            col4_temp = [];

            %we check if multiple entries ba kasi if hindi wala namang
            %conflict dapat sa duration :)
            %multiple entries mean na 2 usages in a day so need na di
            %continuous iyon
            if size(difference,2)>1
            for x = 1:size(difference,2)
                %for every start time generate a duration
                data = [0,D(z,:)];
                data = [0,diff(data)];
                a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                %shortcut na kung 2 hours pagitan nung eme 1 dapat agad ang
                %duration [15,17] 15-16 = 1 hour
                if difference(1,x) == 2
                    col4_temp = [col4_temp,1];
                    col5 = [col5,col3(1,x)+1];
                else
                    %parsing the main data from cumulative into non
                    %cumulative probabilities
                    data = data(1:difference(1,x));
                    data_sum = sum(data(:));
                    if data_sum == 0
                        data_sum = 1;
                        data(end) = 1;
                    end
                    %reversion to cumulative 
                    data = cumsum(data);
                    %recalibrating the probabilities of data kasi gusto
                    %naming kaltasin yung duration
                    data = data/data_sum;
                    a = a(1:difference(1,x));
                    pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                    num = fix(random(pd));
                    col4_temp = [col4_temp,num];
                    
                    %ipagsabay ang timeframe kasi why not
                    data = [0,ETF(z,:)];
                    a = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24];
                    pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                    num_2 = fix(random(pd));
                    %end = start + duration + extra time frame
                    endtime = col3_revised(1,x) + num + num_2;
                    %if lumampas edi set at max
                    if endtime >= (col3_revised(1,x) + difference(1,x) -1)
                        endtime = col3_revised(1,x) + difference(1,x) -1;
                    end
                    %if lumampas sa 24, modulo para bumalik
                    endtime = mod(endtime,24);
                    if endtime == 0
                        endtime = 24;
                    end
                    col5 = [col5,endtime];
                    
                end
            end
            else
                data = [0,D(z,:)];
                %debug for zeros sa dulo
                if data == zeros(size(data))
                data(end) = 1;
                end
                a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                num = fix(random(pd));
                col4_temp = [col4_temp,num];

                if num == 24
                    endtime = 0;
                else 
                    endtime = -1;
                end
                endtime = col3_revised + endtime;
                col5 = [col5,endtime];
                
            end

            col4_temp;
            col4 = [col4,col4_temp];
            
            %endtime = col3+col4+ ETF generated
    end
end


%CHECKER
col1;
col3;
col4;
col5;

%------------------------------------------------------------------------------------
col2 = [];
TW = [16.7 70 38.66 57.99 220.75 207.25 70.11 361.14 141.4 50 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];

for x = 1:size(col1,2)
    col2 = [col2,(TW(1,col1(1,x))*MCA_AO(1,col1(1,x)))];
end

col2
col4
total_wattage = sum(col2.*col4);

%CHECKER
col2;
%------------------------------------------------------------------------------------

apps_try = transpose([col1;col2;col4;col3;col5;col6]);
%pre = size(apps_try)
%------------------------------------------------------------------------------------
%Splicing based on cut-off time %not yet working
%cut_off = 4;

%for x = 1:size(apps_try,1)
%    if apps_try(x,3) == 24
%        apps_try(x,4) = 1;
%        apps_try(x,5) = 24;
%
%    elseif apps_try(x,5) > cut_off && apps_try(x,4) > apps_try(x,5)
%        splice = apps_try(x,:);
%        splice(1,4) = apps_try(x,3) - cut_off + 1;
%        splice(1,5) = 24;
%        
%        apps_try(x,4) = 1;
%        apps_try(x,5) = apps_try(x,5) - cut_off;
%
%    elseif apps_try(x,5) > cut_off && apps_try(x,4) < cut_off
%        splice = apps_try(x,:);
%        splice(1,4) = apps_try(x,3) + 24 - cut_off + 1;
%        splice(1,5) = 24;
%        
%        apps_try(x,4) = 1;
%        apps_try(x,5) = apps_try(x,5) - cut_off;
%        
%    end
%end
%apps_try = [transpose(apps_try), transpose(splice)];
%apps_try = sortrows(transpose(apps_try),1);
%
%
apps = apps_try;
%after = size(apps)
end






