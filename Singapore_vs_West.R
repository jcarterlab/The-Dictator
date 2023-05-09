library(dplyr)
library(tidyverse)
library(tibble)
library(gmp)

# creates a data frame of singapore vs the west EIU demcoracy index
EIU <- tibble(
  country = c("Singapore", "US", "UK", "Canada", "AUS", "NZ"),
  rank = c(70, 30, 18, 12, 15, 2)
)

# reverses the ranking and orders countries by rank
EIU$rank <- 167 - EIU$rank
EIU <- EIU[order(EIU$rank,decreasing=FALSE),]

# creates a barplot of countries by the Economist's assessment of their democracy
barplot(EIU$rank, names.arg=c(pull(EIU[1])), col="purple", 
        main="EIU Democracy rank",  ylab="Global rank (1-167)")




### election coding rules:
# 1) included are all elections since Singapore's first in 1959, or the most recent in which leaders are elected by popular vote
# 2) a change is when another party takes power and coalitions are counted as a win for the party receiving more of the vote
# 3) in cases where multiple parties and coalitions compete, changes are coded to ideology (conservative, liberal etc.) rather than specific party
# 4) in cases where there is both a president and a prime minister, the position which holds more power in the relevant country is counted


# lists election results by country for singapore and the west
Singapore <- tibble(
  country = c(rep("Singapore",14)),
  election = c(1959,1963,1968,1972,1976,1980,1984,1988,1991,2001,2006,2011,2015,2020),
  change = c(rep(0,14))
)
US <- tibble(
  country = c(rep("US",16)),
  election = c(1960,1964,1968,1972,1976,1980,1984,1988,1992,1996,2000,2004,2008,2012,2016,2020),
  change = c(1,0,1,0,1,1,0,0,1,0,1,0,1,0,1,1)
)
UK <- tibble(
  country = c(rep("UK",16)),
  election = c(1964,1966,1970,1974,1974,1979,1983,1987,1992,1997,2001,2005,2010,2015,2017,2019),
  change = c(1,0,1,1,0,1,0,0,0,1,0,0,1,0,0,0)
)
Canada <- tibble(
  country = c(rep("Canada",20)),
  election = c(1962,1963,1965,1968,1972,1974,1979,1980,1984,1988,1993,1997,2000,2004,2006,2008,2011,2015,2019,2021),
  change = c(0,1,0,0,0,0,1,1,1,0,1,0,0,0,1,0,0,1,0,0)
)
AUS <- tibble(
  country = c(rep("AUS",24)),
  election = c(1961,1963,1966,1969,1972,1974,1975,1977,1980,1983,1984,1987,1990,1993,1996,1998,2001,2004,2007,2010,2013,2016,2019,2022),
  change = c(0,0,0,0,1,0,1,0,0,1,0,0,0,0,1,0,0,0,1,0,1,0,0,1)
)
NZ <- tibble(
  country = c(rep("NZ",21)),
  election = c(1960,1963,1966,1969,1972,1975,1978,1981,1984,1987,1990,1993,1996,1999,2002,2005,2008,2011,2014,2017,2020),
  change = c(1,0,0,0,1,1,0,0,1,0,1,0,0,1,0,0,1,0,0,1,0)
)



# gets a scatter plot of election results between UK and Singapore
get_scatter <- function(df, title='') {
  n <- nrow(df)
  color <- list()
  for(i in 1:nrow(df)) {
    color[i] <- if(df$change[i]==0) 'red' else 'blue'
  }
  set.seed(123)
  c <- tibble(
    height = rnorm(n, mean=5, sd=1.2),
    width = rnorm(n, mean=5, sd=1.25),
    change = unlist(color)
  )
  plot(c$height, c$width,
       xaxt='n', yaxt='n', 
       pch=19, cex=1.75, col=c$change, 
       xlab='', ylab='', main = title)
}
par(mfrow = c(3, 2))
get_scatter(Singapore, 'Singapore')
get_scatter(US, 'US')
get_scatter(UK, 'UK')
get_scatter(Canada, 'Canada')
get_scatter(AUS, 'AUS')
get_scatter(NZ, 'NZ')
legend("topright", inset = c(0, 0),
       legend = c("Change","Remain"),
       pch = 19,
       col = c('red', 'blue'))




