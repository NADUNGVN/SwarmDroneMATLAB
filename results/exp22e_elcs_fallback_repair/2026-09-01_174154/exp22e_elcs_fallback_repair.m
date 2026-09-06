function exp22e_elcs_fallback_repair(resumeDir)
%EXP22E_ELCS_FALLBACK_REPAIR Fresh-seed validation of fallback repair.

if nargin<1, resumeDir=''; end
exp22_elcs_kernel_falsification(resumeDir,'v4');

end
