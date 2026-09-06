function T=generateExp21dDstrTrace(seedValue,N,R)
%GENERATEEXP21DDSTRTRACE Absolute, condition-paired D-STR random arrays.

streamSeed=mod(seedValue+R.traceSeedOffset+1000*N,2^32);
stream=RandStream('mrg32k3a','Seed',streamSeed);
T=struct();
T.choiceU=zeros(R.maxFrames,N);
T.retentionU=zeros(R.maxFrames,N);
T.dataDeliveryU=zeros(R.maxFrames,N,N);
T.managementDeliveryU=zeros(R.maxFrames,5,N,N);

% Every logical draw series owns a fixed substream.  Increasing maxFrames
% therefore extends, rather than changes, every existing (frame,index) draw.
for node=1:N
    stream.Substream=node;
    T.choiceU(:,node)=rand(stream,R.maxFrames,1);
    stream.Substream=N+node;
    T.retentionU(:,node)=rand(stream,R.maxFrames,1);
end
offset=2*N;
for sender=1:N
    for receiver=1:N
        stream.Substream=offset+(sender-1)*N+receiver;
        T.dataDeliveryU(:,receiver,sender)=rand(stream,R.maxFrames,1);
    end
end
offset=offset+N*N;
for slot=1:5
    for sender=1:N
        for receiver=1:N
            stream.Substream=offset+(slot-1)*N*N+ ...
                (sender-1)*N+receiver;
            T.managementDeliveryU(:,slot,receiver,sender)= ...
                rand(stream,R.maxFrames,1);
        end
    end
end

end
