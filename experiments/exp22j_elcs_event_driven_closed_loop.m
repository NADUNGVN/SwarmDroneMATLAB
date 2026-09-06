function exp22j_elcs_event_driven_closed_loop(resumeDir)
%EXP22J_ELCS_EVENT_DRIVEN_CLOSED_LOOP Fresh-seed integration validation.

if nargin<1, resumeDir=''; end
exp22d_elcs_closed_loop_integration(resumeDir,'v3');

end
