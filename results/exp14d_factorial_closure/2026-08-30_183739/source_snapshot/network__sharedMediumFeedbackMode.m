function mode = sharedMediumFeedbackMode(cfg)
%SHAREDMEDIUMFEEDBACKMODE Normalize the closed Study-2 feedback-mode enum.

mode = 'hybrid';
if isfield(cfg,'shared')
    if isfield(cfg.shared,'feedbackMode') && ...
            ~isempty(cfg.shared.feedbackMode)
        mode = lower(strtrim(char(cfg.shared.feedbackMode)));
    elseif isfield(cfg.shared,'feedbackEnabled') && ...
            ~logical(cfg.shared.feedbackEnabled)
        mode = 'none';
    end
end

valid = {'none','standalone','piggyback','hybrid','adaptive'};
if ~any(strcmp(mode,valid))
    error(['sharedMediumFeedbackMode: feedbackMode must be none, ' ...
        'standalone, piggyback, hybrid, or adaptive.']);
end

end
