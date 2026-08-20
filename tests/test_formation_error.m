% TEST_FORMATION_ERROR Perfect formation should have near-zero pairwise error.
startup;
cfg = defaultConfig();
N = cfg.swarm.N;
P = cfg.swarm.offsets;
acc = 0; n = 0;
for i = 1:N
    for j = i+1:N
        desired = cfg.swarm.offsets(:,i)-cfg.swarm.offsets(:,j);
        actual = P(:,i)-P(:,j);
        acc = acc + norm(actual-desired)^2;
        n = n + 1;
    end
end
err = sqrt(acc/n);
assert(err < 1e-12);
fprintf('test_formation_error: PASS\n');
