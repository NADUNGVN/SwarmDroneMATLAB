% TEST_ELCS_CUMULATIVE_RECEIPT_CONTRACTS Same-sequence receipt behavior.
startup;
fprintf('\n============================================================\n');
fprintf('test_elcs_cumulative_receipt_contracts\n');
fprintf('============================================================\n\n');

checks=0;
R=exp23hCumulativeReceiptRegistry();
cellInfo=R.cells(1);
zero=R.conditions(1);
legacy=R.modes(1); cumulative=R.modes(2);
A=runExp23hCumulativeReceiptCell(16070901,cellInfo,zero,legacy,R);
B=runExp23hCumulativeReceiptCell(16070901,cellInfo,zero,cumulative,R);
assert(A.CONTROL_ATTEMPTS==B.CONTROL_ATTEMPTS && ...
    A.CONTROL_BYTES==B.CONTROL_BYTES && ...
    A.SCHEDULED_ATTEMPTS==B.SCHEDULED_ATTEMPTS && ...
    A.FALLBACK_ATTEMPTS==B.FALLBACK_ATTEMPTS && ...
    A.FINAL_ALL_CERTIFIED==1 && B.FINAL_ALL_CERTIFIED==1);
fprintf('    ok   cumulative mode is effort-equivalent in zero loss\n');
checks=checks+1;

condition=R.conditions(strcmp({R.conditions.id},R.backgroundCondition));
A=runExp23hCumulativeReceiptCell(16070902,cellInfo,condition,legacy,R);
B=runExp23hCumulativeReceiptCell(16070902,cellInfo,condition,cumulative,R);
assert(B.CONTROL_ATTEMPTS<A.CONTROL_ATTEMPTS && ...
    B.CONTROL_BYTES<A.CONTROL_BYTES && B.FINAL_ALL_CERTIFIED==1 && ...
    B.FALSE_VALID_EDGE_FRAMES==0 && B.SCHEDULED_COLLISION_FRAMES==0 && ...
    B.CLAIM_TRANSACTION_STARTS<B.CLAIM_ATTEMPTS);
fprintf('    ok   cumulative receipts reduce fragmented-load retry amplification\n');
checks=checks+1;

condition=R.conditions(strcmp({R.conditions.id},R.blackoutCondition));
B=runExp23hCumulativeReceiptCell(16070903,cellInfo,condition,cumulative,R);
assert(B.FINAL_ALL_CERTIFIED==0 && B.FALSE_VALID_EDGE_FRAMES==0 && ...
    B.SCHEDULED_COLLISION_FRAMES==0 && ...
    B.FINAL_OPEN_CLAIM_TRANSACTIONS>0 && ...
    B.CONTROL_ATTEMPT_BOUND_RATIO<=1 && B.CONTROL_BYTE_BOUND_RATIO<=1);
fprintf('    ok   permanent RESPONSE blackout remains fail-silent and bounded\n');
checks=checks+1;

fprintf('\ntest_elcs_cumulative_receipt_contracts: PASS (%d checks)\n',checks);
