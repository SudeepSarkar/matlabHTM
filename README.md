# matlabHTM
This is an implementation of Numenta's Hierachical Temporal Machines (HTM) and its testing on the Numenta Anomaly Dataset (NAB)
It implements both the spatial pooler and the temporal memory modules. For the spatial pooler, I used 

For the temporal memory, I used the description in the paper, "Why Neurons Have Thousands of Synapses, a Theory of Sequence Memory in Neocortex," http://journal.frontiersin.org/article/10.3389/fncir.2016.00023/full to guide the implementation. The paper describes the guts of the algorithm, but there are several details that need to be nailed down in an implementation, which are not in the paper. For those, I used some ideas specified in http://chetansurpur.com/slides/2014/5/4/cla-in-nupic.html#42 Note the implementation is NOT faitful to the NUPIC implementation. I did not implementation the PAM mode or the backtrack mode.

