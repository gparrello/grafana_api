pacman::p_load(
  "ConfigParser",
  "httr"
)

submit_predictions <- function(config_file, df){
 
  config <- ConfigParser$new()
  config <- config$read(config_file)
  host <- config$get(option='host', section='DEFAULT')
  team <- config$get(option='team', section='DEFAULT')
  token <- config$get(option='token', section='DEFAULT')
  protocol <- 'http://'
  
  # get team id
  headers <- add_headers(
    "Content-Type" = "application/json",
    "Authorization" = paste("Bearer", token),
    "Prefer" = "return=representation"
  )
  endpoint <- 'teams'
  condition <- paste('name=eq.', team, sep='')
  url <- paste(protocol, host, '/', endpoint, '?', condition, sep='')
  r <- GET(url, headers)
  if (length(content(r)) == 0) {
    return("error! no team with that name!")
  } else if (length(content(r)) == 1) {
    team_id <- content(r)[[1]][["id"]]
  } else {
    print(http_status(r)$message)
    return("error! more than one team with that name???")
  }
  
  # post submission and get submission id
  endpoint <- 'submissions'
  url <- paste(protocol, host, '/', endpoint, sep='')
  payload <- list(
    team_id = team_id,
    records_num = nrow(df),
    timestamp = format(Sys.time(), '%Y-%m-%d %H:%M:%S')
  )
  r <- POST(url, body = payload, encode = "json", headers)
  if (length(content(r)) == 1) {
    submission_id <- content(r)[[1]][["id"]]
  } else {
    return("error! more than one submission posted at the same time???")
  }
  
  # post predictions
  headers <- add_headers(
    "Content-Type" = "application/json",
    "Authorization" = paste("Bearer", token),
    "Prefer" = "return=minimal"
  )
  endpoint <- 'predictions'
  url <- paste(protocol, host, '/', endpoint, sep='')
  df$submission_id <- submission_id
  payload <- df[,c('submission_id', 'usernum', 'datediff', 'quantity')]
  r <- POST(url, body = payload, encode = "json", headers)
  
  status <- http_status(r)$message
  return(status)
   
}
