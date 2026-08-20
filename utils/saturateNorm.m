function y = saturateNorm(x, maxNorm)
%SATURATENORM Limit vector Euclidean norm.
n = norm(x);
if n > maxNorm && n > 0
    y = x * (maxNorm / n);
else
    y = x;
end
end
