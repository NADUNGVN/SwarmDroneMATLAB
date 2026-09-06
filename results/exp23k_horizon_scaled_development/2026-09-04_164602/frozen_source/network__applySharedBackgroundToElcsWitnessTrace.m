function [T,B]=applySharedBackgroundToElcsWitnessTrace( ...
    T,C,trace,spec,backgroundLoad)
%APPLYSHAREDBACKGROUNDTOELCSWITNESSTRACE Map occupied PHY intervals to loss.
%
% A background-active MAC quantum blocks every receiver of any ELCS-W
% attempt whose physical interval overlaps that quantum. Potential attempts
% are mapped before the causal kernel runs; unused potential slots have no
% effect. Clock inversion is identical to applyDstrAffineClockSchedule.

requiredSpec={'clockOffsetSec','clockDriftPpm','leadTimeSec'};
if ~isstruct(spec) || ~all(isfield(spec,requiredSpec))
    error('applySharedBackgroundToElcsWitnessTrace: invalid clock spec.');
end
if ~isscalar(backgroundLoad) || ~isfinite(backgroundLoad) || ...
        backgroundLoad<0 || backgroundLoad>1
    error('applySharedBackgroundToElcsWitnessTrace: invalid load.');
end
if ~isfield(trace,'backgroundU') || ~isfield(trace,'slotTime') || ...
        ~isfield(trace,'hashExact')
    error('applySharedBackgroundToElcsWitnessTrace: invalid shared trace.');
end
if T.hashExact~=elcsWitnessTraceHash(T)
    error('applySharedBackgroundToElcsWitnessTrace: ELCS-W trace mismatch.');
end

N=C.N; F=C.maxFrames;
offset=reshape(spec.clockOffsetSec,[],1);
drift=reshape(spec.clockDriftPpm,[],1)*1e-6;
if numel(offset)~=N || numel(drift)~=N || any(1+drift<=0)
    error('applySharedBackgroundToElcsWitnessTrace: invalid clock vectors.');
end
W=buildConflictWitnessMap(C.conflictGraph,C.managementReach);
if ~W.allCovered
    error('applySharedBackgroundToElcsWitnessTrace: incomplete witness cover.');
end
responseBytes=C.certificateHeaderBytes+ ...
    W.responseEntryLoad*C.certificateEntryBytes;
responseBytes(W.responseEntryLoad==0)=0;
Ddata=8*C.dataBytes/C.phyRateBps;
Dclaim=8*C.claimBytes/C.phyRateBps;
Dresponse=8*responseBytes/C.phyRateBps;
Sdata=Ddata+C.guardSec;
Sclaim=Dclaim+C.guardSec;
claimPhase=N*Sclaim;
responseOffset=zeros(N,1);
cursor=claimPhase;
for witness=1:N
    responseOffset(witness)=cursor;
    if responseBytes(witness)>0
        cursor=cursor+Dresponse(witness)+C.guardSec;
    end
end
dataOffset=cursor;
frameDuration=dataOffset+(C.fallbackSlots+C.frameLength)*Sdata;
color=elcsWitnessPriorityColor(C.conflictGraph);

claimHits=0; responseHits=0; scheduledHits=0; fallbackHits=0;
for frame=1:F
    fs=(frame-1)*frameDuration;
    for sender=1:N
        nominal=fs+(sender-1)*Sclaim;
        actual=clockInverse(nominal,sender);
        if occupied(actual,Dclaim)
            T.claimDeliveryU(frame,:,sender)=0;
            claimHits=claimHits+1;
        end
        if responseBytes(sender)>0
            nominal=fs+responseOffset(sender);
            actual=clockInverse(nominal,sender);
            if occupied(actual,Dresponse(sender))
                T.certificateDeliveryU(frame,:,sender)=0;
                responseHits=responseHits+1;
            end
        end
        nominal=fs+dataOffset+C.fallbackSlots*Sdata+ ...
            (color(sender)-1)*Sdata;
        actual=clockInverse(nominal,sender);
        if occupied(actual,Ddata)
            T.scheduledDeliveryU(frame,:,sender)=0;
            scheduledHits=scheduledHits+1;
        end
        for fallbackSlot=1:C.fallbackSlots
            nominal=fs+dataOffset+(fallbackSlot-1)*Sdata;
            actual=clockInverse(nominal,sender);
            if occupied(actual,Ddata)
                T.fallbackDeliveryU(frame,fallbackSlot,:,sender)=0;
                fallbackHits=fallbackHits+1;
            end
        end
    end
end
T.hashExact=elcsWitnessTraceHash(T);
B=struct('version','ELCS-W-SHARED-BACKGROUND-OVERLAY-v1', ...
    'backgroundLoad',backgroundLoad, ...
    'realizedBackgroundFraction',mean(backgroundState()), ...
    'sharedTraceHashExact',trace.hashExact, ...
    'claimPotentialAttemptHits',claimHits, ...
    'responsePotentialAttemptHits',responseHits, ...
    'scheduledPotentialAttemptHits',scheduledHits, ...
    'fallbackPotentialAttemptHits',fallbackHits, ...
    'totalPotentialAttemptHits',claimHits+responseHits+ ...
        scheduledHits+fallbackHits);
B.hashExact=realizationHash([backgroundLoad;trace.hashExact; ...
    claimHits;responseHits;scheduledHits;fallbackHits;T.hashExact]);

    function actual=clockInverse(nominal,node)
        actual=spec.leadTimeSec+(nominal-offset(node))/(1+drift(node));
    end

    function hit=occupied(startTime,duration)
        hit=false;
        finish=startTime+duration;
        if finish<=0 || startTime>=size(trace.backgroundU,1)*trace.slotTime
            return;
        end
        first=max(1,floor(max(startTime,0)/trace.slotTime)+1);
        last=min(size(trace.backgroundU,1),ceil(max(finish,0)/trace.slotTime));
        for slotIndex=first:last
            a=(slotIndex-1)*trace.slotTime;
            b=slotIndex*trace.slotTime;
            overlap=min(finish,b)-max(startTime,a);
            active=backgroundAtIndex(slotIndex);
            if overlap>1e-12 && active
                hit=true;
                return;
            end
        end
    end

    function state=backgroundState()
        if isfield(trace,'measuredBackgroundActive')
            state=logical(trace.measuredBackgroundActive(:));
        else
            state=trace.backgroundU(:)<backgroundLoad;
        end
    end

    function active=backgroundAtIndex(slotIndex)
        if isfield(trace,'measuredBackgroundActive')
            active=logical(trace.measuredBackgroundActive(slotIndex));
        else
            active=trace.backgroundU(slotIndex)<backgroundLoad;
        end
    end

end
