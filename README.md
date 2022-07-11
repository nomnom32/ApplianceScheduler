# BPSO-based Appliance Scheduler
%% SCHEDULER

MainCode_Test2.m runs the import of data input (UserInput_Test2.m) with modified main code and objective function (objFunc.m) to accomodate EVCode Function (EVCode.m) and BatteryCodeFunction (BatteryCode.m)

1. Sensitivity Analysis Rerun: Due to not updating Solar Operation Time Code.
2. Doesn't yet incorporated running multiple household inputs. 

objFunc1 - produce fitness of an schedule
  -considers EV incorporation
  -app prio

BatteryCode.m:
- outputs the Battery charge rate, instead of state, 1x24 matrix
- battery charges when PV>total hourly wattage
- discharge when PV<total hourly wattage 

EVCode.m:
- outputs the EV charge rate, 1x24 matrix
- EV Charge when < peak, and battery charge rate limit.
- Charge rate is flat out.

%% CITY GENERATION

probability_data.m:
- contains all raw data from processed survey tables excel sheet in matrix form

Converter.m:
- converter for probability data into input for the BPSO main code

final.m:
- function found in Converter.m that generates the Appliance matrix of every household which contain the relevant factors such as
- Appliance Ownership, Usage, Duration, Start time, End time, Appliance Priority

CitywithEVPVESS.m
- generates the total energy demand of the user input across 24 hours while considering electric vehicle usage, solar power, and energy storage system usage in different combinations
- the combinations are as follows:
- EV only, PV only, ESS only, Appliances only (no EV, no PV, no ESS), EV + Appliances, EV + PV + ESS + Appliances

%% USER INPUTS
- contains the raw appliance matrices of the household from Household 1-14061 separated into 20 files
