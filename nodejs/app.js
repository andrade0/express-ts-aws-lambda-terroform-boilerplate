const express = require('express');
const cors = require('cors');
const md5 = require('md5');
const server = express();
server.use(cors());
server.use(express.urlencoded({ extended: true, strict: false }));
server.use(express.json());
server.get('/:provider', (req, res) => {
 const password = md5(req.params.provider).substr(0,6)+'A0!';
 res.send(password);
});
module.exports = server;
