---
  title: 'Project B: Algorithmic Trading Strategy Simulation'
author: 'Tobias Beck, Laura Lonardi, Lydia Papazoglou TEAM ID: 100015'
date: "Oct 2, 2018"
output:
  pdf_document: default
word_document: default
---
  
  ```{r setup, include=FALSE}
###### Importing Libraries

library(tidyquant)
library(xts)
library(ggplot2)
library(readxl)
library(reshape)
library(dplyr)
#library(forecast)
library(tseries)
library(knitr)
library(lubridate)

##### Functions


sf <- function(pivot_stock,weight_vector,start_date,end_date,k_lag)
{
  
  ptf_return = 0
  ptf_date = 0
  date_char = 0
  date_vector <- pivot_stock$d
  date_char = as.character(pivot_stock$d)
  
  start_index <- match(start_date, date_char)
  end_index <- match(end_date, date_char)  
  
  time_period <- end_index - start_index + k_lag + 1
  
  pivot_stock_clean = pivot_stock[,-1]
  
  for(i in (k_lag+1):nrow(pivot_stock))     
  {
    ptf_return[i-k_lag]=crossprod(as.numeric(pivot_stock_clean[i,]),as.numeric(weight_vector[i-k_lag,]))
    ptf_date[i-k_lag]=pivot_stock[i,1]  
  }
  
  year_vector_full <- as.POSIXct(pivot_stock$d[(k_lag+1):length(pivot_stock$d)])
  year_vector_full <- strftime(year_vector_full, "%Y")
  
  ptf_return = as.data.frame(ptf_return[start_index:end_index])
  year_vector <- year_vector_full[start_index:end_index]
  
  ##mean
  strategy_mean <-aggregate(.~year_vector, ptf_return, FUN = mean)
  strategy_mean[,2] <- strategy_mean[,2] *  252
  colnames(strategy_mean) <- c("date","mean")
  
  ##sd
  strategy_sd <- aggregate(.~year_vector, ptf_return, FUN = sd)
  strategy_sd[,2] <- strategy_sd[,2] *  sqrt(252)
  colnames(strategy_sd) <- c("date","sd")
  sharpe_ratio = strategy_mean$mean / strategy_sd$sd
  
  final = cbind(strategy_mean, strategy_sd[,2], sharpe_ratio)  
  colnames(final) <- c("Year","Mean","Standard Dev", "Sharpe Ratio")
  
  return(final)
}

vsf <- function(pivot_stock,start_date,end_date)
{
  date_char = 0
  date_vector <- pivot_stock$d
  date_char = as.character(pivot_stock$d)
  
  start_index <- match(start_date, date_char)
  end_index <- match(end_date, date_char)  
  
  pivot_stock_clean = pivot_stock[,-1]
  pivot_stock_clean = pivot_stock_clean[start_index:end_index,]
  
  mean_across_stock = 0 
  for (i in 1: ncol(stock_pivot_clean))
  {
    mean_across_stock[i] <- sum(stock_pivot_clean[,i])/nrow(stock_pivot_clean[,i])
  }
  mean_across_stock = mean_across_stock *252
  stock_id = as.vector(colnames(stock_pivot_clean))
  mean_across_stock = as.data.frame(cbind(stock_id, mean_across_stock))
  colnames(mean_across_stock) = c("id", "r")
  
  return(mean_across_stock)
}

###### Strategy Set Up
stocks_df_95 = read_excel("C:/Users/Laura/Desktop/MIT Fall 2018/Financial Data Science/Assignment/Assignment #2/Raw_Data_Dec95.xlsx")
stocks_df_96 = read_excel("C:/Users/Laura/Desktop/MIT Fall 2018/Financial Data Science/Assignment/Assignment #2/Raw Data.xlsx")
stocks_df = rbind(stocks_df_95, stocks_df_96)

stocks_df_id = stocks_df[,c(2,5)]
stocks_df_ticker = stocks_df[,c(1,2,5)]
stock_pivot <- spread(stocks_df_ticker, key = id, value = r)
stock_pivot_clean <- stock_pivot[,-1]
returns <-aggregate(.~d,stocks_df_id,FUN = mean)
excess_returns <- apply(stock_pivot_clean,2,'-',returns$r)
ticker_count = nrow(stock_pivot)
c = 0
for(i in 1:ticker_count)
{
  c[i] <- 2/sum(abs(excess_returns[i,]))
}

weights <- apply(excess_returns, 2, '*',-c)
portfolio_return=0

for(i in 2:ticker_count)     
{
  portfolio_return[i-1]=crossprod(as.numeric(stock_pivot_clean[i,]),as.numeric(weights[i-1,]))
}

portfolio_return <- as.data.frame(portfolio_return)

## Part a
date_vector <- stock_pivot$d
date_vector <- date_vector[-1]
portfolio_return_date <- cbind(date_vector, portfolio_return)
colnames(portfolio_return_date) <- c("date","r")

p_portfolio_returns <- ggplot () + 
  geom_line (data = portfolio_return_date, aes(x = portfolio_return_date$date, y=portfolio_return_date$r), color = "green") 

print(p_portfolio_returns)

p_daily_mkt <- ggplot () + 
  geom_line (data = returns, aes(x = returns$d, y=returns$r), color = "green") 

print(p_daily_mkt)

## Part b
statistics_lag1 = sf(stock_pivot,weights,"1996-01-02","2001-12-31",1)
statistics_lag1

## Part c
Box.test(portfolio_return, type = "Ljung-Box")
adf.test(xts(portfolio_return_date$r, order.by = portfolio_return_date$date ))
pacf(xts(portfolio_return_date$r, order.by = portfolio_return_date$date ))
acf(xts(portfolio_return_date$r, order.by = portfolio_return_date$date ))


## Part d
plot(returns$d,returns$r)
boxplot(returns$r)

outliers = boxplot(returns$r)$out
outliers_indexes <- which(returns$r %in% outliers)

outlier_date_list <- returns[outliers_indexes,]

qqplot(returns$d,returns$r)
hist(returns$r, breaks = 50)

# Individual Stock Average Return
mean_across_stock <- vsf(stock_pivot,"1996-01-02","2001-12-31")
mean_across_stock_clean <- as.numeric(as.vector(mean_across_stock[,2]))

plot(mean_across_stock_clean)
boxplot(mean_across_stock_clean)

outliers_by_stock = boxplot(mean_across_stock_clean)$out
outliers_indexes_by_stock <- which(mean_across_stock_clean %in% outliers_by_stock)

outliers_stock_list <- mean_across_stock[outliers_indexes_by_stock,]

qqnorm(mean_across_stock_clean);qqline(mean_across_stock_clean, col = 2)
hist(mean_across_stock_clean, breaks = 50)

non_outliers_stock_list <- mean_across_stock_clean[-outliers_indexes_by_stock]
outliers_stock_list_2 <- mean_across_stock_clean[outliers_indexes_by_stock]

stock_mean_all <- sum(mean_across_stock_clean)/length(mean_across_stock_clean)
stock_mean_outliers <- sum(outliers_stock_list_2)/length(outliers_stock_list_2)
stock_mean_ex_outliers <- sum(non_outliers_stock_list)/length(non_outliers_stock_list)

length(mean_across_stock_clean)
length(non_outliers_stock_list)
length(outliers_stock_list_2)

stock_mean_all
stock_mean_outliers
stock_mean_ex_outliers

## Part e

returns_1996 <- returns[-1,]
correlation <- cor(returns_1996$r,portfolio_return_date$r, use = "complete.obs")
correlation

portfolio_return_long=0
portfolio_return_short=0

ticker_count_ticker = ncol(stock_pivot) - 1

stock_pivot_clean_long = matrix(0,ticker_count,ticker_count_ticker)
weights_long = matrix(0,ticker_count,ticker_count_ticker)

stock_pivot_clean_short = matrix(0,ticker_count,ticker_count_ticker)
weights_short = matrix(0,ticker_count,ticker_count_ticker)

for (i in 1:ticker_count)
{
  for (j in 1:ticker_count_ticker)
  {
    if(weights[i,j] >= 0)
    {
      stock_pivot_clean_long[i,j] = as.numeric(stock_pivot_clean[i,j])
      weights_long[i,j] = as.numeric(weights[i,j])
    }
    else
    {
      stock_pivot_clean_short[i,j] = as.numeric(stock_pivot_clean[i,j])
      weights_short[i,j] = as.numeric(weights[i,j])
    }
  }
}



for(i in 1: (ticker_count-1))     
{
  portfolio_return_long[i]=crossprod(as.numeric(stock_pivot_clean_long[i+1,]),as.numeric(weights_long[i,]))
  portfolio_return_short[i]=crossprod(as.numeric(stock_pivot_clean_short[i+1,]),as.numeric(weights_short[i,]))
  
}


correlation_long_short <- cor(portfolio_return_long,portfolio_return_short, use = "complete.obs")
correlation_long_short


###### Strategy Set Up for Question #2
stocks_df_q2 = read_excel("C:/Users/Laura/Desktop/MIT Fall 2018/Financial Data Science/Assignment/Assignment #2/Dataset_1996-2001_updated.xlsx")
stocks_df_id_q2 = stocks_df_q2[,c(3,8)]
stocks_df_ticker_q2 = stocks_df_q2[,c(3,2,8)]
stock_pivot_q2 <- spread(stocks_df_ticker_q2, key = id, value = r)
stock_pivot_clean_q2 <- stock_pivot_q2[,-1]
returns_q2 <-aggregate(.~d,stocks_df_id_q2,FUN = mean)
excess_returns_q2 <- apply(stock_pivot_clean_q2,2,'-',returns_q2$r)
ticker_count_q2 = nrow(stock_pivot_q2)
date_vector_q2 <- stock_pivot_q2$d
date_vector_q2 <- date_vector_q2[-1]

# Sort the returns for every date to get the first and last decile that is continually changing and calculate the portfolio return
dates_count = nrow(stock_pivot_q2)
first_decile_q2 <- as.integer(0.1*ncol(stock_pivot_clean_q2))
last_decile_start_q2 <- as.integer(0.9*ncol(stock_pivot_clean_q2))
last_decile_end_q2 <- ncol(stock_pivot_clean_q2)

portfolio_return_q2=0
long_portfolio_q2_returns_q2=0
short_portfolio_q2_returns_q2=0

for(i in 1:dates_count)
{
  stock_pivot_c_q2 <- stock_pivot_clean_q2[i,]
  stock_pivot_clean_sorted_q2 <- as.data.frame(apply(stock_pivot_c_q2,1,sort))
  first_decile_returns_q2 <- as.data.frame(stock_pivot_clean_sorted_q2[1:first_decile_q2,])
  last_decile_returns_q2 <- as.data.frame(stock_pivot_clean_sorted_q2[(last_decile_start_q2+1):last_decile_end_q2,])
  
  weights_first_decile_q2 <- first_decile_returns_q2/sum(first_decile_returns_q2)
  weights_last_decile_q2 <- last_decile_returns_q2/sum(last_decile_returns_q2)
  
  stock_pivot_clean_sorted_q2 <- add_rownames(stock_pivot_clean_sorted_q2, "VALUE")
  names(stock_pivot_clean_sorted_q2)[1]<-"id"
  names(stock_pivot_clean_sorted_q2)[2]<-"return_t"
  
  if (i<dates_count) {
    # Sort stock_pivot_clean_sorted_ver_df based on id 
    stock_t_sorted_id_q2 <- stock_pivot_clean_sorted_q2[order(stock_pivot_clean_sorted_q2$id),]
    
    stock_t_1_df_q2 <- stock_pivot_clean_q2[i+1,]
    stock_t_1_ver_q2 <- t(stock_t_1_df_q2)
    stock_t_1_ver_df_q2 <- as.data.frame(stock_t_1_ver_q2)
    stock_t_1_ver_df_q2 <- add_rownames(stock_t_1_ver_df_q2, "VALUE")
    names(stock_t_1_ver_df_q2)[1]<-"id"
    names(stock_t_1_ver_df_q2)[2]<-"return_t+1"
    stock_t_1_sorted_id_q2 <- stock_t_1_ver_df_q2[order(stock_t_1_ver_df_q2$id),]
    
    stock_t_and_t_1_v1_q2 <- cbind(stock_t_sorted_id_q2,stock_t_1_sorted_id_q2)
    stock_t_and_t_1_q2 <- stock_t_and_t_1_v1_q2[-c(3)]
    stock_t_and_t_1_sorted_return_q2 <- stock_t_and_t_1_q2[order(stock_t_and_t_1_q2$return_t),]
    
    # Remove columns id and return_t
    stock_t_and_t_1_sorted_clean_return_q2 <- stock_t_and_t_1_sorted_return_q2[-c(1:2)]
    
    # Create the two dataframes containing the returns for t+1 that correspond to weights for time t
    first_decile_eq_returns_t_1_q2 <- as.data.frame(stock_t_and_t_1_sorted_clean_return_q2[1:first_decile_q2,])
    last_decile_eq_returns_t_1_q2 <- as.data.frame(stock_t_and_t_1_sorted_clean_return_q2[(last_decile_start_q2+1):last_decile_end_q2,])
    
    portfolio_return_q2[i] = -sum(last_decile_eq_returns_t_1_q2[,1]*weights_last_decile_q2[,1]) + sum(first_decile_eq_returns_t_1_q2[,1]*weights_first_decile_q2[,1])
    long_portfolio_q2_returns_q2[i] = sum(first_decile_eq_returns_t_1_q2[,1]*weights_first_decile_q2[,1])
    short_portfolio_q2_returns_q2[i] = -sum(last_decile_eq_returns_t_1_q2[,1]*weights_last_decile_q2[,1])
  }
}

portfolio_return_q2 <- as.data.frame(portfolio_return_q2)
long_portfolio_q2_returns_q2 <- as.data.frame(long_portfolio_q2_returns_q2)
short_portfolio_q2_returns_q2 <- as.data.frame(short_portfolio_q2_returns_q2)

## Part a, Question 2
portfolio_return_date_q2 <- cbind(date_vector_q2, portfolio_return_q2)
colnames(portfolio_return_date_q2) <- c("date","r")

p_portfolio_returns_q2 <- ggplot () + 
  geom_line (data = portfolio_return_date_q2, aes(x = portfolio_return_date_q2$date, y=portfolio_return_date_q2$r), color = "blue") + ggtitle("Daily portfolio returns") + xlab("Date") + ylab("Returns") + theme(plot.title = element_text(hjust = 0.5))

print(p_portfolio_returns_q2)

p_daily_mkt_q2 <- ggplot () + 
  geom_line (data = returns, aes(x = returns$d, y=returns$r), color = "blue") + ggtitle("Daily market returns") + xlab("Date") + ylab("Returns") + theme(plot.title = element_text(hjust = 0.5))

print(p_daily_mkt_q2)

## Part b, Question 2

## Portfolio
year_vector_q2 <- as.POSIXct(portfolio_return_date_q2$date)
year_vector_q2 <- strftime(year_vector_q2, "%Y")

portfolio_return_by_year_q2 <- cbind(year_vector_q2,portfolio_return_q2)

##mean portfolio
strategy_mean_q2 <-aggregate(.~year_vector_q2, portfolio_return_by_year_q2, FUN = mean)
strategy_mean_q2[,2] <- strategy_mean_q2[,2] *  252
colnames(strategy_mean_q2) <- c("date","mean")

##annualized mean
mean_return_q2 <- apply(portfolio_return_q2,2,mean)
annualized_mean_q2 <- mean_return_q2 * 252

##sd portfolio 
strategy_sd_q2 <- aggregate(.~year_vector_q2, portfolio_return_by_year_q2, FUN = sd)
strategy_sd_q2[,2] <- strategy_sd_q2[,2] *  sqrt(252)
colnames(strategy_sd_q2) <- c("date","sd")
sharpe_ratio_q2 = strategy_mean_q2$mean / strategy_sd_q2$sd

final_q2 = cbind(strategy_mean_q2, strategy_sd_q2[,2], sharpe_ratio_q2)  
colnames(final_q2) <- c("Year","Mean","Standard Dev", "Sharpe Ratio")
final_q2

## Annualized SD
sd_q2 <- apply(portfolio_return_q2,2,sd)
annualized_sd_q2 <- sd_q2 * sqrt(252)

annualized_sharpe_ratio_q2 <- annualized_mean_q2/annualized_sd_q2

## Market
year_vector_q2_market <- as.POSIXct(returns_q2$d)
year_vector_q2_market <- strftime(year_vector_q2_market, "%Y")
returns_metrics_q2 <- returns_q2[-c(1)]
market_return_by_year_q2 <- cbind(year_vector_q2_market,returns_metrics_q2)

##mean market
strategy_mean_q2_market <-aggregate(.~year_vector_q2_market, market_return_by_year_q2, FUN = mean)
strategy_mean_q2_market[,2] <- strategy_mean_q2_market[,2] *  252
colnames(strategy_mean_q2_market) <- c("date","mean")

##sd portfolio 
strategy_sd_q2_market <- aggregate(.~year_vector_q2_market, market_return_by_year_q2, FUN = sd)
strategy_sd_q2_market[,2] <- strategy_sd_q2_market[,2] *  sqrt(252)
colnames(strategy_sd_q2_market) <- c("date","sd")
sharpe_ratio_q2_market = strategy_mean_q2_market$mean / strategy_sd_q2_market$sd

final_q2_market = cbind(strategy_mean_q2_market, strategy_sd_q2_market[,2], sharpe_ratio_q2_market)  
colnames(final_q2_market) <- c("Year","Mean","Standard Dev", "Sharpe Ratio")
final_q2_market


## Part c, Question 2
Box.test(portfolio_return_q2, type = "Ljung-Box")
adf.test(xts(portfolio_return_date_q2$r, order.by = portfolio_return_date_q2$date ))
pacf(xts(portfolio_return_date_q2$r, order.by = portfolio_return_date_q2$date ))
acf(xts(portfolio_return_date_q2$r, order.by = portfolio_return_date_q2$date ))

## Part e, Question 2
returns_1996_q2 <- returns_q2[-1,]
correlation_q2 <- cor(returns_1996_q2$r,portfolio_return_date_q2$r, use = "complete.obs")
correlation_q2

## Part f, Question 2
correlation_long_short_q2 <- cor(long_portfolio_q2_returns_q2,short_portfolio_q2_returns_q2, use = "complete.obs")
correlation_long_short_q2

##########Question 3

#### Lags 2 to 10
statistics_lag2 = sf(stock_pivot,weights,"1996-01-03","2001-12-31",2)
statistics_lag2

statistics_lag3 = sf(stock_pivot,weights,"1996-01-04","2001-12-31",3)
statistics_lag3

statistics_lag4 = sf(stock_pivot,weights,"1996-01-05","2001-12-31",4)
statistics_lag4

statistics_lag5 = sf(stock_pivot,weights,"1996-01-08","2001-12-31",5)
statistics_lag5

statistics_lag6 = sf(stock_pivot,weights,"1996-01-09","2001-12-31",6)
statistics_lag6

statistics_lag7 = sf(stock_pivot,weights,"1996-01-10","2001-12-31",7)
statistics_lag7

statistics_lag8 = sf(stock_pivot,weights,"1996-01-11","2001-12-31",8)
statistics_lag8

statistics_lag9 = sf(stock_pivot,weights,"1996-01-12","2001-12-31",9)
statistics_lag9

statistics_lag10 = sf(stock_pivot,weights,"1996-01-15","2001-12-31",10)
statistics_lag10