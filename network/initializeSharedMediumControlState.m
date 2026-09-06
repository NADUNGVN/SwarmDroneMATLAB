function net = initializeSharedMediumControlState(net, P, V, leader, cfg)
%INITIALIZESHAREDMEDIUMCONTROLSTATE Publish the common t=0 control state.
%
%   net = initializeSharedMediumControlState(net,P,V,leader,cfg)
%
% This is the only initialization bridge between the shared-medium protocol
% and distributedFormationPolicy.  Later updates occur atomically inside
% applySharedMediumDeliveries after a newest-generation DATA acceptance.

N = cfg.swarm.N;

if ~isequal(size(P),[N 3]) || ~isequal(size(V),[N 3])
    error('initializeSharedMediumControlState: P and V must be N-by-3.');
end
if ~isequal(size(cfg.swarm.A),[N N]) || numel(cfg.swarm.pin) ~= N
    error('initializeSharedMediumControlState: invalid A or pin dimensions.');
end

net.serviceScheduler.commonPos=P;
net.serviceScheduler.commonVel=V;
net.serviceScheduler.initialPos=P;
net.serviceScheduler.initialVel=V;

for i = 1:N
    for j = 1:N
        if cfg.swarm.A(i,j)
            net.Pij(i,j,:) = reshape(P(j,:),1,1,3);
            net.Vij(i,j,:) = reshape(V(j,:),1,1,3);
        end
    end

    if cfg.swarm.pin(i)
        net.leaderPos(i,:) = leader.pos(:)';
        net.leaderVel(i,:) = leader.vel(:)';
        net.leaderAcc(i,:) = leader.acc(:)';
    end
end

end
