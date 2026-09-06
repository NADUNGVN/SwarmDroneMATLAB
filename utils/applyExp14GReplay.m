function cfg=applyExp14GReplay(cfg,mode,targetOrdinal,localHorizon)
%APPLYEXP14GREPLAY Apply one closed branch intervention to an EXP14G cell.

R=exp14gRegistry();
if nargin<4 || isempty(localHorizon), localHorizon=R.localHorizon; end
mode=lower(strtrim(char(mode)));
if ~ismember(mode,R.replayModes)
    error('applyExp14GReplay: unknown replay mode "%s".',mode);
end
if ~isscalar(targetOrdinal) || ~isfinite(targetOrdinal) || ...
        targetOrdinal<1 || targetOrdinal~=floor(targetOrdinal)
    error('applyExp14GReplay: targetOrdinal must be a positive integer.');
end
if ~isscalar(localHorizon) || ~isfinite(localHorizon) || ...
        localHorizon<R.localHorizon-1e-12 || localHorizon>R.localHorizon+0.05
    error(['applyExp14GReplay: localHorizon must implement the frozen ' ...
        'next-control-tick rule.']);
end
cfg.shared.ackBranchReplay=struct( ...
    'enabled',true,'schema',R.eventSchema,'mode',mode, ...
    'targetOrdinal',targetOrdinal,'localHorizon',localHorizon);
cfg.exp14g.replayMode=mode;
cfg.exp14g.targetOrdinal=targetOrdinal;
cfg.exp14g.realizedHorizon=localHorizon;

end
