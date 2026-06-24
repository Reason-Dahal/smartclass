const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  overrideAttendance,
  overrideMarksheet,
  uploadFinalResults,
  getEvaluationConfig,
  updateEvaluationConfig,
  getSystemReports,
} = require('../controllers/adminController');

router.use(protect);
router.use(authorize('admin'));

router.patch('/attendance/:id', overrideAttendance);
router.patch('/marksheets/:id', overrideMarksheet);
router.post('/final-results', uploadFinalResults);
router.get('/evaluation-config', getEvaluationConfig);
router.patch('/evaluation-config', updateEvaluationConfig);
router.get('/reports', getSystemReports);

module.exports = router;