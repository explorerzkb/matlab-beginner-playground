function model = loadPoseModel(path, candidate, cfg)
%LOADPOSEMODEL Fail explicitly until THIS local model passes interface probe.
candidate=validatestring(candidate,{'single','multi'});
if isempty(which('loadTFLiteModel'))
    error('matlabHi:PoseDependency','Missing MATLAB loadTFLiteModel interface.');
end
assert(isfile(path),'matlabHi:PoseModelMissing','Model file not found: %s',path);
net=loadTFLiteModel(path);
net.Mean=0; net.StandardDeviation=1; net.NumThreads=cfg.modelThreads;
assert(net.NumInputs==1 && net.NumOutputs==1, ...
    'matlabHi:PoseModelShape','Expected one input and one output');
inputSize=double(net.InputSize{1});
assert(numel(inputSize)==3 && inputSize(3)==3, ...
    'matlabHi:PoseModelShape','Expected fixed H x W x 3 input');
if strcmp(candidate,'single')
    assert(isequal(inputSize,[192 192 3]), ...
        'matlabHi:PoseModelShape','Lightning SinglePose requires 192 x 192');
    outputSize=[1 17 3];
else
    assert(isequal(inputSize,[160 256 3]), ...
        'matlabHi:PoseDynamicShape','Use the qualified fixed 160 x 256 MultiPose model');
    outputSize=[6 56];
end
assert(isequal(double(net.OutputSize{1}),outputSize), ...
    'matlabHi:PoseModelShape','Unexpected output layout; do not guess reshape');
type=char(net.InputType{1});
assert(ismember(type,{'single','uint8','int8'}), ...
    'matlabHi:PoseModelType','Unsupported input type: %s',type);
% int8 input needs a separately validated quantization contract.
assert(~strcmp(type,'int8'),'matlabHi:PoseQuantization', ...
    'Use validated float/uint8 candidate; int8 preprocessing not qualified.');
probe=predictPoseModel(net,cast(zeros(inputSize),type));
assert(isequal(size(probe),outputSize) && all(isfinite(probe),'all'), ...
    'matlabHi:PoseModelProbe','Prediction layout/value probe failed');
model=struct('net',net,'candidate',candidate,'inputSize',inputSize(1:2), ...
    'inputType',type,'path',path);
end
