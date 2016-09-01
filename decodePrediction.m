function [values, confidences] = decodePrediction (pi)

global SP data


reconstructedInput = (pi* double(SP.synapse > SP.connectPerm)) > 1;



d = (data.inputCodes * reconstructedInput')./sum(data.inputCodes, 2);

%d = [];
%         /nnz(inputSDR(i,:));
% for i=1:size(inputSDR, 1)
%     d(i) = nnz(reconstructedInput (startColumn:endColumn) & inputSDR(i,:))...
%         /nnz(inputSDR(i,:));
% end;
% %[v, y] = max(d);

[confidences, values] = sort(d, 'descend');
i = find(confidences > 0.99);
confidences = confidences(i);
values = data.value{1}(values(i));
%fprintf(1, '\n Predicted symbol: %d, (%d)', y, nnz(pi));

