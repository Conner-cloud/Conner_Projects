set.seed(1)
stress.raw <- read.csv('C:/Users/conne/Downloads/ScreenTime vs MentalWellness.csv', header = T)

library(tidyverse)
library(gamlss)
library(performance)
library(caret)

factor.levels = c('awful', 'poor', 'decent', 'good', 'excellent', 
                  'Male', 'Female', 'Non-binary/Other',
                  'Unemployed', 'Retired', 'Student', 'Self-employed', 'Employed',
                  'Remote', 'Hybrid', 'In-person'
)

stress.clean <- stress.raw %>%
  mutate(
    user_id = NULL,
    X = NULL,
    age = as.numeric(age),
    gender = factor(gender,
                    ordered = T, 
                    levels = c('Male', 'Female', 'Non-binary/Other')
    ),
    occupation = factor(occupation, 
                        ordered = T, 
                        levels = c('Unemployed', 'Retired', 'Student', 'Self-employed', 'Employed')
    ),
    work_mode = factor(work_mode,
                       ordered = T, 
                       levels = c('Remote', 'Hybrid', 'In-person')
    ),
    sleep_quality = factor(
      case_when(
        sleep_quality_1_5 == 1 ~ 'awful',
        sleep_quality_1_5 == 2 ~ 'poor',
        sleep_quality_1_5 == 3 ~ 'decent',
        sleep_quality_1_5 == 4 ~ 'good',
        sleep_quality_1_5 == 5 ~ 'excellent'
      ),
      ordered = T,
      levels = c('awful', 'poor', 'decent', 'good', 'excellent')
    ),
    sleep_quality_1_5 = NULL,
    stress_level = case_when(
      stress_level_0_10 == 10 ~ 0.999,
      stress_level_0_10 == 0 ~ 0.001,
      .default = stress_level_0_10/10
    ),
    productivity = productivity_0_100/100,
    productivity_0_100 = NULL,
    stress_level_0_10 = NULL,
    exercise_minutes_per_week = as.numeric(exercise_minutes_per_week),
    mental_wellness_index_0_100 = NULL # This is very similar to our dependent variable.
  )
# Some of these factors are ordered simply to play nicer with pivot.longer

long.table.numeric.only <- stress.clean %>%
  select(!where(is.ordered)) %>%
  pivot_longer(!starts_with('stress_level'))

ggplot(data = long.table.numeric.only, aes(value, stress_level)) +
  theme_bw() +
  geom_jitter(shape = 1, position = position_jitter(width = .1, height = .1)) +
  geom_smooth(method = 'gam') +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('Stress against numeric independents')

long.table.factor.only <- stress.clean %>%
  select(where(is.ordered)) %>%
  mutate(across(!starts_with('stress_level'), ~factor(., ordered = T, levels = factor.levels)),
  stress_level = stress.clean$stress_level) %>%
  pivot_longer(!starts_with('stress_level'))

ggplot(data = long.table.factor.only, aes(value, stress_level)) +
  theme_bw() +
  geom_boxplot() +
  facet_wrap(~name, scales = 'free_x') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle('Stress against independent factors')

# from these plots we can see that there is significant correlation between some of the independent variables and
# stress level, most notable are:
# leisure_screen_hours, mental_wellness_index, productivity, screen_time_hours, sleep_hours, sleep_quality,
# work_screen_hours.
# Mental wellness index is also a trap as it is directly correlated to stress inherently

ggplot(data = stress.clean, aes(stress_level)) +
  theme_bw() +
  geom_bar(stat = 'count', width = .005) +
  ggtitle('Distribution of stress')
# The dependent variable is extremely one inflated, there also exists points that are exactly 0.

# Picking the optimal factors to explain smoothing functions
stress.factors.only <- stress.clean %>% select(!where(is.numeric))

###### Screen time ######
screentime.against.factors <- 
  cbind(stress.factors.only, 'screen_time_hours' = stress.clean$screen_time_hours) %>%
  mutate(across(!ends_with('screen_time_hours'), ~factor(., ordered = T, levels = factor.levels ))) %>%
  pivot_longer(!ends_with('screen_time_hours'))

