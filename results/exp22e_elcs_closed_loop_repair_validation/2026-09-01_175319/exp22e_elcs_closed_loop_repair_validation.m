function exp22e_elcs_closed_loop_repair_validation(resumeDir)
%EXP22E_ELCS_CLOSED_LOOP_REPAIR_VALIDATION Fresh-seed integration rerun.

if nargin<1, resumeDir=''; end
exp22d_elcs_closed_loop_integration(resumeDir,'v2');

end
