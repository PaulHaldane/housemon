var url = 'http://192.168.0.45:8080/mongo/sensor/range/from/1540331263/to/1540332763/sensor/D1.1';

drawgraph();

function drawgraph(){
  // define dimensions of graph
  var m = [80, 80, 80, 80]; // margins
  var w = 1000 - m[1] - m[3]; // width
  var h = 400 - m[0] - m[2]; // height
  
  var x_dim_accessor = function(d){return d.ts};
  var y_dim_accessor = function(d){return d.val};

  var x_range;
  var y_range;
  
  // create a simple data array that we'll plot with a line (this array represents only the Y values, X will just be the index location)
  d3.json(url, function(error, json){
    var data;
    if(!json) json = error; //not sure why error seems to contain the data!...
    if(json[0] && json[0].summary){
      data = json[0].summary;
    }else{
      data = json;
    }

    x_range = [
      d3.min(data, x_dim_accessor),
      d3.max(data, x_dim_accessor)
    ];

    y_range = [
      d3.min(data, y_dim_accessor),
      d3.max(data, y_dim_accessor)
    ];
    render(data); 
  });

  function render(data){
     
    // X scale will fit all values from data[] within pixels 0-w
    var x = d3.scale.linear().domain(x_range).range([0, w]);
    // Y scale will fit values from 0-10 within pixels h-0 (Note the inverted domain for the y-scale: bigger is up!)
    var y = d3.scale.linear().domain(y_range).range([h, 0]);
      // automatically determining max range can work something like this
      // var y = d3.scale.linear().domain([0, d3.max(data)]).range([h, 0]);

    // create a line function that can convert data[] into x and y points
    var line = d3.svg.line()
      // assign the X function to plot our line as we wish
      .x(function(d,i) { 
        return x(x_dim_accessor(d)); 
      })
      .y(function(d) { 
        return y(y_dim_accessor(d)); 
      })

      // Add an SVG element with the desired dimensions and margin.
      var graph = d3.select("#graph").append("svg:svg")
            .attr("width", w + m[1] + m[3])
            .attr("height", h + m[0] + m[2])
          .append("svg:g")
            .attr("transform", "translate(" + m[3] + "," + m[0] + ")");

      // create yAxis
      var xAxis = d3.svg.axis().scale(x).tickSize(-h).tickSubdivide(true);
      // Add the x-axis.
      graph.append("svg:g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + h + ")")
            .call(xAxis);


      // create left yAxis
      var yAxisLeft = d3.svg.axis().scale(y).ticks(4).orient("left");
      // Add the y-axis to the left
      graph.append("svg:g")
            .attr("class", "y axis")
            .attr("transform", "translate(-25,0)")
            .call(yAxisLeft);
      
        // Add the line by appending an svg:path element with the data line we created above
      // do this AFTER the axes above so that the line is above the tick-lines
      graph.append("svg:path").attr("d", line(data));
  }
}
style.css#
/* tell the SVG path to be a thin blue line without any area fill */
path {
  stroke: steelblue;
  stroke-width: 1;
  fill: none;
}

.axis {
  shape-rendering: crispEdges;
}

.x.axis line {
  stroke: lightgrey;
}

.x.axis .minor {
  stroke-opacity: .5;
}

.x.axis path {
  display: none;
}

.y.axis line, .y.axis path {
  fill: none;
  stroke: #000;
}

