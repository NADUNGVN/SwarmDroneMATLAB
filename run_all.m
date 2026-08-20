startup;
fprintf('\n[1/3] Running single-drone hover...\n');
exp01_hover;
fprintf('\n[2/3] Running nominal swarm formation...\n');
exp02_formation;
fprintf('\n[3/3] Running packet-loss sweep...\n');
exp03_packet_loss_sweep;
