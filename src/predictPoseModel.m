function output = predictPoseModel(net, input)
%PREDICTPOSEMODEL Raw pixel range 0..255 with normalization disabled.
% Windows uint8 opt-in is qualified by runPoseModelChecks on this computer;
% it is not a claim that arbitrary quantized models are numerically correct.
if ispc && isa(input,'uint8')
    output=predict(net,input,EnableINT8InferenceOnWindows=true);
else
    output=predict(net,input);
end
end