ggplot(data = screentime.against.factors, aes(value, screen_time_hours)) +
  theme_bw() +
  geom_boxplot() +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('screen time hours against factors') +
  xlab('Category') +
  ylab('Screen time (hours)') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# From these plots, we can see that occupation shows the largest variance between categories for screen_time
# I will chose this factor to explain the smoothing function of screen_time
###### END ######

###### Sleep hours ######
sleephours.against.factors <- 
  cbind(stress.factors.only, 'sleep_hours' = stress.clean$sleep_hours) %>%
  mutate(across(!ends_with('sleep_hours'), ~factor(., ordered = T, levels = factor.levels ))) %>%
  pivot_longer(!ends_with('sleep_hours'))

ggplot(data = sleephours.against.factors, aes(value, sleep_hours)) +
  theme_bw() +
  geom_boxplot() +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('sleep hours against factors') +
  xlab('Category') +
  ylab('sleep time (hours)') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Occupation appears again to variate most significantly with sleep time. Unemployed and retired sleep the longest
# Students appear to sleep the least. This could be due to nights out for example.
###### END ######

###### Exercise ######
exercise.against.factors <- 
  cbind(stress.factors.only, 'exercise_mins_per_week' = stress.clean$exercise_minutes_per_week) %>%
  mutate(across(!ends_with('exercise_mins_per_week'), ~factor(., ordered = T, levels = factor.levels ))) %>%
  pivot_longer(!ends_with('exercise_mins_per_week'))

ggplot(data = exercise.against.factors, aes(value, exercise_mins_per_week)) +
  theme_bw() +
  geom_boxplot() +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('exercise minutes per week against factors') +
  xlab('Category') +
  ylab('Exercise minutes (per week)') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Exercise is best described by occupation
###### END ######

###### Social Hours ######
socialhours.against.factors <- 
  cbind(stress.factors.only, 'social_hours_per_week' = stress.clean$social_hours_per_week) %>%
  mutate(across(!ends_with('social_hours_per_week'), ~factor(., ordered = T, levels = factor.levels ))) %>%
  pivot_longer(!ends_with('social_hours_per_week'))

ggplot(data = socialhours.against.factors, aes(value, social_hours_per_week)) +
  theme_bw() +
  geom_boxplot() +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('social hours per week against factors') +
  xlab('Category') +
  ylab('Social hours (per week)') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

###### END ######

###### Productivity ######
productivity.against.factors <- 
  cbind(stress.factors.only, 'productivity' = stress.clean$productivity) %>%
  mutate(across(!ends_with('productivity'), ~factor(., ordered = T, levels = factor.levels ))) %>%
  pivot_longer(!ends_with('productivity'))

