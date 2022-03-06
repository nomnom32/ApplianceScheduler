# ApplianceScheduler
BPSO-based appliance scheduler

%% SCHEDULER

MainCode_Test2.m runs the import of data input (UserInput_Test2.m) with changed main code and objective function (objFunc.m) to accomodate EVCode Function (EVCode.m) and BatteryCodeFunction (BatteryCode.m)
1. Does not yet consider appliance time frame crossing reset time (4am)
2. EV and Battery Incorporation updated, though constants of the PSO algorithm (c1,c2,vmax) are still not finally determined (Sensitivity Analysis)
3. Appliance Prioritization not yet updated, UserInput_Test2.m is being adjusted for this incorporation. 
4. Doesn't yet incorporated running multiple household inputs. 

objFunc1 - produce fitness of an schedule
1. EV and Battery Incorporation updated - up for deeper analysis. Testing case. (Flexibility Analysis)

EVCode.m:
- outputs the EV charge state, 1x24 matrix
- electric vehicles only charge when total hourly wattage < peak

BatteryCode.m:
- outputs the Battery charge state, 1x24 matrix
- battery charges when PV>total hourly wattage
- discharge when PV<total hourly wattage 

%% CITY GENERATION
