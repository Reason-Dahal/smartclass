const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { upload, uploadToCloudinary } = require('../utils/upload');

// Upload assignment submission file
router.post('/submission', protect, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { code: 'NO_FILE', message: 'No file uploaded' },
      });
    }

    const fileUrl = await uploadToCloudinary(req.file.buffer, 'submissions');

    res.status(200).json({
      success: true,
      data: { fileUrl },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'UPLOAD_ERROR', message: error.message },
    });
  }
});

// Upload note file
router.post('/note', protect, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { code: 'NO_FILE', message: 'No file uploaded' },
      });
    }

    const fileUrl = await uploadToCloudinary(req.file.buffer, 'notes');

    res.status(200).json({
      success: true,
      data: { fileUrl },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'UPLOAD_ERROR', message: error.message },
    });
  }
});

module.exports = router;