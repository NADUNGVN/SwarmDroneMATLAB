%% TEST_RECEIVER_LIFTED_CONTROL_ROUTING_CONTRACTS Semantic destinations.
startup;

N=5; M=struct('N',N,'initiator',1,'affectedNodes',[1;2;3], ...
    'incidentEdgeA',[2;3;4;2],'incidentEdgeB',[4;5;5;5], ...
    'incidentEdgeWitness',[4;3;1;2]);
M.oldGraph=false(N); M.oldGraph(4,2)=true; M.oldGraph(5,2)=true;

assert(isequal(find(receiverLiftedClosureControlRecipients( ...
    M,'prepare',1)),[2;3]));
assert(isequal(find(receiverLiftedClosureControlRecipients( ...
    M,'quiescent',2)),1));
assert(isequal(find(receiverLiftedClosureControlRecipients( ...
    M,'claim',2)),4));
assert(isequal(find(receiverLiftedClosureControlRecipients( ...
    M,'lock-proof',4)),1));
assert(isequal(find(receiverLiftedClosureControlRecipients( ...
    M,'response',4)),1));
assert(isequal(find(receiverLiftedClosureControlRecipients( ...
    M,'commit',1)),[2;3]));
assert(isequal(find(receiverLiftedClosureControlRecipients( ...
    M,'revoke',2)),[4;5]));

bad=false;
try
    receiverLiftedClosureControlRecipients(M,'prepare',2);
catch
    bad=true;
end
assert(bad);

fprintf('test_receiver_lifted_control_routing_contracts: PASS\n');
