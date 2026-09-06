function net=recordServiceCompletion(net,sender,tk)
%RECORDSERVICECOMPLETION Record one DATA frame delivered to any receiver.

S=net.serviceScheduler;
S.completed(sender)=S.completed(sender)+1;
S.virtualDeficit(sender)=max(0,S.virtualDeficit(sender)-1);
interval=max(tk-S.lastServiceTime(sender),0);
S.maxStarvationInterval(sender)=max( ...
    S.maxStarvationInterval(sender),interval);
S.lastServiceTime(sender)=tk;
net.serviceScheduler=S;

end
