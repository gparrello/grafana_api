source('./client.R')
df <- read.csv("./data.csv")
status <- submit_predictions('./config.ini.sample', df)
print(status)