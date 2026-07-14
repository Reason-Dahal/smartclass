const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const { upload } = require('../utils/upload'); 
const {
  uploadFinalResults,
  getEvaluationConfig,
  updateEvaluationConfig,
  getSystemReports,
} = require('../controllers/adminController');

router.use(protect);
router.use(authorize('admin'));

router.post('/final-results', upload.single('file'), uploadFinalResults);
router.get('/evaluation-config', getEvaluationConfig);
router.patch('/evaluation-config', updateEvaluationConfig);
router.get('/reports', getSystemReports);

module.exports = router;