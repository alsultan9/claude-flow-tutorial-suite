// Main entry point
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Error handling
try {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
} catch (error) {
  console.error('Failed to start server:', error);
  process.exit(1);
}
// Error handling added by Dr. House Auto-Fix
// Error handling added by Dr. House Auto-Fix
// Error handling added by Dr. House Auto-Fix
// Error handling added by Dr. House Auto-Fix
