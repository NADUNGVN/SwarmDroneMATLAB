function mac = sharedMediumConfig(cfg)
%SHAREDMEDIUMCONFIG Validate and complete the EXP12 MAC configuration.
%
%   mac = sharedMediumConfig(cfg)
%
% EXP12 deliberately implements an abstract shared medium, not a named IEEE
% PHY/MAC.  All sizes and times are explicit so later trace/HIL calibration can
% replace them without changing the frame and delivery semantics.

if isfield(cfg,'mac')
    mac = cfg.mac;
else
    mac = struct();
end

mac = setDefault(mac, 'type',          'csma');
mac = setDefault(mac, 'slotTime',      1e-3);
mac = setDefault(mac, 'queueCapacity', 4);
mac = setDefault(mac, 'dataBytes',     48);
mac = setDefault(mac, 'ackBaseBytes',  12);
mac = setDefault(mac, 'ackEntryBytes', 8);
mac = setDefault(mac, 'phyRateBps',    1e6);
mac = setDefault(mac, 'ackDeadline',   0.02);
mac = setDefault(mac, 'pAccess',       1.0);
mac = setDefault(mac, 'historySize',   32);
mac = setDefault(mac, 'residualLoss',  0.0);
mac = setDefault(mac, 'lossModel',     'iid');
mac = setDefault(mac, 'separateAckTrace', false);
mac = setDefault(mac, 'dataResidualLoss', mac.residualLoss);
mac = setDefault(mac, 'ackResidualLoss',  mac.residualLoss);
mac = setDefault(mac, 'seedOffset',    31012026);
mac = setDefault(mac, 'maxRetries',    0);
mac = setDefault(mac, 'txPowerW',      0.20);
mac = setDefault(mac, 'backgroundLoad',0.0);
mac = setDefault(mac, 'applyDeliveriesInline', false);

if ~isfield(mac,'burst') || isempty(mac.burst)
    mac.burst = struct();
end
mac.burst = setDefault(mac.burst,'dataGoodLoss',0.02);
mac.burst = setDefault(mac.burst,'dataBadLoss',0.65);
mac.burst = setDefault(mac.burst,'dataGoodToBad',0.003);
mac.burst = setDefault(mac.burst,'dataBadToGood',0.030);
mac.burst = setDefault(mac.burst,'ackGoodLoss',0.02);
mac.burst = setDefault(mac.burst,'ackBadLoss',0.65);
mac.burst = setDefault(mac.burst,'ackGoodToBad',0.003);
mac.burst = setDefault(mac.burst,'ackBadToGood',0.030);

% interferenceMatrix(receiver,transmitter)=true means that transmitter can
% corrupt a concurrent reception at that receiver.  The default is one
% fully-conflicting collision domain.
if ~isfield(mac,'interferenceMatrix') || isempty(mac.interferenceMatrix)
    mac.interferenceMatrix = true(cfg.swarm.N);
end

% carrierSenseMatrix(node,transmitter)=true means that node defers while an
% already-active frame from transmitter is on air.  Keeping carrier sensing
% separate from receiver interference is necessary to express a genuine
% hidden-terminal arm.  The all-true default reproduces the legacy single
% carrier-sense domain exactly.
if ~isfield(mac,'carrierSenseMatrix') || isempty(mac.carrierSenseMatrix)
    mac.carrierSenseMatrix = true(cfg.swarm.N);
end

validTypes = {'csma','aloha','tdma'};
if ~any(strcmpi(mac.type, validTypes))
    error('sharedMediumConfig: unknown MAC type "%s".', mac.type);
end

mac.lossModel = lower(strtrim(char(mac.lossModel)));
validLossModels = {'iid','gilbert-elliott'};
if ~any(strcmp(mac.lossModel,validLossModels))
    error(['sharedMediumConfig: lossModel must be iid or ' ...
        'gilbert-elliott.']);
end

mustBePositiveScalar(mac.slotTime,      'slotTime');
mustBePositiveScalar(mac.queueCapacity, 'queueCapacity');
mustBePositiveScalar(mac.dataBytes,     'dataBytes');
mustBePositiveScalar(mac.ackBaseBytes,  'ackBaseBytes');
mustBePositiveScalar(mac.ackEntryBytes, 'ackEntryBytes');
mustBePositiveScalar(mac.phyRateBps,    'phyRateBps');
mustBePositiveScalar(mac.ackDeadline,   'ackDeadline');
mustBePositiveScalar(mac.historySize,   'historySize');
mustBePositiveScalar(mac.txPowerW,      'txPowerW');

