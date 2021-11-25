install.packages(c("ggplot2", "base", "olsrr", "dplyr", "ML metrics"))
library("ggplot2"); library("base"); library("olsrr");library("dplyr"); set.seed(123)
Car_Price <- read.csv("D:/Documents/Projects/Car_price_Regression/Cars.csv", header = T)
head(Car_Price)
str(Car_Price)

# Cleaning the Data, there are many car names listed, some are incorrect, this reduces the number of unique variables listed.
# e.g. volkswagen golf 2007 becomes VW
Car_Price$CarName[grep("alfa-romero", Car_Price$CarName)] <- "alfa-romero"
Car_Price$CarName[grep("audi", Car_Price$CarName)] <- "audi"
Car_Price$CarName[grep("bmw", Car_Price$CarName)] <- "bmw"
Car_Price$CarName[grep("buick", Car_Price$CarName)] <- "buick"
Car_Price$CarName[grep("chev", Car_Price$CarName)] <- "chevrolet"
Car_Price$CarName[grep("dodge", Car_Price$CarName)] <- "dodge"
Car_Price$CarName[grep("honda", Car_Price$CarName)] <- "honda"
Car_Price$CarName[grep("isuzu", Car_Price$CarName)] <- "isuzu"
Car_Price$CarName[grep("jag", Car_Price$CarName)] <- "jaguar"
Car_Price$CarName[grep("maxda", Car_Price$CarName)] <- "maxda"
Car_Price$CarName[grep("mazda", Car_Price$CarName)] <- "mazda"
Car_Price$CarName[grep("mercury", Car_Price$CarName)] <- "mercury"
Car_Price$CarName[grep("mitsub", Car_Price$CarName)] <- "mitsubishi"
Car_Price$CarName[grep("issan", Car_Price$CarName)] <- "nissan"
Car_Price$CarName[grep("peug", Car_Price$CarName)] <- "peugeot"
Car_Price$CarName[grep("plymouth", Car_Price$CarName)] <- "plymouth"
Car_Price$CarName[grep("por", Car_Price$CarName)] <- "porsche"
Car_Price$CarName[grep("saab", Car_Price$CarName)] <- "saab"
Car_Price$CarName[grep("subaru", Car_Price$CarName)] <- "subaru"
Car_Price$CarName[grep("ren", Car_Price$CarName)] <- "renault"
Car_Price$CarName[grep("toy", Car_Price$CarName)] <- "toyota"
Car_Price$CarName[grep("volks", Car_Price$CarName)] <- "vw"
Car_Price$CarName[grep("vok", Car_Price$CarName)] <- "vw"
Car_Price$CarName[grep("vw", Car_Price$CarName)] <- "vw"
Car_Price$CarName[grep("volvo", Car_Price$CarName)] <- "volvo"

colnames(Car_Price)[3] <- "Brand"

# Creating test and train data sets
sample_size <- floor(0.95 * nrow(Car_Price))
train_id <- sample(seq_len(nrow(Car_Price)), size = sample_size)
train <- Car_Price[train_id,]
test <- Car_Price[-train_id,]

# Lets plot the distribution of Car brands
count <- rle(Car_Price$Brand)$lengths
brand <- rle(Car_Price$Brand)$value

ggplot() + 
  geom_bar(aes(x = count, y=reorder(brand, +count), fill = count),
           stat = "identity", show.legend = F) +
  ggtitle("Distribution of car brands") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        plot.title = element_text(size = 15)) +
  xlab("Number of Models") + ylab("Brand Name")
  

# Lets plot the density of the number of car brands and the density of prices
plot(density(count), main = "Density of Car Brands", xlab = "Number of models", col = "red", lwd = 2)
plot(density(Car_Price$price), main = "Density of Car Prices", xlab = "Price of the Car", col = "blue", lwd = 2)
  
# building a model
fitted_model <- lm(price ~ ., data = train)
summary(fitted_model)
# p-value: < 2.2e-16 implies at least one variable is significantly related to the price of the car. Reject H0
# The model does a very good job at predicting the price of the car.
# The remove Car_ID from model as it is an index variable.

fitted_model <- update(fitted_model, formula = . ~ . - car_ID)
summary(fitted_model)
# Adj R squared is 0.9521 suggesting the model is a good fit. However, there are many insignificant variables.

