%% TEST_ACK_VALUE_INSTRUMENTATION Passive confirmation-event contract.

startup;

base=applyExp14ECell('n5-csma',16018999);
base.swarm.T=2.0;
base.shared.evalStart=0;
trace=generateSharedMediumTrace(base);
R=exp14eRegistry();

selectedOff=applyExp14EArm(base,R.arms(1));
methodSelected='mac-aware-broadcast';
outOff=simSwarmSharedMedium(selectedOff,methodSelected,trace);
assert(~outOff.ackValueLogging.enabled && isempty(outOff.ackValueLog), ...
    'ACK-value logging must default off with an empty event contract.');

selectedOn=selectedOff;
selectedOn.shared.ackValueLogging=struct( ...
    'enabled',true,'schema','ACK-VALUE-EVENT-v1');
outOn=simSwarmSharedMedium(selectedOn,methodSelected,trace);

% Passive means every physical/control/protocol outcome remains exact. Runtime
% and the new passive log itself are deliberately excluded.
assert(isequal(outOff.P,outOn.P) && isequal(outOff.V,outOn.V) && ...
    isequal(outOff.A,outOn.A) && isequaln(outOff.trueAoI,outOn.trueAoI) && ...
    isequaln(outOff.estimatedAoI,outOn.estimatedAoI), ...
    'Enabling event logging changed the plant or information trajectory.');
assert(isequal(outOff.netStats,outOn.netStats) && ...
    isequal(outOff.policy,outOn.policy) && ...
    outOff.traceHashExact==outOn.traceHashExact && ...
    outOff.channelStateHash==outOn.channelStateHash, ...
    'Enabling event logging changed physical network outcomes.');

E=outOn.ackValueLog;
assert(~isempty(E) && numel(E)==outOn.netStats.ackEntriesDelivered, ...
    'Every accepted confirmation must produce exactly one passive event.');
assert(all([E.time]>=[E.genTime]) && all([E.txEnd]<=[E.time]+1e-12), ...
    'Confirmation-event times violate generation/service ordering.');
assert(all([E.frameSender]==[E.sourceReceiver]) && ...
    all([E.seq]>=1) && all([E.bytes]>0), ...
    'Confirmation-event identities do not match the ACK transport.');
assert(all(ismember(string({E.transport}),["ack" "data"])) && ...
    any(string({E.transport})=="ack"), ...
    'Selected adaptive feedback must expose valid standalone confirmations.');

piggy=applyExp14EArm(base,R.arms(4));
piggy.shared.ackValueLogging=struct( ...
    'enabled',true,'schema','ACK-VALUE-EVENT-v1');
outPiggy=simSwarmSharedMedium(piggy,'causal-broadcast',trace);
assert(~isempty(outPiggy.ackValueLog) && ...
    all(string({outPiggy.ackValueLog.transport})=="data"), ...
    'Piggyback-only confirmation events must all travel in DATA frames.');

bad=selectedOn;
bad.shared.ackValueLogging.schema='ACK-VALUE-EVENT-v2';
rejected=false;
try
    simSwarmSharedMedium(bad,methodSelected,trace);
catch
    rejected=true;
end
assert(rejected,'Unknown ACK-value event schemas must fail at the boundary.');

fprintf(['test_ack_value_instrumentation: PASS ' ...
    '(default off, passive identity, event schema, piggyback transport)\n']);
