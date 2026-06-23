const express = require('express');
const router = express.Router();
const {
  createProgram, getPrograms, updateProgram,
  createBatch, getBatches, promoteBatch,
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);
router.use(authorize('admin'));

// Program routes
router.post('/', createProgram);
router.get('/', getPrograms);
router.patch('/:id', updateProgram);

// Batch routes (nested under programs)
router.post('/:programId/batches', createBatch);
router.get('/:programId/batches', getBatches);

// Promotion (separate path — acts on a batch by its own ID)
router.post('/batches/:id/promote', promoteBatch);

module.exports = router;