function exp23r_coherence_packet_graph_repair(resumeDir)
%EXP23R_COHERENCE_PACKET_GRAPH_REPAIR Fresh packet graph-repair validation.

if nargin<1, resumeDir=''; end
exp23p_coherence_packet_kernel(resumeDir,'r');

end
