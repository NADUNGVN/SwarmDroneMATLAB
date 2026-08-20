function v = vee(S)
%VEE Convert a 3x3 skew-symmetric matrix to a 3x1 vector.
v = [S(3,2); S(1,3); S(2,1)];
end