ggplot(data = productivity.against.factors, aes(value, productivity)) +
  theme_bw() +
  geom_boxplot() +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('productivity against factors') +
  xlab('Category') +
  ylab('productivity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

###### END ######

# Fit BEOI model

# work_mode & sleep_quality have extremely high VIFs suggesting servere multicollinearity
# pb(screen_time_hours, by = occupation), occupation & pb(productivity, by = occupation) have high VIFs
# suggested actions: 
# remove sleep quality from the model, it has high multi-collinearity with multiple variables

long.table.numeric.only %>%
  filter(stress_level >= .95) %>%
  ggplot(aes(value, stress_level)) +
  theme_bw() +
  geom_jitter(shape = 1, position = position_jitter(width = .1, height = .1)) +
  geom_smooth(method = 'gam') +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('Distribution of numeric independents with stress >= 0.95')

# There is no visible correlation between the numeric variables and stress being close to 1

stress.factors.only %>% 
  cbind('stress_level' = stress.clean$stress_level) %>%
  filter(stress_level >= .95) %>%
  mutate(across(!ends_with('stress_level'), ~factor(., ordered = T, levels = factor.levels ))) %>%
  pivot_longer(!starts_with('stress_level')) %>%
  ggplot(aes(value, fill = name)) +
  theme_bw() +
  geom_bar() +
  facet_wrap(~name, scales = 'free_x') +
  ggtitle('Distribution of independent factors with stress >= 0.95') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# We don't have a variable that clearly correlates with stress being equal to 1
# Hence we will use nu.forumla ~ 1

# k-fold cross validation
k <- 10 # The number of folds performed
cycles <- 200 # Number of GAMLSS iterations to find optimal parameters
folds <- createFolds(stress.clean$stress_level, k = k, list = T, returnTrain = F)
performance_rmse <- numeric(k)
performance_mae <- numeric(k)
performance_Rsqr <- numeric(k)
performance_StDev <- numeric(k)
ALL_Actuals <- list()
ALL_Predicted <- list()

# Due to the limited amount of data we should implement k-fold cross validation.
for (i in 1:k) {
  
  print(paste('Interation:', i, sep = ' '))
  test_indices <- folds[[i]]
  
  test <- stress.clean[test_indices,]
  train <- stress.clean[-test_indices,]
  
  model_no_nu <- gamlss(stress_level ~ 
                        pb(screen_time_hours, by = occupation) +
                        pb(sleep_hours, by = occupation) +
                        pb(exercise_minutes_per_week, by = occupation) +
                        pb(social_hours_per_week, by = occupation) +
                        pb(productivity, by = occupation) +
                        pb(work_screen_hours, by = occupation) +
                        pb(leisure_screen_hours, by = occupation) +
                        age + gender + occupation + work_mode,
                      sigma.formula = ~
                        pb(screen_time_hours, by = occupation) +
                        pb(productivity, by = occupation) +
                        pb(sleep_hours, by = occupation) +
                        age + gender + occupation + work_mode,
                      nu.formula = ~ 1,
                      family = BEOI,
                      data = train,
                      control = gamlss.control(n.cyc = cycles)
  )
  
  predicted <- predict(model_no_nu, newdata = test, what = 'mu', type = 'response')
  actuals <- test$stress_level
  
  # Stores performance metrics from each fold
  rmse <- sqrt(mean((predicted - actuals)^2))
  performance_rmse[i] <- rmse
  mae <- mean(abs(predicted - actuals))
  performance_mae[i] <- mae
  Rsqr <- Rsq(model_no_nu)
  performance_Rsqr[i] <- Rsqr
  StdDev <- sd(actuals)
  performance_StDev[i] <- StdDev
  
  # Stores results from each fold
  ALL_Actuals[[i]] <- test$stress_level
  ALL_Predicted[[i]] <- predicted
}

# Model goodness of fit checks
summary(model_no_nu)
plot(model_no_nu)
wp(model_no_nu)
check_collinearity(model_no_nu)

# Store results in a data frame
results <- data.frame(
  actual = unlist(ALL_Actuals),
  predicted = unlist(ALL_Predicted)
)

avg_rmse <- round(mean(performance_rmse), 4)
avg_mae <- round(mean(performance_mae), 4)
avg_StDev <- round(mean(performance_StDev), 4)
avg_Rsqr <- round(mean(performance_Rsqr), 4)

results$distance <- abs(results$actual-results$predicted)

ggplot(data = results) +
  theme_bw() +
  scale_color_gradient2(
    low = 'green',
    mid = 'red',
    high = 'red',
    midpoint =  .5,
    limits = c(0,1)
  ) +
  geom_point(size = 2, aes(x = actual, y = predicted, col = distance)) +
  geom_abline(slope = 1, intercept = 0, linetype = 'dashed', col = 'red', lwd = .75) +
  geom_text(aes(x = .1, y = 1, label = paste('RMSE', avg_rmse))) +
  geom_text(aes(x = .1, y = .95, label = paste('MAE', avg_mae))) +
  geom_text(aes(x = .1, y = .9, label = paste('Std Dev', avg_StDev))) +
  geom_text(aes(x = .1, y = .85, label = paste('Rsq', avg_Rsqr))) +
  xlim(0,1) +
  ylim(0,1) +
  ggtitle('Predicted vs Actuals: 10-folds cross-validation')