# combines western democracies into a single data frame for analysis
west <- US %>% rbind(UK) %>% rbind(Canada) %>% rbind(AUS) %>% rbind(NZ)


contingency_table <- tibble(
  change = c("Change", "Remain"),
  Singapore = c(sum(Singapore$change), sum(Singapore$change==0)),
  West = c(sum(west$change),sum(west$change==0))
)
table <- column_to_rownames(contingency_table, "change")


# print the change ratio of each country
change_ratio <- function(country) {
  return(sum(country$change)/length(country$election))
}

# returns data on on the change rate of each country
get_change_ratios <- function(countries) {
  change_rate <- list()
  for(i in 1:length(countries)) {
    change_rate[i] = (change_ratio(eval(parse(text=countries[i])))*100)
  }
  # creates and returns an ordered data frame of each country's change rate
  change_rate_df <- tibble(country=countries, change_rate=unlist(change_rate))
  return(change_rate_df[order(change_rate_df$change_rate,decreasing=TRUE),])
}
# creates a data frame of the change rate results
change_rate_df <- get_change_ratios(c("Singapore", "US", "UK", "Canada", "AUS","NZ"))



# creates a barplot of countries by change rate
barplot(change_rate_df$change_rate, names.arg=c(pull(change_rate_df[1])), 
        col="darkgreen", ylab="Change rate (%)", main="Change rate")




# fisher's exact test (one-tailed p-values)
fishers_test <- function(var_1,var_2,one_tail=FALSE) {
  # two tailed p-value calculation (by default)
  if(one_tail==TRUE) {
    # creates contingency table variables
    a = as.bigz(sum(var_1==0))
    b = as.bigz(sum(var_2==0))
    c = as.bigz(sum(var_1==1))
    d = as.bigz(sum(var_2==1))
    n = a+b+c+d
    # one-tailed p-value calculation (if chosen)
    nom = factorial(a+b)*factorial(c+d)*factorial(a+c)*factorial(b+d)
    denom = factorial(n)*factorial(a)*factorial(b)*factorial(c)*factorial(d)
    return(as.numeric(nom/denom))
  }
  else if(one_tail==FALSE) {
    df = tibble(singapore = c(sum(var_1==0), sum(var_1==1)), 
                west = c(sum(var_2==0), sum(var_2==1)))
    result <- fisher.test(df)
    return(result$p.value)
  }
}
# returns the likelihood Singaporean election results occurred by chance
result <- fishers_test(Singapore$change, west$change, one_tail=TRUE)

# prints the percentage likelihood the results could have occurred by chance
print(paste0("Likelihood results occurred by chance --- ", round(result*100,2),'%'))



# returns the results of fisher's exact test using different sample sizes
get_samples_results <- function(a,b,samples) {
  # lists the samples results at different sizes
  sample_results <- list()
  for(i in 1:length(samples)) {
    # sets seed for sample reproducibility.
    set.seed(2012)
    sample_results[i] <- fishers_test(a, sample(b, samples[i]))
  }
  # creates a data frame for sample size and resulting p-values
  sample_results_df <- tibble(
    size = samples,
    results = unlist(sample_results)
  )
  return(sample_results_df)
}
# plots the decline in the p-value as sample size increases
sample_results_df <- get_samples_results(Singapore$change, west$change, c(seq(10,90,10)))
plot(sample_results_df$size, sample_results_df$results, type="o", col="red", xlab="West samples", ylab="P-value", main = "P-value vs sample size")
abline(h=0.05, col="blue")





