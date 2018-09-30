function [values, confidences] = decodePrediction (pi)
% This function reconstructs the input to the spatial pooler intput from
% the input of the sequence (or equivalently the output of the spatial
% pooler. This function is used to visualize the predicted vector of the
% sequence memory in terms of the raw input signal.
%
% For an input vector, it returns a set of possible values along with
% confidence values.
%
% To arrive at the output, it considers past inputs and picks ones that are
% closed to the reconstructed signal.


global SP data

reconstructedInput = (pi* double(SP.synapse > SP.connectPerm)) > 20;

d = (data.inputCodes * reconstructedInput'); %./sum(data.inputCodes, 2);

[confidences, values] = sort(d, 'descend');
i = find(confidences > 0.99);
confidences = confidences(i);
values = data.value{1}(values(i));

