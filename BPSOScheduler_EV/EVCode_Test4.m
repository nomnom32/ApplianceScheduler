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
limit=300;

%e-trike
ev_rating = 3300;
%https://gulfnews.com/world/asia/philippines/900-e-trikes-deployed-in-manila-1.2230670

%e-car
% ev_rating = 34000;
%https://evcompare.io/cars/changan/changan-ev360/

evcharge_t = zeros(1,12);
HighThresh = 0.8*ev_rating-0.2*ev_rating;

[sorted,sorted_index]=sort([imbalance(1,1:2) imbalance(1,15:24)],'descend') %sort 6pm to 6am in descending order
layer = abs(diff([sorted 0]))

ctr=12; 

%% Working Code. Default. No limit
% for a=1:12 % 
%     if layer(1,a)>0 && (layer(1,a)*a)+sum(transpose(evcharge_t),1)<HighThresh
%         for k=1:a % from 1 to current stair
%             evcharge_t(1,sorted_index(1,k))= evcharge_t(1,sorted_index(1,k))+layer(1,a);
%         end
%     elseif layer(1,a)>0 && (layer(1,a)*a)+sum(transpose(evcharge_t),1)>HighThresh
%         excess=HighThresh-sum(transpose(evcharge_t),1);
%         ctr=a;
%         break
%     end
% end 

% for a=1:ctr
%     evcharge_t(1,sorted_index(1,a))= evcharge_t(1,sorted_index(1,a))+excess/ctr;
% end

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
% 
% excess1=0;
% 
% for a=1:12
%     if evcharge_t(1,a)>=limit
%         excess1 = excess1 + (evcharge_t(1,a)-limit);
%         evcharge_t(1,a)=limit;
%     end
% end
% 
% evcharge_t = [evcharge_t(1,1:2) zeros(1,12) evcharge_t(1,3:12)];
% app_ev = appenergy+evcharge_t;
% [x_sorted,x_sorted_index]=sort([app_ev(1,1:2) app_ev(1,15:24)],'ascend');
% x_layer = abs(diff([x_sorted(1,1) x_sorted]));
% 
% for a=1:12 % 
%     if x_layer(1,a)>0 && (x_layer(1,a)*a)>excess1
%         for k=1:a % from 1 to current stair
%             evcharge_t(1,sorted_index(1,k))= evcharge_t(1,sorted_index(1,k))+x_layer(1,a);
%         end
%     elseif layer(1,a)>0 && (layer(1,a)*a)+sum(transpose(evcharge_t),1)<x
%         excess=HighThresh-sum(transpose(evcharge_t),1);
%         ctr=a;
%         break
%     end
% end 
% 

% 
% evcharge_t
% excess1
% 
% for a=1:12
%     if evcharge_t(1,a)<limit && excess1>=(limit-evcharge_t(1,a))
%         excess1=excess1-(limit-evcharge_t(1,a))
%         evcharge_t(1,a)=limit
%     elseif evcharge_t(1,a)<limit && excess1<=(limit-evcharge_t(1,a))
%         evcharge_t(1,a)=evcharge_t(1,a)+excess1;
%         excess1=0;
%     end
% end
% 


%% Plotting
evcharge_t = [evcharge_t(1,1:2) zeros(1,12) evcharge_t(1,3:12)]
sum(transpose(evcharge_t),1)

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
