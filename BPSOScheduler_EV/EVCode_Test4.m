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
ev_rating = 3300;
limit=1200; %25A*48V
%https://gulfnews.com/world/asia/philippines/900-e-trikes-deployed-in-manila-1.2230670

%e-car
% ev_rating = 34000;
%https://evcompare.io/cars/changan/changan-ev360/

evcharge_t = zeros(1,12);
HighThresh = 0.8*ev_rating-0.2*ev_rating;

[sorted,sorted_index]=sort([imbalance(1,1:2) imbalance(1,15:24)],'descend'); %sort 6pm to 6am in descending order
layer = abs(diff([sorted 0]));

ctr=12; 

%% Working Code. Default. No limit
for a=1:12 % 
    if layer(1,a)>0 && (layer(1,a)*a)+sum(evcharge_t,2)<HighThresh
        for k=1:a % from 1 to current stair
            evcharge_t(1,sorted_index(1,k))= evcharge_t(1,sorted_index(1,k))+layer(1,a);
        end
    elseif layer(1,a)>0 && (layer(1,a)*a)+sum(evcharge_t,2)>HighThresh
        excess=HighThresh-sum(evcharge_t,2);
        ctr=a;
        break
    end
end 

for a=1:ctr
    evcharge_t(1,sorted_index(1,a))= evcharge_t(1,sorted_index(1,a))+excess/ctr;
end

%% Testing Code with Limit

% excess1=0;
% limited=0;
% count=0;
% 
% for a=1:12 % 
%     if layer(1,a)>0 && (layer(1,a)*a)+sum(transpose(evcharge_t),1)<HighThresh % Normal Distribution
%         for k=1:a % from 1 to current stair
%             if evcharge_t(1,sorted_index(1,k))+layer(1,a)<limit
%                 evcharge_t(1,sorted_index(1,k))= evcharge_t(1,sorted_index(1,k))+layer(1,a)
%             else
%                 excess1=excess1+(limit-evcharge_t(1,sorted_index(1,k)))
%                 evcharge_t(1,sorted_index(1,k))= limit
%                 count=a
%             end
%         end
% 
%     elseif layer(1,a)>0 && (layer(1,a)*a)+sum(transpose(evcharge_t),1)>HighThresh %
%         excess=HighThresh-sum(transpose(evcharge_t),1)
%         break
%     end
% end 


%% Excesss

removed=0; 
lim = zeros(1,12);

for a=1:12 %Removed the excess from the limits
    if evcharge_t(1,a)>=limit
        removed = removed + (evcharge_t(1,a)-limit);
        evcharge_t(1,a)=limit;
        lim(1,a)=1;
    end
end

%% If There Are Excess
    %which is least likely to occur because of the flattening of the
    %charging time and BPSO optimization
evcharge_t
if removed>0

    app_and_ev = [appenergy(1,1:2) appenergy(1,15:24)]+evcharge_t; %ev charge + app energy, para macheck pa rin yung peak ng usage
    [x_s,x_s_i]=sort(app_and_ev,'ascend'); %ascending order 6pm to 6am, sort from lowest to peak pero 6pm to 6am lang
    x_lay = diff([x_s x_s(1,12)]) %rate of stairs, difference nung sortation
    
    ex_lim = zeros(1,12);
    for a=1:12
        ex_lim(a)=lim(x_s_i(a));
    end
    ex_lim
    sum(ex_lim(1,1:a),2)
    for a=1:12 % for every x_layer
        a
        % If may ascending stair, and yung idadagdag is mas mababa sa removed (yung binawas)
        if (x_lay(1,a)>0) && (x_lay(1,a)*(a-(sum(ex_lim(1,1:a),2)))<removed && a>(sum(ex_lim(1,1:a),2))) 
            for k=1:a %for every element at that level (stair)
                %If di malilimit, at di limited: add yung layer, bawas sa
                %removed
                if x_lay(1,a)+evcharge_t(1,x_s_i(1,k))<limit && not(ex_lim(1,k)) 
                    evcharge_t(1,x_s_i(1,k))=evcharge_t(1,x_s_i(1,k))+x_lay(1,a) %add yung x_layer(1,a)
                    removed=removed-x_lay(1,a)
                    1
                %If malilimit, at di limited: gawing limit, bawas sa removed, 
                elseif x_lay(1,a)+evcharge_t(1,x_s_i(1,k))>limit && not(ex_lim(1,k))
                    removed=removed-(limit-evcharge_t(1,x_s_i(1,k)))
                    evcharge_t(1,x_s_i(1,k))=limit; %gawing limited yung ev charge na yon
                    ex_lim(1,k)=1; %gawing limited yung ev charge na yon
                    2
                end
            end
    
         %if may ascending value, and yung idadagdag is mas mataas sa removed,
         %yung removed value ang gagamitin pang add
        elseif x_lay(1,a)>0 && (x_lay(1,a)*(a-sum(ex_lim(1,k),2))) > removed
            poss = a-sum(ex_lim(1,1:a),2) %yung value distribution ng removed, sa hindi pa limited na items
            
            for k=1:a %for every element sa level na yon
              
                if removed <=0 
                    %SHOULD NOT HAPPEN <0, only =0
                    break
                %if removed is 0 pa rin, and yung idagdag ay hindi maglimit,
                %add yung value distributed removed/poss
                elseif removed/poss + evcharge_t(1,x_s_i(1,k)) < limit && not(ex_lim(1,k)) 
                    evcharge_t(1,x_s_i(1,k))=evcharge_t(1,x_s_i(1,k))+removed/poss
                    removed=removed-removed/poss
                    3
                %if malilimit: maging limit at ibawas
                elseif removed/poss + evcharge_t(1,x_s_i(1,k)) > limit && not(ex_lim(1,k)) %if sya malilimit, or di malilimit
                    removed=removed-(limit-evcharge_t(1,x_s_i(1,k)))
                    evcharge_t(1,x_s_i(1,k))=limit
                    4
                end
            end
        end
    end
end


%% Plotting
evcharge_t = [evcharge_t(1,1:2) zeros(1,12) evcharge_t(1,3:12)]
sum(evcharge_t,2)

x = linspace(1,24,24);
t = tiledlayout(3,1);
nexttile
bar(x,appenergy)
title('Appliance')
nexttile
bar(x,evcharge_t)
title('Charging')
nexttile
bar(x,[appenergy;evcharge_t],'stacked')
title('Stacked')
