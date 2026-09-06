function logging=ackValueLoggingConfig(cfg)
%ACKVALUELOGGINGCONFIG Validate passive confirmation-event instrumentation.

logging=struct('enabled',false,'schema','ACK-VALUE-EVENT-v1');
if isfield(cfg,'shared') && isfield(cfg.shared,'ackValueLogging') && ...
        ~isempty(cfg.shared.ackValueLogging)
    supplied=cfg.shared.ackValueLogging;
    if ~isstruct(supplied) || ~isscalar(supplied)
        error('ackValueLoggingConfig: cfg.shared.ackValueLogging must be a scalar struct.');
    end
    if isfield(supplied,'enabled')
        value=supplied.enabled;
        if ~isscalar(value) || ...
                ~(islogical(value) || (isnumeric(value) && any(value==[0 1])))
            error('ackValueLoggingConfig: enabled must be scalar logical.');
        end
        logging.enabled=logical(value);
    end
    if isfield(supplied,'schema') && ...
            ~strcmp(char(string(supplied.schema)),logging.schema)
        error('ackValueLoggingConfig: unsupported event schema.');
    end
end

end
