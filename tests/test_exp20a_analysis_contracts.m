%% TEST_EXP20A_ANALYSIS_CONTRACTS Synthetic frozen-verdict contracts.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp20a_analysis_contracts\n');
fprintf('============================================================\n\n');

R=exp20aRegistry();
tmp=tempname; mkdir(tmp);
cleanup=onCleanup(@() rmdir(tmp,'s'));
F=syntheticFormation(R);
N=syntheticNative(R,6);
writetable(table("synthetic_contract",1,"all structural gates pass", ...
    'VariableNames',{'gate','passed','detail'}), ...
    fullfile(tmp,'integrity_gates.csv'));

writeInputs(tmp,F,N);
A=analyzeExp20AResults(tmp);
positive=strcmp(A.verdict.status,'INFORMATION_STRUCTURE_GAP_SUPPORTED') && ...
    A.verdict.nativeGapSupportedCells==6 && A.verdict.exp20bPermitted;

P=F;
idx=string(P.arm)=='periodic-tdma-p6p25' & ...
    string(P.scenario)==string(R.primaryBoundaryCell);
P.RMSE(idx)=0.80; P.CHARGED_OFFERED_UTIL(idx)=0.80; P.SAFEFAIL(idx)=0;
writeInputs(tmp,P,N);
B=analyzeExp20AResults(tmp);
prior=strcmp(B.verdict.status,'PRIOR_ART_EXPLAINS_FRONTIER') && ...
    B.verdict.priorArtExplainsFrontier && ~B.verdict.exp20bPermitted;

N0=syntheticNative(R,0);
writeInputs(tmp,F,N0);
C=analyzeExp20AResults(tmp);
noGap=strcmp(C.verdict.status,'NO_PRIVATE_FEEDBACK_GAP') && ...
    C.verdict.nativeGapSupportedCells==0 && ~C.verdict.exp20bPermitted;

N3=syntheticNative(R,3);
writeInputs(tmp,F,N3);
D=analyzeExp20AResults(tmp);
inconclusive=strcmp(D.verdict.status,'INCONCLUSIVE_NO_CANDIDATE') && ...
    D.verdict.nativeGapSupportedCells==3 && ~D.verdict.exp20bPermitted;

E=F;
private=ismember(string(E.arm), ...
    ["chen-age-gain-private","delta-private-projection"]);
E.RMSE(private)=0.99;
E.CHARGED_OFFERED_UTIL(private)=0.99;
E.SAFEFAIL(private)=0;
writeInputs(tmp,E,N);
Q=analyzeExp20AResults(tmp);
matched=strcmp(Q.verdict.status,'PRIOR_ART_EXPLAINS_FRONTIER') && ...
    Q.verdict.existingPrivateBaselineMatches && ~Q.verdict.exp20bPermitted;

checks={positive,'all five gates alone permit EXP20B'; ...
    prior,'periodic dominance stops candidate creation'; ...
    noGap,'zero supported native cells closes the information gap'; ...
    inconclusive,'three of six native cells remains inconclusive'; ...
    matched,'an existing private baseline match stops candidate creation'};
flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp20a_analysis_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp20a_analysis_contracts: PASS (%d checks)\n',numel(flags));


function F=syntheticFormation(R)

n=R.expectedFormationRuns;
rows=repmat(exp20aFormationEmptyRow(),n,1);
q=0;
for seed=R.formationSeeds'
    for cellIndex=1:numel(R.cells)
        c=R.cells(cellIndex);
        for armIndex=1:numel(R.formationArms)
            a=R.formationArms(armIndex);
            q=q+1;
            row=exp20aFormationEmptyRow();
            row.seed=seed;
            row.scenario=c.id;
            row.scenarioLabel=c.label;
            row.originalMacType=c.macType;
            row.arm=a.id;
            row.methodLabel=a.label;
            row.armKind=a.kind;
            row.schedulerMode=a.schedulerMode;
            row.RMSE=1.20;
            row.DIVERGED=0;
            row.SAFEFAIL=5;
            row.CHARGED_OFFERED_UTIL=1.20;
            row.OFFERED_UTIL=1.10;
            row.MEAN_TRUE_AOI=0.20;
            row.ENDOGENOUS_COLLISION_FRAMES=2;
            row.PUBLIC_FEEDBACK_AIRTIME=0;
            row.DTSA_DISAGREEMENT_FRACTION=0;
            if strcmp(a.id,'frame-piggyback')
                row.RMSE=1.00;
                row.CHARGED_OFFERED_UTIL=1.00;
                row.OFFERED_UTIL=1.00;
            elseif strcmp(a.id,'delta-public-projection')
                row.RMSE=0.80;
                row.CHARGED_OFFERED_UTIL=0.80;
            elseif strcmp(a.id,'delta-private-projection')
                row.RMSE=1.10;
                row.CHARGED_OFFERED_UTIL=1.10;
            end
            rows(q)=row;
        end
    end
end
F=struct2table(rows);

end


function N=syntheticNative(R,nSupported)

n=R.expectedNativeRuns;
rows=repmat(exp20aNativeEmptyRow(),n,1);
rhoHalfIndex=0;
supportByCell=false(numel(R.nativeCells),1);
for cellIndex=1:numel(R.nativeCells)
    if abs(R.nativeCells(cellIndex).rho-0.5)<eps
        rhoHalfIndex=rhoHalfIndex+1;
        supportByCell(cellIndex)=rhoHalfIndex<=nSupported;
    end
end
q=0;
for seed=R.nativeSeeds'
    for cellIndex=1:numel(R.nativeCells)
        c=R.nativeCells(cellIndex);
        for armIndex=1:numel(R.nativeArms)
            q=q+1;
            row=exp20aNativeEmptyRow();
            row.seed=seed;
            row.cell=c.id;
            row.arm=R.nativeArms{armIndex};
            row.N=c.N;
            row.rho=c.rho;
            row.lambda=c.rho/c.N;
            row.epsilon=c.epsilon;
            row.MEAN_AOII=1.0;
            if strcmp(row.arm,'delta-private-delayed') && ...
                    supportByCell(cellIndex)
                row.MEAN_AOII=1.20;
            end
            rows(q)=row;
        end
    end
end
N=struct2table(rows);

end


function writeInputs(path,F,N)

writetable(F,fullfile(path,'formation_tidy.csv'));
writetable(N,fullfile(path,'native_tidy.csv'));

end