if mac.queueCapacity ~= floor(mac.queueCapacity)
    error('sharedMediumConfig: queueCapacity must be an integer.');
end
if mac.historySize ~= floor(mac.historySize)
    error('sharedMediumConfig: historySize must be an integer.');
end
if ~isscalar(mac.maxRetries) || ~isfinite(mac.maxRetries) || ...
        mac.maxRetries < 0 || mac.maxRetries ~= floor(mac.maxRetries)
    error('sharedMediumConfig: maxRetries must be a nonnegative integer.');
end
if ~isscalar(mac.pAccess) || mac.pAccess < 0 || mac.pAccess > 1
    error('sharedMediumConfig: pAccess must lie in [0,1].');
end
if ~isscalar(mac.backgroundLoad) || ~isfinite(mac.backgroundLoad) || ...
        mac.backgroundLoad < 0 || mac.backgroundLoad > 1
    error('sharedMediumConfig: backgroundLoad must lie in [0,1].');
end
N = cfg.swarm.N;
validateProbabilityMap(mac.residualLoss,N,'residualLoss');
validateProbabilityMap(mac.dataResidualLoss,N,'dataResidualLoss');
validateProbabilityMap(mac.ackResidualLoss,N,'ackResidualLoss');
burstFields = {'dataGoodLoss','dataBadLoss','dataGoodToBad', ...
    'dataBadToGood','ackGoodLoss','ackBadLoss','ackGoodToBad', ...
    'ackBadToGood'};
for k = 1:numel(burstFields)
    validateProbabilityMap(mac.burst.(burstFields{k}),N, ...
        ['burst.' burstFields{k}]);
end
if any(expandMap(mac.burst.dataBadLoss,N) < ...
        expandMap(mac.burst.dataGoodLoss,N),'all') || ...
        any(expandMap(mac.burst.ackBadLoss,N) < ...
        expandMap(mac.burst.ackGoodLoss,N),'all')
    error(['sharedMediumConfig: bad-state loss must not be below ' ...
        'good-state loss.']);
end
if ~isequal(size(mac.interferenceMatrix),[cfg.swarm.N cfg.swarm.N]) || ...
        any(~isfinite(mac.interferenceMatrix(:))) || ...
        any(mac.interferenceMatrix(:) ~= 0 & mac.interferenceMatrix(:) ~= 1)
    error(['sharedMediumConfig: interferenceMatrix must be a finite binary ' ...
        'N-by-N matrix.']);
end
mac.interferenceMatrix = logical(mac.interferenceMatrix);
if ~isequal(size(mac.carrierSenseMatrix),[cfg.swarm.N cfg.swarm.N]) || ...
        any(~isfinite(mac.carrierSenseMatrix(:))) || ...
        any(mac.carrierSenseMatrix(:) ~= 0 & mac.carrierSenseMatrix(:) ~= 1)
    error(['sharedMediumConfig: carrierSenseMatrix must be a finite binary ' ...
        'N-by-N matrix.']);
end
mac.carrierSenseMatrix = logical(mac.carrierSenseMatrix);
if ~isscalar(mac.applyDeliveriesInline) || ...
        ~(islogical(mac.applyDeliveriesInline) || ...
        any(mac.applyDeliveriesInline == [0 1]))
    error('sharedMediumConfig: applyDeliveriesInline must be scalar logical.');
end
mac.applyDeliveriesInline = logical(mac.applyDeliveriesInline);
if ~isscalar(mac.separateAckTrace) || ...
        ~(islogical(mac.separateAckTrace) || ...
        any(mac.separateAckTrace == [0 1]))
    error('sharedMediumConfig: separateAckTrace must be scalar logical.');
end
mac.separateAckTrace = logical(mac.separateAckTrace);

end


function validateProbabilityMap(x,N,name)

if ~(isscalar(x) || isequal(size(x),[N N])) || ...
        any(~isfinite(x(:)) | x(:)<0 | x(:)>1)
    error(['sharedMediumConfig: %s must be a probability scalar or ' ...
        'N-by-N map.'],name);
end

end


function y = expandMap(x,N)

if isscalar(x)
    y = repmat(x,N,N);
else
    y = x;
end

end


function s = setDefault(s, name, value)

if ~isfield(s,name) || isempty(s.(name))
    s.(name) = value;
end

end


function mustBePositiveScalar(x, name)

if ~isscalar(x) || ~isfinite(x) || x <= 0
    error('sharedMediumConfig: %s must be a positive finite scalar.', name);
end

end
