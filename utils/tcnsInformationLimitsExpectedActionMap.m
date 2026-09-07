function E = tcnsInformationLimitsExpectedActionMap( ...
    model,linkClass,receiver,sender,currentSource,belief)
%TCNSINFORMATIONLIMITSEXPECTEDACTIONMAP Belief-weighted exact Gate-3 value.
%
% Candidate-specific quadratic values are averaged.  This deliberately
% does not evaluate the nonlinear value at an expected receiver state.

requiredSource = {'pos','vel'};
for q = 1:numel(requiredSource)
    if ~isfield(currentSource,requiredSource{q})
        error('tcnsInformationLimitsExpectedActionMap:Source', ...
            'currentSource.%s is required.',requiredSource{q});
    end
end
probability = double(belief.probability(:));
if any(~isfinite(probability)) || any(probability<0) || ...
        abs(sum(probability)-1)>1e-12
    error('tcnsInformationLimitsExpectedActionMap:Belief', ...
        'Belief probabilities must be nonnegative and sum to one.');
end
n = numel(probability);
if size(belief.candidatePos,1)~=n || ...
        size(belief.candidateVel,1)~=n
    error('tcnsInformationLimitsExpectedActionMap:Belief', ...
        'Belief candidate arrays and probability disagree.');
end

linkClass = lower(string(linkClass));
fi = find(model.followers==receiver,1);
if isempty(fi)
    error('tcnsInformationLimitsExpectedActionMap:Receiver', ...
        'The receiver must be a Gate-3 follower.');
end
switch linkClass
    case "ordinary"
        moments = tcnsAckFreeResidualMoments( ...
            currentSource.pos,currentSource.vel,[],belief, ...
            model.certificate.degreeScale(fi)*model.config.Kp, ...
            model.certificate.degreeScale(fi)*model.config.Kv,0);
    case "pinned-leader"
        if ~isfield(currentSource,'acc')
            error('tcnsInformationLimitsExpectedActionMap:Source', ...
                'currentSource.acc is required for pinned-leader data.');
        end
        moments = tcnsAckFreeResidualMoments( ...
            currentSource.pos,currentSource.vel,currentSource.acc,belief, ...
            model.config.KpLeader,model.config.KvLeader,1);
    otherwise
        error('tcnsInformationLimitsExpectedActionMap:Class', ...
            'linkClass must be ordinary or pinned-leader.');
end

maps = cell(n,1);
for s = 1:n
    payload.pos = belief.candidatePos(s,:);
    payload.vel = belief.candidateVel(s,:);
    if linkClass=="pinned-leader"
        payload.acc = belief.candidateAcc(s,:);
    end
    maps{s} = tcnsInformationLimitsActionMap( ...
        model,linkClass,receiver,sender, ...
        moments.candidateCorrection(s,:),payload);
end
keepIndex = maps{1}.keepIndex;
ell = zeros(numel(keepIndex),1);
constant = 0;
valueCoefficient = zeros(numel(keepIndex),1);
valueConstant = 0;
expectedEnergy = 0;
for s = 1:n
    if ~isequal(maps{s}.keepIndex,keepIndex)
        error('tcnsInformationLimitsExpectedActionMap:Coordinates', ...
            'Candidate hypotheses do not share free coordinates.');
    end
    ell = ell+probability(s)*maps{s}.crossTermCoefficient;
    constant = constant+probability(s)*maps{s}.crossTermConstant;
    valueCoefficient = valueCoefficient+ ...
        probability(s)*maps{s}.valueCoefficient;
    valueConstant = valueConstant+probability(s)*maps{s}.valueConstant;
    expectedEnergy = expectedEnergy+ ...
        probability(s)*maps{s}.actionResponseEnergy;
end

E.linkClass = linkClass;
E.receiver = receiver;
E.sender = sender;
E.probability = probability;
E.candidateMaps = maps;
E.keepIndex = keepIndex;
E.expectedCrossTermCoefficient = ell;
E.expectedCrossTermConstant = constant;
E.expectedValueCoefficient = valueCoefficient;
E.expectedValueConstant = valueConstant;
E.expectedActionResponseEnergy = expectedEnergy;
E.residualMoments = moments;
E.averagesCandidateQuadratics = true;
E.usesValueAtExpectedMemory = false;

end
