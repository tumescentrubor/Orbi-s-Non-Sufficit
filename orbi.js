#!/usr/bin/nodejs

var password=""
var listeningPort=8886;
var myIPaddress="192.168.86.3";


if ( ! password ) {
	var readline = require('readline').createInterface({
	        input: process.stdin,
	        output: process.stdout
	})
	readline.question("Enter Orbi admin password: ", (pw) => {
		password=pw;
		readline.close();
		initialize();
	});
} else {
	initialize();
}

function initialize() {
	require('dns').lookup(require('os').hostname(), function (err, myAddress, fam) {
		var orbiAddress=myAddress;
		var tmp=orbiAddress.split('.');
		tmp[3]=1;
		var orbiAddress=tmp.join('.');
		startNCserver();
		initialPartitionDetect(orbiAddress,myAddress,listeningPort,choosePartition);
	})
}

function choosePartition(partitionData) {
	for ( var x=0; x<partitionData.length; x++ ) {
		if ( partitionData[x].size > 10 && ( ! partitionData[x].blkid && ! partitionData[x].options.match(/^on \//) )) {
			console.log('partition '+partitionData[x].device+' is '+partitionData[x].size+' MB in size');
		}
	}
	console.log('end of choosePartition');
}

function startNCserver() {
	var netcatServer=require('netcat/server');
	var nc=new netcatServer();
	var tar=require('tar');
	tar.c(
		{ gzip: true,
		  file: 'ons-payload.tar.gz'
		},
		[ './ons-payload' ]
	).then(_ => {
		nc.port(listeningPort).serve('ons-payload.tar.gz').listen();
		console.log('serving on '+myIPaddress+':'+listeningPort);
	} );
}

function initialPartitionDetect(orbiAddress,myAddress,listeningPort,callback) {
  var et=require("expect-telnet");
  var result;
  et(orbiAddress+":23", [
	{expect: "login", send: "admin\r"},
	{expect: "assword", send: password+"\r"},
	{expect: "#", send: "cd /tmp/device_tables\r"},
	{expect: "#", send: "pwd\r"},
	{expect: "#", out: function (output) {
	  console.log("working directory is "+output);
	 }, send: "\r" },
	{expect: "#", send: "waiting for server to spin up; sleep 5\r"},
	{expect: "#", send: "nc "+ myAddress +" "+ listeningPort +" > ons-payload.tar.gz\r" },
	{expect: "#", out: function (output) {
           console.log("result of netcat is "+output);
         }, send: "\r" },
	//{expect: "#", send: "chmod a+x test.sh\r"},
	{expect: "#", send: "tar xvfz ons-payload.tar.gz\r"},
	{expect: "#", send: "./ons-payload/partition_info.sh\r"},
	{expect: "#", out: function (output) {
	  result=JSON.parse(output);
	  if ( typeof(callback) == "function" ) {
		console.log('executing callback function');
		callback(result);
	  }
	}, send: "exit\r"}
  ], {exit: true, timeout: 10000 }, function(err) {
	if (err) console.error(err);
  });
}
