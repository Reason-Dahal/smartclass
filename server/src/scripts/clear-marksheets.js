require('dotenv').config();
const connectDB = require('../config/db');
const Marksheet = require('../models/Marksheet');

const clearMarksheets = async () => {
  await connectDB();
  const result = await Marksheet.deleteMany({});
  console.log(`Marksheet records deleted: ${result.deletedCount}`);
  process.exit(0);
};

clearMarksheets().catch((error) => {
  console.error('Failed:', error.message);
  process.exit(1);
});