clear
tic
%% IMPORT INPUT DATA
data=load('UserInput_Test1.m');
price_code=1;%1=M-S(dry),2=M-S(wet),3=Sun(dry),4=Sun(wet)
user_budget=45;
peak_threshold=1200;


%Parsing input data
[row_len,col_len]=size(data);

%counts number of appliances
n=max(data(:,1));

%counts number of usage per appliance
app_usage=zeros(n,1);
% TTR EDIT
for a = 1:n
temp = find(data(:,1)==a); %find which is equal to a at column 1, that is temp, ilagay nya dito yung parehas na mga A
app_usage(a) = size(temp,1); % counts the number of row of temp
end
% TTR EDIT
mu=max(app_usage); % finds the maximum of appliance usage. sa case ng userinput24, 2 ito dahil ng data row input 4 and 5
app_dur=zeros(n,mu); %app durations data, per app and per usage
app_tA=zeros(n,mu); % app usage starting times
app_tB=zeros(n,mu); %app usage finishing times
app_TW=zeros(n,1); % I don't know what is this, Wattage? per appliances?

%total wattage, duration, tA, tB
use=0;
%rank = 15 %for prioritization factor
for a=1:row_len
    %for priority factor, in terms of ranking, we need to find how to
    %arrange them. I'm thinking this method but it has O(n^2) i think,  
    app_TW(data(a,1),1)=data(a,2); %getting wattage from each data input, may redundancy ata
    use=use+1; %kapag doble ata ang use nito %basta puro pang input lang to
    if use<=app_usage(data(a,1))
        app_dur(data(a,1),use)=data(a,3); % kapag may more than 1 ang usage kaya may use variable
        app_tA(data(a,1),use)=data(a,4);
        app_tB(data(a,1),use)=data(a,5);
        if use==app_usage(data(a,1))
            use=0;
            end
    end
end 


%% INITIALIZATION OF PARAMETERS
N=250; %Number of particles
t=24; %length of variables/time slots
dim=n*t; %dimension of a particle in a single row
price = tou_rates24(t); % need to study this tou_rates, may error sa code, walang &&
c1=9;
c2=9;
v_max=6;
validctr=0; %% PSO PROGRAM
max_iteration=500;
simulations=1;
checkd=zeros(1,simulations);%number of appliances with right duration in one simulation
checki=zeros(1,simulations);%number of appliances with right interruption in one simulation
minfit_per_ite=zeros(max_iteration,simulations);
sol_per_run=zeros(simulations,dim);

for run=1:simulations
itectr=0;
%Allocations
sig=zeros(N,dim); %particle x appliance*time 24*9 column, 250 rows
solution=zeros(n,t); %proposed solution of 0 1
fitness=zeros(N,1); % fitnes?? hmmm 250 rows
pbest=ones(N,dim); % personal best same size with sig
gbest=ones(1,dim); % global best, only 1 solution
pbest_fitness=ones(N,1); %fitness per particle
%Initial position and velocity
sched=round(rand(N,dim));%initial position na random lang, round? siguro dahil 0 to 1 ang values
v=round(-v_max+(rand(N,dim)*(2*v_max)));%initial velocity
%Start of PSO Algorithm
while itectr<max_iteration
itectr=itectr+1;
w=1;%inertia weight
%Evaluation of Fitness
for a=1:N
for b=1:n
solution(b,:)=sched(a,(b-1)*t+1:b*t); %rearranges every row(particle) of swarm to its ownmatrix 
end
fitness(a,itectr)=objFunc(n, t, solution, price(price_code,:), app_usage, app_TW, app_dur, app_tA, app_tB, user_budget, peak_threshold, mu);
end
%Updating Pbest
for a=1:N
if (itectr==1 || fitness(a,itectr) < pbest_fitness(a,1))
pbest_fitness(a,1)=fitness(a,itectr);
pbest(a,:)=sched(a,:);
end
end
%Updating Gbest
[fmin, fmin_index]=min(pbest_fitness); %finds best particle
minfit_per_ite(itectr,run)=fmin; %stores gbest value per iteration on every run
if (itectr==1 || fmin < gbest_fitness)
gbest_fitness=fmin;
gbest=pbest(fmin_index,:);
end %Updating Velocity
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
% Sig function and Updating Position
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
sol_per_run(run,:)=gbest;
%Constructs the matrix of the latest global best
for a=1:n
solution(a,:)=gbest(1,(a-1)*t+1:a*t);
on_times=sum(diff([0 solution(a,:)])==1);
if sum(solution(a,:))==sum(app_dur(a,:))
checkd(1,run)=checkd(1,run)+1;
end
if on_times==app_usage(a)
checki(1,run)=checki(1,run)+1;  
end
end
%Checks if duration of operation and on times is met to be VALID!
if (checkd(1,run)==n &&checki(1,run)==n)
validctr=validctr+1;
end 
end
%prints fittest solution
%note: sometimes fittest solution is not valid
[fittest, fittest_index]=min(minfit_per_ite(max_iteration,:));
for a=1:n
solution(a,:)=sol_per_run(fittest_index,(a-1)*t+1:a*t);
end
end
toc
