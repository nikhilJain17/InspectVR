var app = require('express')();
var http = require('http').Server(app);
var request = require('request');
var io = require('socket.io')(http);
var fs = require('fs');

var util = require('util');
var log_file = fs.createWriteStream(__dirname + '/debug.log', {flags : 'w'});
var log_stdout = process.stdout;

console.log = function(d) { //
  log_file.write(util.format(d) + '\n');
  log_stdout.write(util.format(d) + '\n');
};

var friends = [{ name: "Rishi", points: 0 }, { name: "Rohan", points: 0 }, { name: "Nikhil", points: 0 }, { name: "Shashank", points: 0 }];

function sortByKey(array, key) {
    return array.sort(function(a, b) {
        var x = a[key]; var y = b[key];
        return ((x > y) ? -1 : ((x < y) ? 1 : 0));
    });
}

var getLeaderboard = function(){
	return sortByKey(friends, "points");
};

var tasks = ["do stuff one", "mow the lawn", "eat coconuts", "do stuff two"];

io.on("connection", function(socket){

	socket.on("want tasks", function(){
		console.log("want tasks");
		io.emit("got tasks", tasks);

	});

});

// require('dotenv').config({path: __dirname + '/../.env'});

var app = require('express')();
var https = require('https');

app.use(require('body-parser').urlencoded({ extended: false }));

app.get('/inbound-sms-webhook', function (req, res) {
  console.log("get: " + req.query.text);
  //req.query.text is text message

  var data = JSON.stringify({
    api_key: 'b1226615',
    api_secret: 'fc224eb979640d5a',
    to: 17327427351,
    // Above number is the user's number
    from: 12675097488,
    text: req.query.text
  })

  var options = {
    host: 'api.nexmo.com',
    path: '/tts/json',
    port: 443,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data)
    }
  };

  var req = https.request(options);

  req.write(data);
  req.end();

  var responseData = '';
  req.on('response', function(res){
    res.on('data', function(chunk){
      responseData += chunk;
    });

    res.on('end', function(){
      console.log(JSON.parse(responseData));
    });
  });

  handleWebhook(req.query, res);
});

app.post('/inbound-sms-webhook', function (req, res) {
  console.log("post: " + req.body.text);
  handleWebhook(req.body, res);
});

function handleWebhook(params, res) {
  console.log(params);

  var from = params['msisdn']; // the number that send the message
  var to = params['to']; // the Long Virtual Number the message was sent to
  var text = params['text'];
  var timestamp = params['message-timestamp'];
  var type = params['type']; // text, unicode or binary


  res.sendStatus(200);
}

app.listen(app.get('port'), function() {
  console.log('Example app listening on port', app.get('port'));
});

app.get("/up", function(req, resp){
	io.emit("up");
	console.log("up")
});

app.get("/down", function(req, resp){
	io.emit("down");
	console.log("down")
});

app.get("/right", function(req, resp){
	io.emit("right");
	console.log("right")
});

app.get("/left", function(req, resp){
	io.emit("left");
	console.log("left")
});

app.get("/deposit", function(req, resp){

	request({ url: "http://api.reimaginebanking.com/accounts/57d4203ce63c5995587e867e/deposits?key=f22e0b663e5763bc27e5a5b03f49999b", method: 'POST', json: {
	  "medium": "balance",
	  "transaction_date": "2016-09-10",
	  "amount": 10,
	  "description": "string"
	}}, function(err, res, body){
		if (err){
			console.log(err);
		}
		resp.send("<h1>Deposit</h1>");
		console.log("10 points added to account.");
	});

});

app.get("/withdraw", function(req, resp){

	request({ url: "http://api.reimaginebanking.com/accounts/57d4203ce63c5995587e867e/withdrawals?key=f22e0b663e5763bc27e5a5b03f49999b", method: 'POST', json: {
	  "medium": "balance",
	  "transaction_date": "2016-09-10",
	  "amount": 10,
	  "status": "pending",
	  "description": "string"
	}}, function(err, res, body){
		resp.send("<h1>Withdrawal</h1>");
		console.log("10 points removed from account.");
	});

});

http.listen(8080, function(){
	console.log("Listening on *:8080");
});
