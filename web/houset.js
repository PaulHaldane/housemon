var arrDweet = [];

var dweetThing = '';

if (typeof localStorage.arrDweet != 'undefined'){
    try{
      //arrDweet = JSON.parse(localStorage.arrDweet);
    }catch(err){
      //console.error(err);
      //arrDweet = [];
      //localStorage.removeItem('arrDweet');
    }
}

dweetio.get_all_dweets_for(dweetThing, function(err, dweets){
    for(theDweet in dweets)
    {
        var thedweet = dweets[theDweet];
        arrDweet.push(thedweet)
    }
    draw(arrDweet,true);
});

dweetio.listen_for(dweetThing, function(dweet){
  arrDweet.push(dweet)

  if (arrDweet.length > 100){
    arrDweet = arrDweet.slice(1,arrDweet.length);
    console.info('array sliced')
  }

  console.log(arrDweet.length);
  localStorage.arrDweet = JSON.stringify(arrDweet);
  draw(arrDweet,false);
});


// set the dimensions and margins of the graph
var margin = {top: 20, right: 20, bottom: 30, left: 50},
    width = 890 - margin.left - margin.right,
    height = 250 - margin.top - margin.bottom;

// set the ranges
var x = d3.scaleTime().range([0, width]);
var y = d3.scaleLinear().range([height, 0]);

// define the line
var valueline = d3.line()
    .x(function(d) { return x(new Date(d.content.ts * 1000)); })
    .y(function(d) { return y(d.content.val); });
//     .x(function(d) { return x(new Date(d.content.ts * 1000)); })

// append the svg object to the body of the page
// appends a 'group' element to 'svg'
// moves the 'group' element to the top left margin
var svg = d3.select("body").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform",
          "translate(" + margin.left + "," + margin.top + ")");

function draw(data,init) {
  // Scale the range of the data
  x.domain(d3.extent(data, function(d) { return new Date(d.content.ts * 1000); }));
  // y.domain(d3.extent(data, function(d) { return d.content.val; }));
  y.domain([0,24]);
  if(init){
    // Add the valueline path.
    svg.append("path")
        .attr("class", "line")
        .attr("d", valueline(data));

    // Add the X Axis
    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x));

    // Add the Y Axis
    svg.append("g")
        .attr("class", "y axis")
        .call(d3.axisLeft(y));

  }else{
      var svgupd = d3.select("body").transition();
    // Make the changes
        svgupd.select(".line")   // change the line
            .duration(250)
            .attr("d", valueline(data));
        svgupd.select(".x.axis") // change the x axis
            .duration(250)
            .call(d3.axisBottom(x));
        svgupd.select(".y.axis") // change the y axis
            .duration(250)
            .call(d3.axisLeft(y));
  }
}
