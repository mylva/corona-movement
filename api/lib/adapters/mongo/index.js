const fs = require('fs')
const { MongoClient } = require('mongodb')
const userCollection = require('./users')
const stepsCollection = require('./steps')
const codesCollection = require('./codes')
const steps = require('./steps')

let caBundle = fs.readFileSync(`${__dirname}/rds-combined-ca-bundle.pem`)
let inited
const DB_NAME = process.env.DB_NAME ? process.env.DB_NAME : 'coronamovement'
const options =
  process.env.NODE_ENV === 'production'
    ? {
        ssl: true,
        sslValidate: false,
        sslCA: caBundle,
      }
    : {}

const init = async () => {
  const client = await MongoClient.connect(process.env.CONNECT_TO, options)
  const db = client.db(DB_NAME)
  await Promise.all([
    userCollection.init(db),
    stepsCollection.init(db),
    codesCollection.init(db),
  ])
  inited = true
}

module.exports = {
  // steps
  saveSteps: stepsCollection.save,
  getAverageHour: stepsCollection.getAverageHour,
  getHours: stepsCollection.getHours,
  getDailyAverages: stepsCollection.getDailyAverages,
  getSummary: stepsCollection.getSummary,
  getLastUpload: stepsCollection.getLastUpload,
  removeStepsForUser: stepsCollection.removeStepsForUser,
  // users
  createUser: userCollection.create,
  getUser: userCollection.get,
  updateUser: userCollection.update,
  removeUser: userCollection.remove,
  // codes
  codeExists: codesCollection.codeExists,
  inited: async () => {
    if (!inited) await init()
    return true
  },
}
