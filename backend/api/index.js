const app = require('../dist/app').default;

module.exports = (req, res) => {
  return app(req, res);
};
