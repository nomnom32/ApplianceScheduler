function [apps,total_wattage] = input(AO,AU,ST,D,PR,ETF)

owner = [];
pr = [];
for x = 1:size(AO,1)
    %check the ownership if the appliance is present or not
    data = [0,AO(x,:)];
    pd = makedist('PiecewiseLinear', 'x', [0 1 2 3 4 5 6], 'Fx', [data]);
    num = fix(random(pd));
    owner = [owner,num];
    
    %if no ownership -> zero priority 
    if num == 0
        pr = [pr,0];
    else
    data = [0,PR(x,:)];
    %solution for priority ranking error -> data must start with 0 and end
    %with 1 (doesn't affect results because the last "x" value should never
    %appear)
    if data == zeros(size(data))
        data(end) = 1;
    end
    pd = makedist('PiecewiseLinear', 'x', [100 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600], 'Fx', [data]);
    num = fix(random(pd));
    pr = [pr,num];
    end
end

%manipulating the MCA_AO to allow only 5 OA's
MCA_AO = owner(:,1:10); %keep the main appliances

MCA_AO_template = owner(:,11:52);
zero_checker = MCA_AO_template==0;
num_of_zeros = sum(zero_checker(:));
if num_of_zeros >= 37 %means there are at most 5 Other Appliances
    MCA_AO = [MCA_AO, MCA_AO_template]; %same as MCA_AO = owner;;
else
    %get all nonzeros from template, randomize and get 5, then append 
    [row,col,value]=find(MCA_AO_template);
    num_iterations = size(col,2)-5;
    randomizer = randperm(size(col,2));
    removedOA = randomizer(1:num_iterations);
    %MCA_AO_template

    for x = 1:size(removedOA,2)
        MCA_AO_template(1,col(1,removedOA(1,x))) = 0; %this is the index of one of the OA to be removed in MCA_AO_template
    end

    %MCA_AO_template
    MCA_AO = [MCA_AO, MCA_AO_template];
end
    
%CHECKER;
owner;
MCA_AO_template;
MCA_AO;
pr;
%------------------------------------------------------------------------------------
%processing col6
col6_template = zeros(size(pr));

%row sorting
[B,index] = sortrows(transpose(pr)); %you can call index as is rin
num_zero = sum(~pr(:)); %number of zeros
size(pr,2); %number of entries in pr

%for loop that prints the answer
for x = (num_zero+1):size(col6_template,2)
    col6_template(1,index(x,1)) = x-num_zero; %print 1->x while considering the number of zeros in the matrix
end
col6_template;%rankings of similar appliances will be the same regardless of time frame

%------------------------------------------------------------------------------------
col1 = []; %app code index
col3 = []; %start time
col4 = []; %duration
col5 = []; %endtime
col6 = []; %prio rank

