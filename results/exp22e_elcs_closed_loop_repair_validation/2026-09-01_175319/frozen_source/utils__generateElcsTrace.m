function T=generateElcsTrace(seedValue,cfg)
%GENERATEELCSTRACE Absolute random arrays for the ELCS-F kernel.

N=cfg.N;
F=cfg.maxFrames;
W=cfg.fallbackSlots;
stream=RandStream('mrg32k3a','Seed',mod(seedValue+22092026+1000*N,2^32));
T=struct();
stream.Substream=1; T.statusSlotU=rand(stream,F,N);
stream.Substream=2; T.grantSlotU=rand(stream,F,N);
stream.Substream=3; T.statusDeliveryU=rand(stream,F,N,N);
stream.Substream=4; T.grantDeliveryU=rand(stream,F,N,N);
stream.Substream=5; T.scheduledDeliveryU=rand(stream,F,N,N);
stream.Substream=6; T.fallbackAccessU=rand(stream,F,W,N);
stream.Substream=7; T.fallbackDeliveryU=rand(stream,F,W,N,N);
T.hashExact=realizationHash([T.statusSlotU(:);T.grantSlotU(:); ...
    T.statusDeliveryU(:);T.grantDeliveryU(:); ...
    T.scheduledDeliveryU(:);T.fallbackAccessU(:); ...
    T.fallbackDeliveryU(:)]);

end
