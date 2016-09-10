//code
var app = require('express')();
var http = require('http').Server(app);
var request = require('request');
var io = require('socket.io')(http);

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