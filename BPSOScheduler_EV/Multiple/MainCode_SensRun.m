clear
tic
%% IMPORT INPUT DATA
data=load('UserInput_Test_Ave.m');
price_code=1;%1=M-S(dry),2=M-S(wet),3=Sun(dry),4=Sun(wet)
price = tou_rates24(24); %Time of Use Rates

%Parsing input data
[row_len,col_len]=size(data);
peak_threshold=data(1,4);
total_energy=data(1,5);
user_budget=data(1,6);

% Counts the number of type of appliances
n=0;
LA = zeros(15,1);
for i=1:row_len 
    if (data(i,1)>0)&&(data(i,1)<98)&&(not(ismember(data(i,1),LA)))
        n=n+1;
        LA(n)=data(i,1);
    elseif(data(i,1)==98)
        batt_own=data(i,2);
        batt_int_ch=data(i,3);
    elseif(data(i,1)==99)
        ev_own=data(i,2);
        ev_int_ch=data(i,3);
    elseif(data(i,1)==100)
        solar_own=data(i,2);
    end
end

%Battery Sizing
batt = 1020; %batt size for https://www.rollsbattery.com/battery/12-fs-24/ 20 Hour Rate, 
batt_size = batt;

batt_ctr = 1;
while(batt_size<total_energy)
    batt_ctr=batt_ctr+1;
    batt_size = batt*batt_ctr;
end

%Solar Panel Operation %Assume constant for all households. 10 am to 3 pm
PV = zeros(24,1);
for a=1:24
    if ((a>=7)&&(a<=11))
        PV(a,1) = 320;
    end
end

PV=PV*solar_own; %PV output*no. of PV

% counts number of usage per appliance
app_usage=zeros(n,1);
for a = 1:LA(n,1)
    temp = find(data(:,1)==a); %find p
    pos = find(LA(:,1)==a);
    app_usage(pos) = size(temp,1); 
end

%Wattage Rating, Duration, Start Time, End Time, Rank 
mu=max(app_usage); 
app_TW=zeros(n,1); % Appliance Wattage Ratings
app_dur=zeros(n,mu); %Durations
app_tA=zeros(n,mu); %Start Time
app_tB=zeros(n,mu); %End Time 
app_R=zeros(n,1); % Appliance Rank


use=1;
for a=1:row_len
    if (data(a,1)>0)&&(data(a,1)<98)
        pos=find(LA(:,1)==data(a,1));
        app_TW(pos,1)=data(a,2);
        app_R(pos,1)=data(a,6);
        if use<=app_usage(pos)
            app_dur(pos,use)=data(a,3);
            app_tA(pos,use)=data(a,4);
            app_tB(pos,use)=data(a,5);
            if use==app_usage(pos)
                use=1;
            elseif use<app_usage(pos)
                use=use+1;
            end
        end
    end
end 

orig_sched = zeros(n,24);

for i=1:n
    for j=1:mu
        if app_dur(i,j)==0
            orig_sched(i,j)=orig_sched(i,j);
        else 
            for k=0:app_dur(i,j)-1
                l=app_tA(i,j)+k;
                if l>24
                    l=l-24;
                end
                orig_sched(i,l)=1;
            end
        end
    end
end


orig_tempvar = orig_sched.*app_TW;
orig_appenergy = sum(orig_tempvar,1);
orig_ev_op = EVCode(orig_sched,app_TW, peak_threshold,ev_int_ch);
orig_cost = sum(transpose(orig_appenergy.*price(price_code,:)),1);

%% INITIALIZATION OF PARAMETERS
N=250; % number of particles
t=24; % 24 hours
dim=n*t; %dimension of a particle in a single row
max_iteration=500; %iteration per simulation
simulations=30; %number of simulations
  
final_cost_per_c1c2=zeros(1,20);
best_fitness_per_c1c2 = zeros(1,20);
num_of_valids_per_c1c2 = zeros(1,20);

v_max_1=6; % velocity max
v_max_2=6  ;

start_c1 = 5;
end_c1 = 10;

