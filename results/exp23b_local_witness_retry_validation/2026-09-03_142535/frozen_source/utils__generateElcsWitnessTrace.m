function T=generateElcsWitnessTrace(seedValue,C)
%GENERATEELCSWITNESSTRACE Absolute causal draws for ELCS-W.

N=C.N; F=C.maxFrames; W=C.fallbackSlots;
stream=RandStream('mrg32k3a','Seed',mod(seedValue+23092026+1000*N,2^32));
T=struct();
stream.Substream=1; T.claimSlotU=rand(stream,F,N);
stream.Substream=2; T.certificateSlotU=rand(stream,F,N);
stream.Substream=3; T.claimDeliveryU=rand(stream,F,N,N);
stream.Substream=4; T.certificateDeliveryU=rand(stream,F,N,N);
stream.Substream=5; T.scheduledDeliveryU=rand(stream,F,N,N);
stream.Substream=6; T.fallbackAccessU=rand(stream,F,W,N);
stream.Substream=7; T.fallbackDeliveryU=rand(stream,F,W,N,N);
T.hashExact=elcsWitnessTraceHash(T);

end
