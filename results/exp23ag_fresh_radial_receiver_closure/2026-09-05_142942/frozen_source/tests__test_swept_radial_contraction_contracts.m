%% TEST_SWEPT_RADIAL_CONTRACTION_CONTRACTS One-sided geometry theorem.
startup;

p=[0 0;2 0]; b=[0 .2;.2 0]; empty=false(2);

% A large tangential error consumes no inward conflict margin.
x=[0 0;2 1];
C=evaluateSweptRadialContractionContract(p,x,empty,b,1);
assert(C.constructionPremiseSatisfied&&C.radialBoundSatisfied&& ...
    C.theoremCertified&&C.actualPhysicalSubset&& ...
    C.maximumVectorErrorRatio>1&&C.maximumRadialContractionRatio==0);

% Inward contraction within b remains outside the interference radius.
x=[0 0;1.85 0];
C=evaluateSweptRadialContractionContract(p,x,empty,b,1);
assert(C.theoremCertified&&C.actualPhysicalSubset&& ...
    abs(C.maximumRadialContractionRatio-.75)<1e-12);

% A contraction beyond the declared budget is detected; no certificate is
% issued, and the realized conflict is visible.
x=[0 0;.9 0];
C=evaluateSweptRadialContractionContract(p,x,empty,b,1);
assert(~C.radialBoundSatisfied&&~C.theoremCertified&& ...
    ~C.actualPhysicalSubset&&C.implicationExact);

% An included pair is exempt because the graph already separates senders
% that can interfere through it.
included=[false true;true false];
C=evaluateSweptRadialContractionContract(p,x,included,b,1);
assert(C.theoremCertified&&C.actualPhysicalSubset&& ...
    C.omittedPairCount==0&&C.maximumRadialContractionRatio==0);

fprintf('test_swept_radial_contraction_contracts: PASS\n');
