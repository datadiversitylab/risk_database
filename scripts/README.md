Changes Made

The following changes were needed to run the IUCNN pipeline:

WWF data: The automatic download returned an HTTP 403 error. The files were downloaded manually and stored in input/official/. The script copies them to the temporary directory used by IUCNN.

Human Footprint: IUCNN could not find the raster files automatically. The 1993 and 2009 files were stored in input/human_footprint/ and copied to the expected temporary directory.

TensorFlow: Added reticulate::py_require("tensorflow") to make TensorFlow available for model training.

Predictions: The original write.csv() failed because the prediction result is not a regular data frame. The script now uses saveRDS() to save the complete prediction object.
