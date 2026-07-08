const express = require('express');
const router = express.Router();
const {
  createProgram, getPrograms, updateProgram,
  createBatch, getBatches,getAllBatches, promoteBatch,
  updateBatch,deactivateBatch,deactivateProgram, 
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);
router.use(authorize('admin'));

// Program routes
router.post('/', createProgram);
router.get('/', getPrograms);
router.patch('/:id', updateProgram);
router.delete('/:id',deactivateProgram);

// Batch routes (nested under programs)
router.post('/:programId/batches', createBatch);
router.get('/:programId/batches', getBatches);
router.get('/batches', getAllBatches);
router.patch('/batches/:id',updateBatch);
router.delete('/batches/:id',deactivateBatch);

// Promotion (separate path — acts on a batch by its own ID)
router.post('/batches/:id/promote', promoteBatch);

module.exports = router;