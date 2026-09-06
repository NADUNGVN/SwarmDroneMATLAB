function diagnose_exp23af_command_candidates()
%DIAGNOSE_EXP23AF_COMMAND_CANDIDATES Find non-vacuous safe sweep commands.

startup;
expRun=startExperiment('exp23af_command_candidate_diagnostic', ...
    'Search safe receiver-lifted command sweeps that force recoloring.');
cfg=applyExp21dClosedLoopCell('n10-ring2-zero-loss',16093999);
p0=2*cfg.swarm.offsets; N=cfg.swarm.N; neighbor=logical(cfg.swarm.A);
reach=true(N); reach(1:N+1:end)=false; packet=packetConfig(N);
radius=.97; grid=-3:.10:3; rows=cell(0,14);
for node=2:N
    tube=.11*(ones(N)-eye(N));
    tube(1,:)=.21; tube(:,1)=.21;
    tube(node,:)=.18; tube(:,node)=.18; tube(1:N+1:end)=0;
    for x=grid
        for y=grid
            target=[x y 0]; displacement=norm(target-p0(node,:));
            if displacement<.20||displacement>2.0, continue; end
            [minSweep,nearest]=sweepSeparation(p0,node,target);
            if minSweep<.60, continue; end
            p1=p0; p1(node,:)=target;
            G=buildCausalSweptReceiverClosure(p0,p1,tube,radius, ...
                neighbor,reach,node,packet);
            M=G.migration;
            nonincident=nnz(M.changedEdgeA~=node&M.changedEdgeB~=node);
            protected=~any(ismember((N+1:N+5)',M.oldSlot))&& ...
                ~any(ismember((N+1:N+5)',M.candidateSlot));
            if ~(M.admissible&&M.changedSlotCount>0&&nonincident>0&&protected)
                continue;
            end
            rows(end+1,:)={node,x,y,displacement,minSweep,nearest, ... %#ok<AGROW>
                M.changedEdgeCount,nonincident,M.affectedCount, ...
                M.changedSlotCount,max(M.oldSlot),max(M.candidateSlot), ...
                M.maxResponseBytes,G.hashExact};
        end
    end
end
if isempty(rows)
    T=cell2table(cell(0,14),'VariableNames',variableNames());
else
    T=cell2table(rows,'VariableNames',variableNames());
    T=sortrows(T,{'displacement','minimumSweepSeparation'}, ...
        {'ascend','descend'});
end
writetable(T,fullfile(expRun.dir,'command_candidates.csv'));
disp(T(1:min(30,height(T)),:));
verdict=struct('status',ternary(height(T)>0, ...
    'NONVACUOUS_SAFE_COMMAND_CANDIDATES_FOUND', ...
    'NO_NONVACUOUS_SAFE_COMMAND_CANDIDATE'), ...
    'candidates',height(T),'radius',radius, ...
    'pairwiseTrackingRadius',true, ...
    'managementReachHops',inf,'developmentDiagnostic',true, ...
    'confirmationEvidence',false);
writeJson(fullfile(expRun.dir,'diagnostic_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','verdict');
finishExperiment(expRun);

end


function [minimum,nodeIndex]=sweepSeparation(p,node,target)

minimum=inf; nodeIndex=NaN; step=target-p(node,:);
for other=1:size(p,1)
    if other==node, continue; end
    relative=p(node,:)-p(other,:); denominator=sum(step.^2);
    if denominator<=eps, alpha=0;
    else, alpha=min(1,max(0,-dot(relative,step)/denominator)); end
    distance=norm(relative+alpha*step);
    if distance<minimum, minimum=distance; nodeIndex=other; end
end

end


function packet=packetConfig(N)

packet=struct('maxDataSlots',N+5,'maxAffectedNodes',N, ...
    'prepareHeaderBytes',32,'affectedEntryBytes',4,'claimBytes',72, ...
    'quietBytes',24,'lockProofBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'commitBytes',28,'maxControlPacketBytes',96,'revokeBytes',24, ...
    'retiringSlot',(1:N)');

end


function names=variableNames()

names={'node','targetX','targetY','displacement', ...
    'minimumSweepSeparation','nearestNode','changedSenderEdges', ...
    'nonincidentSenderEdges','affectedCount','changedSlotCount', ...
    'oldColors','newColors','maxResponseBytes','geometryHash'};

end


function writeJson(path,value)

fid=fopen(path,'w'); if fid<0, error('exp23af candidate: write.'); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)
if condition, value=a; else, value=b; end
end
