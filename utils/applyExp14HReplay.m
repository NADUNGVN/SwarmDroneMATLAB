function cfg=applyExp14HReplay(cfg,mode,targetOrdinal,localHorizon)
%APPLYEXP14HREPLAY Apply the unchanged EXP14G branch intervention to N20.

cfg=applyExp14GReplay(cfg,mode,targetOrdinal,localHorizon);
cfg.exp14h.replayMode=lower(strtrim(char(mode)));
cfg.exp14h.targetOrdinal=targetOrdinal;
cfg.exp14h.realizedHorizon=localHorizon;

end
