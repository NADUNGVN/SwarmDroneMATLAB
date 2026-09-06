function S=posthocExp20ANativeDistributionAudit(runDir)
%POSTHOCEXP20ANATIVEDISTRIBUTIONAUDIT Describe DELTA heavy-tail outcomes.
%
% This audit is explicitly post hoc and descriptive. It does not alter the
% registered EXP20A decision rule or development verdict.

R=exp20aRegistry();
T=readtable(fullfile(runDir,'native_tidy.csv'),'TextType','string');
cells=R.nativeCells;
S=table('Size',[numel(cells) 23], ...
    'VariableTypes',[{'string'},repmat({'double'},1,22)], ...
    'VariableNames',{'cell','N','rho','epsilon','nPairs', ...
    'publicMean','publicMedian','publicP90','publicP95','publicMax', ...
    'publicTailGt100','privateMean','privateMedian','privateP90', ...
    'privateP95','privateMax','privateTailGt100', ...
    'privateWorseFraction','pairedRelativeMean','pairedRelativeMedian', ...
    'pairedRelativeP90','pairedRelativeP95','registeredGapCell'});

for k=1:numel(cells)
    c=cells(k);
    P=sortrows(T(string(T.cell)==string(c.id) & ...
        string(T.arm)=='delta-public',:),'seed');
    Q=sortrows(T(string(T.cell)==string(c.id) & ...
        string(T.arm)=='delta-private-delayed',:),'seed');
    if height(P)~=numel(R.nativeSeeds) || ~isequal(P.seed,Q.seed)
        error('posthocExp20ANativeDistributionAudit: pairing failed.');
    end
    p=P.MEAN_AOII; q=Q.MEAN_AOII;
    relative=(q-p)./max(p,eps);
    S.cell(k)=string(c.id);
    S.N(k)=c.N; S.rho(k)=c.rho; S.epsilon(k)=c.epsilon;
    S.nPairs(k)=numel(p);
    S.publicMean(k)=mean(p); S.publicMedian(k)=median(p);
    S.publicP90(k)=percentile(p,90); S.publicP95(k)=percentile(p,95);
    S.publicMax(k)=max(p); S.publicTailGt100(k)=nnz(p>100);
    S.privateMean(k)=mean(q); S.privateMedian(k)=median(q);
    S.privateP90(k)=percentile(q,90); S.privateP95(k)=percentile(q,95);
    S.privateMax(k)=max(q); S.privateTailGt100(k)=nnz(q>100);
    S.privateWorseFraction(k)=mean(q>p);
    S.pairedRelativeMean(k)=mean(relative);
    S.pairedRelativeMedian(k)=median(relative);
    S.pairedRelativeP90(k)=percentile(relative,90);
    S.pairedRelativeP95(k)=percentile(relative,95);
    S.registeredGapCell(k)=double(abs(c.rho-0.5)<eps);
end

writetable(S,fullfile(runDir,'native_distribution_audit_posthoc.csv'));
record=struct('status','POSTHOC_DESCRIPTIVE_ONLY', ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'changesRegisteredDecision',false, ...
    'reason',['Public DELTA has a hot-start/CR heavy tail; report central ' ...
    'tendency, tail frequency and paired direction alongside the registered ' ...
    'paired-relative-mean gate.']);
writeJson(fullfile(runDir,'native_distribution_audit_posthoc.json'),record);

end


function y=percentile(x,p)

x=sort(x(isfinite(x)));
if isempty(x), y=NaN; return; end
if isscalar(x), y=x; return; end
r=1+(numel(x)-1)*p/100;
lo=floor(r); hi=ceil(r); w=r-lo;
y=(1-w)*x(lo)+w*x(hi);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('posthoc EXP20A audit: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
