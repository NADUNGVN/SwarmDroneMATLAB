function exp22b_elcs_kernel_repair(resumeDir)
%EXP22B_ELCS_KERNEL_REPAIR Fresh-seed validation of v1 structural repairs.

if nargin<1, resumeDir=''; end
exp22_elcs_kernel_falsification(resumeDir,'v2');

end
