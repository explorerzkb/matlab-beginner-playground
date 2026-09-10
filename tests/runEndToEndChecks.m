function runEndToEndChecks()
%RUNENDTOENDCHECKS Real key-input journeys, never position/state shortcuts.
runGameplayJourney('upper',0,false);
runGameplayJourney('lower',0,false);
runGameplayJourney('upper',30,true);
runGameplayJourney('lower',90,true);
fprintf('ALL FOUR INPUT JOURNEYS PASSED\n');
end
