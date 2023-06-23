const path = require("path");

require("dotenv").config({
  path: path.join(__dirname, ".env"),
});

exports.get = (key, defaultValue) => {
  return process.env[key] || defaultValue;
};
