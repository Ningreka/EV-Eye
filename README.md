# EV-Eye: Rethinking High-frequency Eye Tracking through the Lenses of Event Cameras

## Summary
[[todo]]:结果的图像化，方法过程
<br/>

## Dataset

You can download the data from  xxx ,which consists of

- raw_data
  
  Data_davis : From user1 to user48, all eye tracking data collected using event cameras, including data from left and right eyes, for each user including four sessions.
  ```
  ─Data_davis
  ├─user1
  │  ├─left
  │  │  ├─session_1_0_1
  │  │  │  ├─events
  │  │  │  └─frames
  │  │  ├─session_1_0_2
  │  │  │  ├─events
  │  │  │  └─frames
  │  │  ├─session_2_0_1
  │  │  │  ├─events
  │  │  │  └─frames
  │  │  └─session_2_0_2
  │  │      ├─events
  │  │      └─frames
  │  └─right
  │      ├─session_1_0_1
  │      │  ├─events
  │      │  └─frames
  │      ├─session_1_0_2
  │      │  ├─events
  │      │  └─frames
  │      ├─session_2_0_1
  │      │  ├─events
  │      │  └─frames
  │      └─session_2_0_2
  │          ├─events
  │          └─frames
  ```
  
  Data_davis_labelled_with_mask: Use the code in '/matlab_data_processing' to label the position of the pupils in frames captured by the event camera, and save the labels as an hdf5 file.
  ```
  ─Data_davis_labelled_with_mask
  ├─left
  │  ├─user1_session_1_0_2.h5
  │  │─user1_session_2_0_1.h5
  │  ..........
  ├─right
  │  ├─user1_session_1_0_2.h5
  │  │─user1_session_2_0_1.h5
  │  ..........
  ```
  
  Data_tobii: Eye tracking data collected using Tobii
  ```
  -Data_tobii
  ├─ user1 
  │  ├─tobiisend.txt
  │  ├─ tobiittl.txt
  │  ├─session_1_0_1
  │        ├─diameter.csv
  │        ├─diameter.txt
  │        ├─eventdata
  │        ├─eventdata.gz
  │        ├─gazedata
  │        ├─gazedata.gz
  │        ├─gazedata.txt
  │        ├─imudata
  │        ├─imudata.gz
  │        ├─recording.g3
  │        ├─scenevideo.mp4
  │        ├─snap0.jpg
  │        ├─meta
  ```

- processed_data
  
  Data_davis_predict: 
  Using the algorithm, estimated pupil images were obtained from the grayscale images for each user's session 102, 201, and 202.

  Frame_event_pupil_track_result:
  
  Pixel_error_evaluation:
  
  Pre-trained_models:


<br/>

## Requirements

```
python>=3.6
torch>=1.9.0
numpy>=1.21.0
tqdm>=4.61.1
h5py>=3.2.1
torchvision>=0.10.0
argparse>=1.1
```
To install requirements:
```angular2html
pip install -r requirements.txt
```


## Installation

```
pip install -r requirements.txt

cd ./dataset

#download checkpoints
wget xxx

python train.py

python predict.py
```

[//]: # (<br/>)

## Training

To train the model(s) in the paper, run this command:
```
python train.py
```

## Pre-trained Models

You can download pretrained models here:

## Results

## Citation

If you would like to use our code or dataset, please cite either

```
@inproceedings{,  
  title={EV-Eye: Rethinking High-frequency Eye Tracking through the Lenses of Event Cameras},  
  author={Guangrong Zhao, Yiran Shen, Yurun Yang, Jingwei Liu, Ning Chen, Hongkai Wen, Guohao Lan},  
  year={2023}  
} 
```

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.
