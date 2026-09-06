function net=updateServiceStarvation(net,tk)
%UPDATESERVICESTARVATION Track elapsed service gaps for outstanding demand.

S=net.serviceScheduler;
outstanding=S.virtualDeficit>0;
if any(outstanding)
    elapsed=max(tk-S.lastServiceTime,0);
    S.maxStarvationInterval(outstanding)=max( ...
        S.maxStarvationInterval(outstanding),elapsed(outstanding));
end
net.serviceScheduler=S;

end
