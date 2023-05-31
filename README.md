# EV-Eye: Rethinking High-frequency Eye Tracking through the Lenses of Event Cameras

## Summary
We introduce the most diverse and largest multi-modal eye tracking dataset in the literature for high frequency eye tracking in the literature. and propose a novel hybrid frame-event eye tracking system that can track the pupil at a frequency up to 38.4KHz.
We propose a novel hybrid frame-event eye tracking benchmarking approach bespoke for the collected dataset that can track the pupil at a frequency up to 38.4KHz and outperforms the existing
solution in both pupil and gaze estimation by a large margin.
<br/>
<br/>

![summary](pictures/main.jpg)

<br/>

## A quick Youtube demo for introduction
[![IMAGE_ALT](pictures/EV.png)](https://youtu.be/Yi03mFAyslU)


## Dataset

You can download the data from   [https://1drv.ms/f/s!Ar4TcaawWPssqmtPFPikuTIHUAmJ?e=eFIjMP](https://) ,which consists of

- raw_data

  Data_davis : From user1 to user48, all eye tracking data collected using event cameras, including data from left and
  right eyes, for each user including four sessions.
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
  │      ..........

  ```

  Data_davis_labelled_with_mask: Use the code in '/matlab_data_processing' to label the position of the pupils in frames
  captured by the event camera, and save the labels as an hdf5 file.
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
  │        ├─eventdata
  │        ├─gazedata.txt
  │        ├─imudata
  ```

- processed_data

  Data_davis_predict:
  Using the algorithm, estimated pupil images were obtained from the grayscale images for each user's session 102, 201,
  and 202.

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
