### Visualising and Cleaning the Data
After cleaning the data so that all car models were listed under the name of the brand (e.g. Volkwagen Golf 2007 -> VW) I plotted the distribution of car models. The bar chart shows cleanly which car brand has the most number of models (Toyota) and which has the least (Mercury). We can see that most car brands have around 10 models but this plot is not a good visualisation of averages.

 
<img src="Car_price_prediction/Images/Distribution_brands.jpeg" width="600"  >

 
Here I plot the density of car models, we can see the average number of car models between all brands more clearly. There is also a small peak at 32 models which we know to be Toyota from the bar chart above. The average number of models per car brand is approximately ~ 5 models.

 
<img src="Car_price_prediction/Images/Density_brands.jpeg" width="600"  >

Since we are interested in the price of the car we should plot the density of car prices to get an understanding of the average price of a car. We can see most cars are £10000, the curve drops and then flattens around £20000 where a few more cars sit, the curve then flattens towards £50000 as we expect.

 
<img src="Car_price_prediction/Images/Density_car_prices.jpeg" width="600"  >

 
### Building a model
Firstly, I started with a model that includes all variables. This way I can plot all residuals to detect outliers and more importantly determine if the data is suitable for multiple linear regression.

* Residuals VS Fitted: The red line is horizontal suggesting linearity and there are an equal number of residuals above and below the line suggesting zero-mean.
* Normal Q-Q plot: Majority of the residuals are on  or close to the diagonal line suggesting normality.
* Scale-Location: Mostly horizontal line suggesting the assumption of contant variance is upheld by our model.
* Residual VS leverage: We can identify one outlier in the bottom right.

 
<img src="Car_price_prediction/Images/Residual_plots_train.jpeg" width="600"  >

 
Overall it appears our model is a good fit and suitable for prediction using Multiple Linear Regression. However, we need to deal with the outlier identified and we can also make our model simpler without reducing the accuracy of the model. Using Backward Elimination or Forward Selection we can remove insignificant variables from the model and build a simpler one to use for prediction.

 
### Forward model
<img src="Car_price_prediction/Images/Forward_model.png" width="400"  >

 
### Backward model
<img src="Car_price_prediction/Images/Backward_model.png" width="400"  >

 
### Comparing models
Comparing the two models, the backward model appears to have more significant variables as well as having a higher R-squared value, suggesting it is the better model. The F-test below shows that the F-statistic is significant. Hence I have evidence to reject the null hypothesis that the models are not significantly different. We have enough evidence to say that the backward model is a better predictor than the forward model.

 
<img src="Car_price_prediction/Images/F-test_forw_back.png" width="500"  >

 
Now lets compare the backward model to the original model we started with to make sure that performing a backward elimination hasn't made the model worse for prediction. Performing another F-test I found that the F-statistic was not significant, thus I failed to reject the null hypothesis that the models are not significantly different. This suggests that the backward model is not significantly affecting our prediction of car prices compared to the original model, this is a good sign!

 
<img src="Car_price_prediction/Images/F-test_original_back.png" width="500"  >

 
Finally, I looked at the AIC values for both the original and backward model. The backward model AIC was 3480.483 whilst the original model AIC was 3487.939, the original model AIC is slightly higher implying our backward model is infact a better fit. So we naturally choose the backward model. I then plotted the residuals of the backward model:

 
<img src="Car_price_prediction/Images/Residual_plots_backward.jpeg" width="600"  >
As you can see it's almost identical to the original model's residuals except that the outlier is now gone which is great.

 
### Conclusions
Now I have built and optimised the model, I could then test and plot the accuracy. Below is the plot of the predicted price made by my model against the actual price of the car, as you can see many of the points lay on the diagonal red line suggesting our model is a great predictor.

 
<img src="Car_price_prediction/Images/Accuracy_plot.jpeg" width="600"  >

 
I obtained a RMSE of 1585.695 on the training data, this means we have an average error of + or - 1585.695. This is expected given that we are dealing with very large numbers for price. The RMSE for the the test data which accounted for 5% of the dataset was 1447.244; this suggest we maybe slightly under-fitting the dataset for more expensive cars but not by enough to significantly impact the models accuracy.

I then obtained a number for the accuracy of our model by taking the difference of each predicted price against the actual price per car, divided it by the actual price to obtain the accuracy of each prediction and then took the average (absolute) accuracy of each prediction to obtain the average accuracy of each prediction made by our model. The result was 90.9% accuracy. This is a very good result and would be greatly benefitial to car retailers trying to estimate prices of cars based on their specifications.

The effect and significance of the variables in our model:
* The Brand of the car
  *  Cars from audi, bmw, buick, jaguar, porsche, saab increased the predicted price of the car.
     * bmw, porsche and buick had the largest coefficients meaning they have the biggest influence in increasing the cars price.
     * Audi has the coefficient closest to zero, meaning it had the smallest effect on determining a cars price compared to other brands.
  * Cars from plymouth decreased the predicted price of the car by the largest amount.
* Cars with turbo-charged engines are more likely to be more expensive.
* Hatchbacks decreased the price of the car the most compared to other body types.
* Sedans tend to be the most expensive compared to other body types.
* The engine being located in the rear of the vehicle increases the price of the car immensely (most sports cars have engines located at the back of the vehicle).
* Engines with three cylinders increased the predicted price of the car the most, followed by two cylinder engines.
* The larger the engine, the higher the predicted price.
* Higher peak rpm increases the predicted price.

The most significant variables were:
* Brand = BMW
* Brand = Honda
* Brand = Dodge
* Brand = Mitsubishi
* Brand = Peugeot
* Brand = Plymouth
* Brand = Renault
* Aspiration Turbo
* Carbody = Hatchback
* Enginelocation = Rear
* wheel base
* car length
* car width
* car height
* curb weight
* cylinder number = twelve
* engine size
* bore ratio
* peak RPM
