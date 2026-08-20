% TEST_ROTATION Minimal sanity checks for rotation utilities.
startup;
R = rotmZYX([0;0;0]);
assert(norm(R-eye(3),'fro') < 1e-12);
R = rotmZYX([0.2;-0.1;0.4]);
assert(norm(R'*R-eye(3),'fro') < 1e-10);
assert(abs(det(R)-1) < 1e-10);
fprintf('test_rotation: PASS\n');
