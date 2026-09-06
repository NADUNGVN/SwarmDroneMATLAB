%% TEST_STANDALONE_ACK_VALUE_CERTIFICATE Exact identity and lead bounds.

startup;

weights=struct('airtimeCostPerSecond',1,'controlCostPerUnit',2, ...
    'collisionCostPerEvent',0.1);

% N5-CSMA-like decomposition: DATA savings cover only half the direct ACK
% airtime, while control loss is also worse. Piggyback is Pareto-preferred.
n5=struct('standaloneAckAirtimeSeconds',0.12, ...
    'dataAirtimeSavedSeconds',0.06,'controlLossSaved',-0.01, ...
    'collisionEventsSaved',3,'weights',weights);
c5=standaloneAckValueCertificate(n5);
assert(abs(c5.offeredAirtimeMarginSeconds+0.06)<1e-12);
assert(strcmp(c5.realizedContinuousStatus, ...
    'PIGGYBACK_PARETO_CONTINUOUS'));
assert(strcmp(c5.predictiveStatus,'NOT_EVALUATED'));
expected=-0.06+2*(-0.01)+0.1*3;
assert(abs(c5.weightedNetValue-expected)<1e-12);

% ALOHA-like decomposition: avoided DATA airtime exceeds ACK cost and the
% control loss also falls.
aloha=n5;
aloha.standaloneAckAirtimeSeconds=0.4;
aloha.dataAirtimeSavedSeconds=1.0;
aloha.controlLossSaved=0.02;
ca=standaloneAckValueCertificate(aloha);
assert(abs(ca.offeredAirtimeMarginSeconds-0.6)<1e-12);
assert(strcmp(ca.realizedContinuousStatus, ...
    'ACK_ASSISTED_PARETO_CONTINUOUS'));

% A short unique-information lead cannot repay the ACK even at the declared
% upper information-value rate.
airOnly=n5;
airOnly.weights=struct('airtimeCostPerSecond',1, ...
    'controlCostPerUnit',0,'collisionCostPerEvent',0);
discard=struct('expectedUniqueLeadSeconds',0.01, ...
    'informationValueRateLower',0,'informationValueRateUpper',2, ...
    'externalityCostLower',0.01,'externalityCostUpper',0.02);
cd=standaloneAckValueCertificate(airOnly,discard);
assert(cd.certifiedDiscard && ~cd.certifiedTransmit);
assert(strcmp(cd.predictiveStatus,'CERTIFIED_DISCARD'));

% A lower benefit bound above the upper cost certifies transmission.
transmit=discard;
transmit.expectedUniqueLeadSeconds=0.2;
transmit.informationValueRateLower=1;
transmit.informationValueRateUpper=2;
ct=standaloneAckValueCertificate(airOnly,transmit);
assert(ct.certifiedTransmit && ~ct.certifiedDiscard);
assert(strcmp(ct.predictiveStatus,'CERTIFIED_TRANSMIT'));

% Overlapping value/cost bounds must remain inconclusive.
uncertain=discard;
uncertain.expectedUniqueLeadSeconds=0.1;
uncertain.informationValueRateLower=0.5;
uncertain.informationValueRateUpper=2;
cu=standaloneAckValueCertificate(airOnly,uncertain);
assert(~cu.certifiedTransmit && ~cu.certifiedDiscard);
assert(strcmp(cu.predictiveStatus,'INCONCLUSIVE'));

bad=n5;
bad.standaloneAckAirtimeSeconds=-1;
rejected=false;
try
    standaloneAckValueCertificate(bad);
catch
    rejected=true;
end
assert(rejected,'Negative direct ACK airtime must fail at the boundary.');

fprintf(['test_standalone_ack_value_certificate: PASS ' ...
    '(identity, Pareto direction, lead-time bounds)\n']);
