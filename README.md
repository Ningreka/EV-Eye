# EV-Eye: Rethinking High-frequency Eye Tracking through the Lenses of Event Cameras

## Introduction EV-Eye
We introduce the largest and most diverse multi-modal frame-event dataset for high frequency eyetracking in the literature (totally over 170Gb). 
We propose a novel hybrid frame-event eye tracking benchmarking approach tailored to the collected dataset, capable of tracking the pupil at a frequency up to 38.4kHz. 
<br/>
<br/>

![summary](pictures/main.jpg)

<br/>

## A quick Youtube demo for introduction
[![IMAGE_ALT](pictures/EV.png)](https://youtu.be/Yi03mFAyslU)


## Dataset organization

You can download the data from [https://1drv.ms/f/s!Ar4TcaawWPssqmu-0vJ45vYR3OHw](https://), which consists of:

- raw_data 

Data_davis: Including near-eye gryscale images in and event streams captured by two sets of DAVIS346 event cameras for "left" and "right" eyes.
Each user participates four sessions of data collection, the first two session capture both saccade and fixation states of the eye movement, the last two sessions record eye movement in smooth pursuit. 
We leverage the VGG Image Annotator on the [https://www.robots.ox.ac.uk/~vgg/software/via/via_demo.html](https://) to label the pupil region of 9,011 near-eye images selected uniformly across the image dataset, annotation results are recorded in excel tables in the last three sessions, e.g., "raw_data/Data_davis/user1/left/session_1_0_1/user_1.csv". The creation_time.txt file records the system time when davis 346 started collecting.
  ```
  ─Data_davis
  ├─user1
  │  ├─left
  │  │  ├─session_1_0_1
  │  │  │  ├─events
  │  │  │  └─frames
  │  │  ├─session_1_0_2
  │  │  │  ├─events
  │  │  │  ├─frames
  │  │  │  └─user_1.csv
  │  │  ├─session_2_0_1
  │  │  │  ├─events
  │  │  │  ├─frames
  │  │  │  └─user_1.csv
  │  │  ├─session_2_0_2
  │  │  │  ├─events
  │  │  │  ├─frames
  │  │  │  └─user_1.csv
  │  │  ├─creation_time.txt
  │  └─right
  │      ..........
  ```
Data_davis_labelled_with_mask: Using the code in '/matlab_processed/enerate_pupil_mask.m' to label grayscale images with annotation results in Data_davis, the results are saved as hdf5 files, which are then used for training the DL-based pupil segmentation network.
  ```
  ─Data_davis_labelled_with_mask
  ├─left
  │  ├─user1_session_1_0_2.h5
  │  ├─user1_session_2_0_1.h5
  │  │─user1_session_2_0_2.h5
  │  ..........
  ├─right
  │  ├─user1_session_1_0_2.h5
  │  ├─user1_session_2_0_1.h5
  │  │─user1_session_2_0_2.h5
  │  ..........
  ```


Data_tobii: The gaze references provided by Tobii Pro Glasses 3. The tobiisend.txt file records the system time when TTL signal is send to Tobii Pro Glasses 3, the tobiittl.txt records
the TTL signal receiving time in the glasses internal clock. The detailed introduction about gazedata, scenevideo, imudata and eventdata can be find in: [https://www.tobii.com/products/eye-trackers/wearables/tobii-pro-glasses-3#form](https://) 
  ```
  -Data_tobii
  ├─ user1 
  │  ├─tobiisend.txt
  │  ├─tobiittl.txt
  │  ├─session_1_0_1
  │        ├─gazedata
  │        ├─scenevideo
  │        ├─imudata
  │        ├─eventdata
  ```



- processed_data

Data_davis_predict:
Using the algorithm, estimated pupil images were obtained from the grayscale images for each user's session 102, 201,
and 202.

Frame_event_pupil_track_result:

Pixel_error_evaluation:

Pre-trained_models:

To access more information about the setup and data collection process, kindly refer to Section 3 of the corresponding paper.

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

#download processed_data

#unzip processed_data to 'dataset' folder
find /dataset/ -maxdepth 1 -name "*.zip" -exec unzip {} -d /dataset \

#download raw_data

#unzip raw_data to 'dataset' folder
unzip raw_data.zip -d /path/dataset

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

![dice](pictures/dice.png)
![distance](pictures/distance.png)
![event](pictures/event_pixel.png)
![frame](pictures/frame_pixel.png)
![iou](pictures/iou_new.png)

## Citation

If you would like to use our code or dataset, please cite either

```
@inproceedings{,  
  title={EV-Eye: Rethinking High-frequency Eye Tracking through the Lenses of Event Cameras},  
  author={Guangrong Zhao, Yiran Shen, Yurun Yang, Jingwei Liu, Ning Chen, Hongkai Wen, Guohao Lan},  
  year={2023}  
} 
```

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />
This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons
Attribution-NonCommercial 4.0 International License</a>.
