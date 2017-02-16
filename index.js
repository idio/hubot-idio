'use strict'

const fs = require('fs')
const {resolve} = require('path')

module.exports = (robot) => {
  const path = resolve(__dirname, 'src')
  if (fs.existsSync(path)) {
    fs.readdirSync(path).forEach(s => robot.loadFile(path, s))
  }
}
