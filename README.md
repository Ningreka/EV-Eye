# EV-Eye: Rethinking High-frequency Eye Tracking through the Lenses of Event Cameras

## Summary

<br/>

## Dataset

You can download the data from  xxx ,which consists of

- Data_dvs :
  
  From user1 to user48, all eye tracking data collected using event cameras, including data from left and right eyes, for each user including four sessions.
- Data_dvs_predict:
  
  Using the algorithm, estimated pupil images were obtained from the grayscale images for each user's session 102, 201, and 202.
- Data_tobii:
  
  Eye tracking data collected using Tobii

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

<br/>

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
