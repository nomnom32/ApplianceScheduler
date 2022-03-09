# ApplianceScheduler
BPSO-based appliance scheduler

%% SCHEDULER

MainCode_Test2.m runs the import of data input (UserInput_Test2.m) with modified main code and objective function (objFunc.m) to accomodate EVCode Function (EVCode.m) and BatteryCodeFunction (BatteryCode.m)
1. Does not yet consider appliance time frame crossing reset time (4am)
2. EV and Battery Incorporation updated, though constants of the PSO algorithm (c1,c2,vmax) are still not finally determined (Sensitivity Analysis)
3. Appliance Prioritization not yet updated, UserInput_Test2.m is being adjusted for this incorporation. 
4. Doesn't yet incorporated running multiple household inputs. 

objFunc1 - produce fitness of an schedule
1. EV and Battery Incorporation updated - up for deeper analysis. Testing case. (Flexibility Analysis)

BatteryCode.m:
- outputs the Battery charge state, 1x24 matrix
- battery charges when PV>total hourly wattage
- discharge when PV<total hourly wattage 

EVCode.m:
- outputs the EV charge state, 1x24 matrix
- electric vehicles only charge when total hourly wattage < peak

%% CITY GENERATION
probability_data.m:
- contains all raw data from processed survey tables excel sheet in matrix form

Converter.m:
- converter for probability data into input for the BPSO main code
- still working on finalizing TW matrix, budget formula, splicing of time slots based on cut-off time

final.m:
- function found in Converter.m that generates the Appliance matrix which contain the relevant factors such as
- Appliance Ownership, Usage, Duration, Start time, End time, Appliance Priority
