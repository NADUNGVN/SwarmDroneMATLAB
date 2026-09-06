function net=recordServiceAdmission(net,sender,tk)
%RECORDSERVICEADMISSION Update the EXP19 virtual service-deficit state.

S=net.serviceScheduler;
S.admitted(sender)=S.admitted(sender)+1;
S.virtualDeficit(sender)=S.virtualDeficit(sender)+1;
S.lastAdmissionTime(sender)=tk;
S.maxVirtualDeficit=max(S.maxVirtualDeficit,S.virtualDeficit);
net.serviceScheduler=S;

end
