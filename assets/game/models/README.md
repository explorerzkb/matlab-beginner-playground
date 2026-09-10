# MoveNet runtime model

`movenet-single-lightning.tflite` is Google's SinglePose Lightning model, Kaggle TfLite `singlepose-lightning/1`, archive member `3.tflite`, distributed under Apache-2.0. SHA-256: `0491b130b2dd622d71a180936e957212341daca78e9f6a04e0d9c2045eff2ecb`.

Source: https://www.kaggle.com/models/google/movenet/TfLite/singlepose-lightning/1

The game runs it locally through MATLAB's TFLite interface, once per fixed player region. No runtime download, Python, account, or network service is used. MATLAB + Deep Learning Toolbox + TFLite interface support package + USB Webcams support package + Parallel Computing Toolbox are required. The latter provides the tested process worker, not model code generation. MATLAB Coder is not required by this execution path.

The MultiPose benchmark uses the separately downloaded official `multipose-lightning-tflite-float16/1` model and `tools/fix_multipose_shape.mjs`; it is not the default game model because of measured latency on this machine.
