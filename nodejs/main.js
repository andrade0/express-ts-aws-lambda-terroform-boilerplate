'use strict'

const async = require('async');

exports.handler = function(event, context, callback) {
  async.each([1,2], (_var, cb)=>{
    cb();
  }, ()=>{
    console.log('fdfd');
  });
  var response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8'
    },
    body: '<p>Hello world!</p>'
  }
  callback(null, response)
}
