function sc = exp10Scenarios()
%EXP10SCENARIOS The three network scenarios, unchanged since EXP05.
%
% Held in one function so EXP10A, EXP10B and the v1 validation entry
% point cannot drift apart on the values, and so a reader can see that
% they are the locked ones rather than new numbers chosen for EXP10.

sc.names = {'Clean'; 'Moderate'; 'Stressed'};

sc.loss  = [0.00; 0.20; 0.40];
sc.delay = [0.00; 0.08; 0.12];

sc.CLEAN    = 1;
sc.MODERATE = 2;
sc.STRESSED = 3;

end
