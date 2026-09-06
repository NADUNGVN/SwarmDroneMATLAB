function T=generateExp21dDstrTrace(seedValue,N,R)
%GENERATEEXP21DDSTRTRACE Absolute, condition-paired D-STR random arrays.

streamSeed=mod(seedValue+R.traceSeedOffset+1000*N,2^32);
stream=RandStream('mt19937ar','Seed',streamSeed);
T=struct();
T.choiceU=rand(stream,R.maxFrames,N);
T.retentionU=rand(stream,R.maxFrames,N);
T.dataDeliveryU=rand(stream,R.maxFrames,N,N);
T.managementDeliveryU=rand(stream,R.maxFrames,5,N,N);

end
