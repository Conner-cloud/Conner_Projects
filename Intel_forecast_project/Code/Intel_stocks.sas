ods graphics /LOESSMAXOBS=11000;

* Open the file;
data intel_stock;
infile '/home/u40846561/Projects/INTC.csv' dlm = ',' firstobs = 2;   
input Date anydtdte10. Volume;
format Date date10.;
logvolume = log(Volume);
run;

* Plot the data ;
proc sgplot data = intel_stock;
series x = Date y = Volume/markers;	
xaxis values = (1 to 5000 by 1);	
run;
* Variation seems to increase greatly over time, hence we take the log of volume ;

proc sgplot data = intel_stock;
series x = Date y = logvolume/markers;	
xaxis values = (1 to 5000 by 1);	
run;
* Plot shows a good amount of variance removed ;

* Plotting ACF and PACF plots and selecting an ARIMA model ;
proc arima data = intel_stock plots = all;
identify var= logvolume(1);
estimate p = 5 q = 5;
outlier id=Date;
run;
* ARIMA(5,1,5) appears to have the lowest AIC compared to other model ;

* Outlier detection and removal ;
data intel_stock;
set intel_stock;
if _n_ = 1657 then AO = 1;
else AO = 0.0;
if _n_ = 5237 then AO = 1;
else AO = 0.0;
if _n_ = 2816 then AO = 1;
else AO = 0.0;
if _n_ >= 1720 then LS = 1;
else LS = 0.0;
if _n_ = 5267 then AO = 1;
else AO = 0.0;
run;

* Outliers are still significant but the model is better than before ;
proc arima data=intel_stock;
identify var=logvolume(1)
crosscorr=( AO(1) LS(1) );
estimate p = 5 q = 5 noint
input=( AO LS )
method=ml plot;
outlier id=Date;
run;

* Plotting forecast ;
proc arima data = intel_stock plots = all;
identify var= logvolume(1);
estimate p = 5 q = 5;
forecast lead = 60 interval = month id = Date out = forecast;
run;

* Removes logarithm from volume, forecast, upper and lower 95% CIs;
data intel_forecast;
set forecast;
Volume = exp(logvolume);
l95 = exp(l95);
u95 = exp(u95);
forecast = exp(forecast + std*std/2);
run;

* plots forecast with the rest of the data ;
proc sgplot data=intel_forecast;
where date >= '1JAN18'D;
band Upper=u95 Lower=l95 x=Date
/ legendLabel="95% Confidence Limits" ;
scatter x=Date y=Volume;
series x=Date y=forecast
/ legendlabel="Forecast of Volume for the next 5 years";
run;