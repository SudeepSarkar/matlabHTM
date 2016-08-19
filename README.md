# matlabHTM
-- Summer 2016 project by Sudeep Sarkar http://www.cse.usf.edu/~sarkar/

This is an implementation of Numenta's Hierachical Temporal Machines (HTM) and its testing on the Numenta Anomaly Dataset (NAB)
It implements both the spatial pooler and the temporal memory modules. 

For the encoders and the spatial pooler, I used the pseudocode and description BAMI, http://numenta.com/biological-and-machine-intelligence/

For the temporal memory, I used the description in the paper, "Why Neurons Have Thousands of Synapses, a Theory of Sequence Memory in Neocortex," http://journal.frontiersin.org/article/10.3389/fncir.2016.00023/full to guide the implementation. The paper describes the guts of the algorithm, but there are several details that need to be nailed down in an implementation, which are not in the paper. For those, I used some ideas specified in http://chetansurpur.com/slides/2014/5/4/cla-in-nupic.html#42 Note the implementation is NOT faitful to the NUPIC implementation. I did not implementation the PAM mode or the backtrack mode.

For the anomaly detection and scoring parts, I relied on descriptions in the paper "Real-Time Anomaly Detection for Streaming Analytics," https://arxiv.org/abs/1607.02480 I was not able to fully replicate the NUMENTA likelihood algorithm, but was close enough.

I also implemnted a bootstraped estimate of the variance of the final scores, so that we can mark differences as being statistically different or not. 

Performance achieved with this code.

Our Raw Scores + Our implmentation of Anomaly Likelihood: 57.785 (Bootstrap estimate: 58.530 +- 4.095) 

NumentaTM + NAB Anomaly Likelihood Scores: 60.979 (Bootstrap estimate: 61.021 +- 3.815) 

NumentaTM Raw Scores + Our implementation of Anomaly Likelihood: 51.671 (Bootstrap estimate: 51.773 +- 5.002) 

Random: 5.855 (average over > 100 runs)

