const util = require("util");
const gis = util.promisify(require("g-i-s"));

exports.handler = async (event) => {
  const rs = await gis("nyan");
  console.log(JSON.stringify(event, null, 2));
  console.log(JSON.stringify(rs, null, 2));
};
