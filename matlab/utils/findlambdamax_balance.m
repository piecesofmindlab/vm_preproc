function lambdamax=findlambdamax_balance

global globDat

[num_samp, dim]=size(globDat.stim);
idx_pos=find(globDat.resp>0);
idx_neg=find(globDat.resp<=0);
tmp_m=zeros(num_samp,1);
tmp_m(idx_pos)=1/2;
tmp_m(idx_neg)=-1/2*length(idx_pos)/length(idx_neg);
tmp_n=globDat.stim'*tmp_m;
lambdamax=max(abs(tmp_n));