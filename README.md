# matlabHTM
-- Summer 2016 project by Sudeep Sarkar http://www.cse.usf.edu/~sarkar/

https://github.com/SudeepSarkar/matlabHTM

This is an implementation of Numenta's Hierachical Temporal Machines (HTM) 
and its testing on the Numenta Anomaly Dataset (NAB). It implements all the three modules the 
spatial pooler (SP), the sequence memory (SM or temporal memory), and the temporal pooler (TP)
modules. 

For the encoders and the spatial pooler, I used the pseudocode and description 
BAMI, http://numenta.com/biological-and-machine-intelligence/

For the temporal memory, I used the description in the paper, "Why Neurons 
Have Thousands of Synapses, a Theory of Sequence Memory in Neocortex," 

http://journal.frontiersin.org/article/10.3389/fncir.2016.00023/full 

to guide the implementation. The paper describes the guts of the algorithm, but there 
are several details that need to be nailed down in an implementation, which 
are not in the paper. I followed the implementation that is sketched out at

http://numenta.com/assets/pdf/biological-and-machine-intelligence/0.4/BaMI-Temporal-Memory.pdf

I also relied on the information on the slides in 

http://chetansurpur.com/slides/2014/5/4/cla-in-nupic.html#42 

Note the implementation is NOT faithful to the NUPIC implementation. 
I did not implement the PAM mode or the backtrack mode.

For the temporal pooler (TP) I used the 2015 version of the temporal pooler concept
as outlined at 

https://github.com/numenta/nupic.research/wiki/Overview-of-the-Temporal-Pooler

and using implementations at
 https://github.com/numenta/nupic.research/wiki/Union-Pooler-Psuedocode ,
 https://github.com/numenta/nupic.research/blob/master/htmresearch/algorithms/union_temporal_pooler.py
 and
 https://github.com/numenta/nupic.research/blob/master/htmresearch/frameworks/union_temporal_pooling/union_temporal_pooler_experiment.py


For the anomaly detection and scoring parts, I relied on descriptions in the 
paper "Real-Time Anomaly Detection for Streaming Analytics," 

https://arxiv.org/abs/1607.02480 

I was not able to fully replicate the NUMENTA likelihood algorithm, but was close enough.

I also implemented a bootstraped estimate of the variance of the final scores, 
so that we can mark differences as being statistically different or not. 

-------------------------------------------

Performance achieved with this code, with estimates bounded by plus and minus one standard deviation.

Our Raw Scores + Our Anomaly Likelihood: 60.193 (Bootstrap estimate: 60.165 +- 3.677) 

NUPIC Scores + NAB Anomaly Likelihood: 60.979 (Bootstrap estimate: 60.576 +- 3.555)
 
NUPIC Raw Scores + Our Anomaly Likelihood: 56.171 (Bootstrap estimate: 56.270 +- 3.931) 
 
Random: 7.952 (average over > 100 runs)