# Residuals for basic model
standardized_residuals <- rstandard(fitted_model)
studentized_residuals <- rstudent(fitted_model)
raw_residuals <- residuals(fitted_model)
cbind(observed = train$price, fitted = fitted(fitted_model), raw = raw_residuals, 
      standardized = standardized_residuals, studentized = studentized_residuals)

# Plot of residuals of Price variable
par(mfrow = c(2, 2))
plot(fitted_model)

# Residuals vs fitted
# Linearity: Almost straight red line which is good
# Zero Mean: Equal amount of points above and below black dotted line (good)

# Normal QQ plot
# Points very closely follow diagonal which is good.

# Scale-Location
# check assumption of constant variance: Horizontal line is good with randomly scattered points

# Residual vs leverage
# One influential observation can be seen (135 bottom right)

# Selecting the best model
backward_elimination <- ols_step_backward_p(fitted_model, prem = 0.05)
summary(backward_elimination$model)

forward_selection <- ols_step_forward_p(fitted_model, penter = 0.05)
summary(forward_selection$model)

# Comparing models
anova(backward_elimination$model, forward_selection$model)
# Significant F test suggests there is significant difference between the forward and backward model.

# Backward elimination model has a better R square.
backward_model <- backward_elimination$model
coef(backward_model)
# Given the F-test and comparing the values of R square we have enough evidence to suggest the backward model is better

# Lets compare this model to the original
anova(backward_model, fitted_model)
# F test shows us that the models do not differ significantly. Hence we can use the simpler (backward) one.

AIC(backward_model)
AIC(fitted_model)
# Our Backward model has lower AIC implying it's a better fit.

# Confidence Intervals
confint(backward_model)

# Model Accuracy
backward_model_rmse <- train %>%
  mutate(pred.reg.train = predict(backward_model)) # produces estimates using our model

# Plot the actual price against the predicted price from our model
plot(backward_model_rmse$price, backward_model_rmse$pred.reg.train)
abline(0,1, col = "red")
# Strong positive correlation suggests out model is a very good predictor of car prices.
# There are a two outliers where our model is predicting quite a bit under the actual amount.

# Mean Square error
mse <- backward_model_rmse %>%
  mutate(error = pred.reg.train - price,
         sq.error = error^2) %>%
  summarise(mse = mean(sq.error))
rmse <- sqrt(mse)
rmse 
# we have an average error of plus or minus 1585.695, this is very good, especially considering most values are above 10000

# Check rmse on test data
pred_test <- predict(backward_model, newdata = test)
rmse_test <- sqrt((mean((pred_test - test$price)^2)))
rmse_test
# rmse of 1447.244 for the test data, our model maybe slightly under-fitting the data.

# Lets again look at the plot of residuals of our backward elimination model
standardized_residuals <- rstandard(backward_model)
studentized_residuals <- rstudent(backward_model)
raw_residuals <- residuals(backward_model)
cbind(observed = train$price, fitted = fitted(backward_model), raw = raw_residuals, 
      standardized = standardized_residuals, studentized = studentized_residuals)

par(mfrow = c(2, 2))
plot(backward_model)
# Plot of residuals look good.

# Lets calculate the accuracy of the model
predicted <- backward_model_rmse$pred.reg.train
actual <- train$price
difference <- ((actual-predicted)/actual)
  
accuracy <- 1-mean(abs(difference))
accuracy
# We obtained a model that is 90.9 % accurate at predicting car prices.
# This model can accurately depict the price of a car based on it's specifications and would be beneficial to car retailers.

# Using backward elimination, we can say that these factors were the most important in determining the price of a car:
# The Brand of the car had a large impact on it's price
  # Cars from audi, bmw, buick, jaguar, porsche, saab increased the price of the car
    # bmw, porsche and buick had the largest coefficients meaning they have the biggest influence in increasing the cars price
    # Audi has the coefficient closest to zero, meaning it had the lowest impact on determining a cars price
  # Cars from plymouth decreased the predicted price of the car by the largest amount.
  # Turbocharged engines increased the price of the car
  # Hatchbacks decreased the price of the car the most compared to other body types
  # Sedans tend to be the most expensive
  # The engine being located in the rear of the vehicle increases the price of the car immensely (this is expected as they're likely modern sports cars).
  # Three and two cylinder engines tend to be the most expensive (this could be due to older sports cars which inflate the price/power ratio we expect)
