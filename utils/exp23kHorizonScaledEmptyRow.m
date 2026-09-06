function row=exp23kHorizonScaledEmptyRow()
%EXP23KHORIZONSCALEDEMPTYROW Stable horizon-probe schema.

row=exp23fWitnessBackgroundEmptyRow();
row.RENEWAL_SCALE_FACTOR=NaN;
row.RENEWAL_PERIOD_FRAMES=NaN;
row.LEASE_FRAMES=NaN;
row.REFRESH_LEAD_FRAMES=NaN;
row.LEASE_FENCE_FRAMES=NaN;

end
