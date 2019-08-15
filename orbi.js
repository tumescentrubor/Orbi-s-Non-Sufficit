#!/usr/bin/nodejs

var global=new Object();
var listeningPort=8886;
var myIPaddress="192.168.86.3";
var targetPartition='';

if ( ! global.password ) {
    var readline = require('readline').createInterface({
	input: process.stdin,
	output: process.stdout
    })
    readline.question("Enter Orbi admin password: ", (pw) => {
	global.password=pw;
	readline.close();
	initialize();
    });
} else {
    initialize();
}

function initialize() {
    require('dns').lookup(require('os').hostname(), function (err, myAddress, fam) {
	global.orbiAddress=myAddress;
	var tmp=global.orbiAddress.split('.');
	tmp[3]=1;
	global.orbiAddress=tmp.join('.');
	startNCserver();
	initialPartitionDetect(myAddress,listeningPort,choosePartition);
    })
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
    function initialPartitionDetect(myAddress,listeningPort,callback) {
	var et=require("expect-telnet");
	var result;
	et(global.orbiAddress+":23", [
	    {expect: "login", send: "admin\r"},
	    {expect: "assword", send: global.password+"\r"},
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
	    {expect: "#", send: "tar xvfz ons-payload.tar.gz\r"},
	    {expect: "#", send: "./ons-payload/partition_info.sh\r"},
	    {expect: "#", out: function (output) {
		result=JSON.parse(output);
		if ( typeof(callback) == "function" ) {
		    callback(result);
		}
	    }, send: "exit\r"}
	], {exit: true, timeout: 10000 }, function(err) {
	    if (err) console.error(err);
	});
    }
}

function choosePartition(partitionData) {
    var emptyPartitions=[];
    for ( var x=0; x<partitionData.length; x++ ) {
	if ( partitionData[x].size > 10 && ( ! partitionData[x].blkid && ! partitionData[x].options.match(/^on \//) )) {
	    emptyPartitions.push( { "device":partitionData[x].device, "size":partitionData[x].size } );
	}
    }
    function ask() {
	for ( var x=0; x<emptyPartitions.length; x++ ) {
	    console.log("choice "+(x+1)+": "+emptyPartitions[x].device+" "+emptyPartitions[x].size+" MB")
	}
	var readline = require('readline').createInterface({
	    input: process.stdin,
	    output: process.stdout
	})
	readline.question("type number of partition to format and use: ", (p) => {
	    readline.close();
	    p = parseInt(p);
	    if ( typeof(p) == "number" && p < emptyPartitions.length ) {
		setup(emptyPartitions[p-1].device);
	    } else {
		console.log('"'+p+'? seriously?');
		ask();
	    }
	});
    }
    ask();
}

function setup(partition) {
    var et=require("expect-telnet");
    var result;
    et(global.orbiAddress+":23", [
	{expect: "login", send: "admin\r"},
	{expect: "assword", send: global.password+"\r"},
	{expect: "#", send: "cd /tmp/device_tables\r"},
	{expect: "#", send: "./ons-payload/subvert_bd.sh /usr/heyafubar "+partition+"\r"},
	{expect: "#", out: function (output) {
	    console.log(output);
	}, send: "exit\r"}
    ], {exit: true, timeout: 10000 }, function(err) {
	if (err) console.error(err);
    });
}

