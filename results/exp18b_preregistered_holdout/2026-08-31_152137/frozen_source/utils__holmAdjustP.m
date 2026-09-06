function adjusted=holmAdjustP(p)
%HOLMADJUSTP Holm step-down adjusted p-values with stable input shape.

if ~isnumeric(p) || ~isvector(p) || isempty(p)
    error('holmAdjustP: p must be a nonempty numeric vector.');
end
if any(isfinite(p) & (p<0 | p>1))
    error('holmAdjustP: finite p-values must lie in [0,1].');
end

originalSize=size(p);
work=p(:);
work(~isfinite(work))=1;
[sorted,order]=sort(work);
m=numel(sorted);
adjustedSorted=zeros(m,1);
running=0;
for k=1:m
    running=max(running,(m-k+1)*sorted(k));
    adjustedSorted(k)=min(1,running);
end
adjustedColumn=zeros(m,1);
adjustedColumn(order)=adjustedSorted;
adjusted=reshape(adjustedColumn,originalSize);

end