for z = 1:size(MCA_AO,2)
    %ensuring that this appliance is owned
    if MCA_AO(1,z) ~= 0
            %appliance usage dictates how many rows there will be of a
            %certain appliance
            data = [0,AU(z,:)];

            if data(end) == 0
                data(end) = 1;
            end
            
            pd = makedist('PiecewiseLinear', 'x', [1 2 3 4 5 6], 'Fx', [data]);
            num_fix = fix(random(pd));
            
            %loop so that you can make multiple rows
            col3_temp = [];
            for y = 1:num_fix
                %col1 is made here %save appliance index
                col1 = [col1,z];
                
                %col3 is made here %starting time generation
                data = [0,ST(z,:)];

                if data(end) == 0
                data(end) = 1;
                end

                a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                num = fix(random(pd));
                col3_temp = [col3_temp,num];

                %col6 has a template so it is retrieved based on the
                %appliance index "z"'
                col6 = [col6,col6_template(1,z)];
            end
            %col3_temp

            %removing consecutive time frames
            consecutive = true;
            test = zeros(size(col3_temp)); %get the size of col3_temp 
            %test = zeros(size(col3_temp)-1); past code for line98 

            while consecutive == true
                %sorting col3_temp in ascending order
                col3_temp = transpose(sortrows(transpose(col3_temp)));
    
                tracker = not(any(col3_temp(:)==1) & any(col3_temp(:)==24)); %1 and 24 are consecutive; so it must be accounted for
                x = diff(col3_temp)==1; %check for consecutive numbers in the matrix 
                y = diff(col3_temp)==0; %check for duplitcates in the matrix
   
                if any(x(:)==1) == false && tracker == true && any(y(:)==1) == false %no difference of 1 for any numbers, no 1's and 24's present at the same time, no duplicates
                    consecutive = false; %exit if no more consecutive numbers
                else
                    col3_temp = [];
                    %reroll the col3_temp entries
                    for y = 1:size(test,2) %size determines how many to reroll
                        data = [0,ST(z,:)];
                        
                        if data(end) == 0
                            data(end) = 1;
                        end

                        z;
                        data;
                        
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

            difference = [diff(col3_revised),24-col3_revised(end)+col3_revised(1,1)];
            col4_temp = [];

            if size(difference,2) > 1 %check for multilple entries
            %fprintf('here\n');
            for x = 1:size(difference,2)
                %for every start time generate a duration
                data = [0,D(z,:)];
                %data = [0,diff(data)];
                a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                if difference(1,x) == 2
                    col4_temp = [col4_temp,1];
                    col5 = [col5,col3_revised(1,x)+1];
                else
                    %converting the main data from cumulative into non
                    %cumulative probabilities
                    data = data(1:difference(1,x));
                    data_sum = data(end);
                    if data_sum == 0
                        data_sum = 1;
                        data(end) = 1;
                    end
                    %reversion to cumulative 
                    data = data/data_sum;
                    a = a(1:difference(1,x));
                    pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                    num = fix(random(pd));
                    col4_temp = [col4_temp,num];
                    
                    data = [0,ETF(z,:)];
                    data(end) = 1;
                    a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                    pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                    num_2 = fix(random(pd));
                    
                    if (num + num_2 <= difference(1,x)-1)
                        endtime = col3_revised(1,x) + num + num_2;
                    else
                        endtime = col3_revised(1,x) + difference(1,x) - 1;
                    end
                    if endtime > 24
                        endtime = mod(endtime,24);
                    end
                    if endtime == 0
                        endtime = 24;
                    end
                    col5 = [col5,endtime];
                    
                end
            end
            else
                data = [0,D(z,:)];
                if data == zeros(size(data))
                    data(end) = 1;
                end
                a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                num = fix(random(pd));
                col4_temp = [col4_temp,num];
                
                data = [0,ETF(z,:)];
                data(end) = 1;
                a = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
                pd = makedist('PiecewiseLinear', 'x', [a], 'Fx', [data]);
                num_2 = fix(random(pd));
                
                if num == 24
                    endtime = col3_revised; 
                else
                    if (col3_revised + num + num_2 <= 24)
                        endtime = col3_revised + num + num_2;
                    else 
                        endtime = col3_revised + num + num_2 - 24;
                        if (endtime > col3_revised)
                            endtime = col3_revised;
                        end 
                    end
                end
                col5 = [col5,endtime];
                
            end

            col4_temp;
            col4 = [col4,col4_temp];
    end
end


%CHECKER
col1;
col3;
col4;
col5;

%------------------------------------------------------------------------------------
col2 = [];
TW = [16.7 70 38.66 57.99 220.75 207.25 70.11 361.14 141.4 60 276 26.5 7.8 320 166 47.3 576.7 10 23.23 150 8.5 152 20 333.7 1.1 412.2 3 25 30.2 596.8 302.9 185 1500 80.8 1500 10.3 30.2 1500 24 504.5 660 440 4.9 105.5 26.8 120 35 150 75 10 361.14 1200];

for x = 1:size(col1,2)
    col2 = [col2,(TW(1,col1(1,x))*MCA_AO(1,col1(1,x)))];
end
%col2 formula is TW*number of appliances owned


col2;
col4;
total_wattage = sum(col2.*col4); %sum product

%CHECKER
col2;
%------------------------------------------------------------------------------------

apps_try = transpose([col1;col2;col4;col3;col5;col6]); %return the appliance matrix


%set the reset time of the day
cut_off = 4;
for x = 1:size(apps_try,1)
    if apps_try(x,4) < cut_off
        apps_try(x,4) = apps_try(x,4) - cut_off + 1 + 24;
    else
        apps_try(x,4) = apps_try(x,4) - cut_off + 1;
    end

    if apps_try(x,5) < cut_off
        apps_try(x,5) = apps_try(x,5) - cut_off + 24;
    elseif apps_try(x,5) == cut_off
        apps_try(x,5) = 24;
    else
        apps_try(x,5) = apps_try(x,5) - cut_off;
    end
    %print st=1 and et=24 for 24 hour timeframes
    if (apps_try(x,4) > apps_try(x,5))
        if ((24-apps_try(x,4)+1)+apps_try(x,5)==24)
            apps_try(x,4)=1;
            apps_try(x,5)=24;
        end
    end    
end

apps = apps_try;
end
