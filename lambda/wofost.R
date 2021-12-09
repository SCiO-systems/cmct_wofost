library("jsonlite")
library("Rwofost")

handler = function(body, ...){
  tryCatch(
    {
      input_json <- fromJSON(txt = body)
    
      local_save_file_path = "/tmp/weather_example.csv" 
      
      download.file(url =  input_json[["file_url"]],local_save_file_path)
      # read downloaded data
      data = read.csv(local_save_file_path)
      # change date column to data format recognizable from R
      data$date <- as.Date(data$date)
      
      # initialize "control" parameters
      contr <- wofost_control()
      
      # apply user control parameters
      for (name in names(input_json$control_params)) {
        # print(name)
        if (name=="modelstart"){
          # t = input_json$control_params[name]
          # print(input_json$control_params[[name]])
          contr[[name]] = as.Date(input_json$control_params[[name]])
        }
        else{
          contr[[name]] = input_json$control_params[[name]]
        }
      } 
      # crop and soil parameters
      crop <- wofost_crop(input_json$crop)
      soil <- wofost_soil(input_json$soil)
      
      
      # run model
      model_ID <- wofost_model(crop, data, soil, contr)
      response = run(model_ID)
      return(
        list(
          statusCode = 200,
          headers = list("Content-Type" = "application/json"),
          body = toJSON(response)
        )
      )
    },
    
    error=function(error_message) {
      
      response = toString(error_message)
      response = substr(response,1,nchar(response)-1)
      return(
        list(
          statusCode = 400,
          headers = list("Content-Type" = "application/json"),
          body = toJSON(response)
        )
      )
    }
  )
  
  

}