for v_max=v_max_1:v_max_2
    v_max
    for c1=start_c1:end_c1
        c2=c1; %
        
        validctr=0; %valid schedule counter
        checkd=zeros(1,simulations); %number of appliances with right duration in every simulation
        checki=zeros(1,simulations); %number of appliances with right interruption in every simulation
        minfit_per_ite=zeros(max_iteration,simulations); %minimum fitness per iteration
        sol_per_run=zeros(simulations,dim);
    
        for run=1:simulations
            itectr=0;
        
            %Allocations
            sig=zeros(N,dim); %particle x appliance*time  250 rows X 24*n column
            solution=zeros(n,t); %solution
            fitness=zeros(N,1); % fitness
            pbest=ones(N,dim); % personal best same size with sig
            gbest=ones(1,dim); % global best, only 1 solution
            pbest_fitness=ones(N,1); %fitness per particle
            batt_op = zeros(1,t); %battery operation
            ev_op = zeros(1,t); %ev operation
        
            %Initial position and velocity
            sched=round(rand(N,dim)); %initial 1 and 0
            v=round(-v_max+(rand(N,dim)*(2*v_max))); %initial velocity
        
            %Start of PSO Algorithm
        
            while itectr<max_iteration
                itectr=itectr+1;
                w=1; %inertia weight
                
        
        
        
                %Evaluation of Fitness
                for a=1:N
                    for b=1:n
                        solution(b,:)=sched(a,(b-1)*t+1:b*t); %solution = type of appliance * 24 hours
                    end
                    
                    %Battery and EV Operation
                    if (ev_own==1)
                        ev_op = EVCode(solution,app_TW, peak_threshold,ev_int_ch); %will update
                    end
                    if (batt_own==1)
                        batt_op = BatteryCode(solution,app_TW, PV,batt_int_ch,ev_op,total_energy,batt_ctr); %will update
                    end
                    
        
                     %With Battery and EV fitness funcion
                     fitness(a,itectr)=objFunc1(n, t, solution, price(price_code,:), app_usage, app_TW, app_dur, app_tA, app_tB, user_budget, peak_threshold, mu, ev_op, batt_op, PV);
                end
                
                %Updating Pbest of Each Particle
                for a=1:N
                    if (itectr==1 || fitness(a,itectr) < pbest_fitness(a,1))
                        pbest_fitness(a,1)=fitness(a,itectr);
                        pbest(a,:)=sched(a,:);
                    end
                end
        
                %Updating Gbest
                [fmin, fmin_index]=min(pbest_fitness); %finds best fitness, with its index
                minfit_per_ite(itectr,run)=fmin; %stores gbest value per iteration on every run
                if (itectr==1 || fmin < gbest_fitness)
                    gbest_fitness=fmin;
                    gbest=pbest(fmin_index,:);
                end 
                
                %Updating Velocity
                for a=1:N
                    for b=1:dim
                        v(a,b)=w*v(a,b)+(c1*rand()*(pbest(a,b)-sched(a,b)))+(c2*rand()*(gbest(1,b)-sched(a,b)));
                        if v(a,b)>v_max %limiting velocity within [-v_max,v_max]
                            v(a,b)=v_max;
                        elseif v(a,b)<-v_max
                            v(a,b)=-v_max;
                        end 
                    end
                end
                
                % Sig function and Updating Position based from Updated Velocity
                for a=1:N
                    for b=1:dim
                        sig(a,b)=1/(1+exp(-v(a,b)));
                        if sig(a,b)>rand()
                            sched(a,b)=1;
                        elseif sig(a,b)<rand()
                            sched(a,b)=0;
                        end
                    end
                end
            end
        
            sol_per_run(run,:)=gbest; % final global best of the 500 iterations-run
            
            for a=1:n
                solution(a,:)=gbest(1,(a-1)*t+1:a*t); % get appliance*24 hours 1 and 0 from final gbest
            end
        
            %Constructs the matrix of the latest global best
            for a=1:n
                on_times=sum(diff([0 solution(a,:)])==1);
        
                %to accomodate 4am crossing
                if (solution(a,1)==1 && solution(a,24)==1 && not(app_dur(a,1)==24))
                    on_times=on_times-1;
                end
                
                %Duration Validiity
                d=1; %duration flag
                for b=1:app_usage(a)
                    if (app_tB(a,b)<app_tA(a,b)) %to accomodate 4am crossing
                        on=sum(solution(a,app_tA(a,b):24))+sum(solution(a,1:app_tB(a,b)));
                        if on~=app_dur(a,b) %if not equal, 0 duration flag
                            d=0;
                        end
                    else
                        on=sum(solution(a,app_tA(a,b):app_tB(a,b)));
                        if on~=app_dur(a,b)
                            d=0;
                        end
                    end
                end

                if sum(solution(a,:))==sum(app_dur(a,:)) && d %checking duration validity by sum of the on time and duration time
                    checkd(1,run)=checkd(1,run)+1;
                end
                %Interruption Validity
                if on_times==app_usage(a) %checking interruption validity
                    checki(1,run)=checki(1,run)+1;  
                end
            end
        
            %Checks if duration of operation and on times is met to be VALID!
            if (checkd(1,run)==n &&checki(1,run)==n)
                validctr=validctr+1;
            end 
            % prints fittest solution
            % note: sometimes fittest solution is not valid
        end
        
        %% Final Solution
        [fittest, fittest_index]=min(minfit_per_ite(max_iteration,:)); % check minimum fitness for every run
        for a=1:n
            solution(a,:)=sol_per_run(fittest_index,(a-1)*t+1:a*t);
        end 
        
        tempvar = solution.*app_TW; % wattage per app-time slot
        appenergy = sum(tempvar,1); % wattage per time slot
        ev_op = EVCode(solution,app_TW, peak_threshold,ev_int_ch); %ev charge rate
        batt_op = BatteryCode(solution,app_TW, PV,batt_int_ch,ev_op,total_energy,batt_ctr); %battery charge rate
        
        total = appenergy+ev_op; %total energy consumption
        batt_op_charging = batt_op; %initialization of battery charge rate (walang discharge data)
        
        for k=1:24 % Find total consumption from utility
            if PV(k,1)>0
                total(1,k) = total(1,k)-PV(k,1);
            end
            if batt_op(1,k) < 0
                total(1,k) = total(1,k)+batt_op(1,k);
                batt_op_charging(1,k)=0;
            end
            if total(1,k) <0
                total(1,k)=0;
            end    
        end
        
        excess = transpose(PV)-appenergy-ev_op-batt_op_charging; %computation of PV excess energy
        for k=1:24
            if excess(1,k)<0
                excess(1,k)=0;
            end
        end
        final_cost = sum(transpose(total.*price(price_code,:)),1)-sum(transpose(excess.*price(price_code,:))); %computation of final cost for conumer
        
        toc
        
    
    fprintf('With vmax =%d, constant c1=c2=%d: final cost is %d, fitness is %d, and no. of valid schedules is %d',v_max,c1,final_cost,fittest,validctr);
    
    sum(ev_op,2);
    final_cost_per_c1c2(1,c1) = final_cost;
    best_fitness_per_c1c2(1,c1) = fittest;
    num_of_valids_per_c1c2(1,c1) = validctr;
    
    end
    
    f= final_cost_per_c1c2(1,start_c1:end_c1)
    b= best_fitness_per_c1c2(1,start_c1:end_c1)
    v= num_of_valids_per_c1c2(1,start_c1:end_c1)
end
