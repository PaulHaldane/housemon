
With a JSON data source of 

  https://api.newcastle.urbanobservatory.ac.uk/api/v1/sensor/live.json?sensor_name=new_new_emote_2763

called "emote_2763". You can configure a pane accessing the value by putting the following in the value field

  return(datasources["emote_2763"][0]["data"]["NO2"]["data"][Object.keys(datasources["emote_2763"][0]["data"]["NO2"]["data"])[0]]);

Or even the following if you want to control the number of decimal places shown

  return(datasources["emote_2763"][0]["data"]["NO2"]["data"][Object.keys(datasources["emote_2763"][0]["data"]["NO2"]["data"])[0]].toFixed(1));



Based on information from
  https://weblog.west-wind.com/posts/2017/Mar/04/Getting-JavaScript-Properties-for-Object-Maps-by-Index-or-Name

