import argparse
import logging
import sys
import os
import sys
from pathlib import Path
import h5py
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch import optim
from torch.utils.data import DataLoader, random_split
from tqdm import tqdm
import torch.utils.data as Data
from utils.data_loading import BasicDataset, CarvanaDataset
from utils.dice_score import dice_loss
from evaluate import evaluate
from unet import UNet
import numpy as np

'''
    Args:
        device (torch.device): Device to use (cuda or cpu)
        epochs (int): Number of epochs to train for
        batch_size (int): Batch size to use for training
        learning_rate (float): Learning rate to use for training
        val_percent (float): Percentage of data to use for validation
        save_checkpoint (bool): Whether to save the checkpoint or not
        img_scale (float): Scaling factor of the images
        use_amp (bool): Whether to use Automatic Mixed Precision or not
        whicheye (str): whicheye of EV_Eye_dataset to be used,such as left or right

    Returns:
        None

'''


def train_net(
        device,
        epochs: int = 5,
        batch_size: int = 1,
        learning_rate: float = 1e-5,
        val_percent: float = 0.1,
        save_checkpoint: bool = True,
        img_scale: float = 1,
        amp: bool = False,
        whicheye: str = 'right',
        data_dir: str = os.getcwd()


):
    if whicheye == 'L':
        whicheye = 'left'
    if whicheye == 'R':
        whicheye = 'right'
    save_checkpoint = data_dir+"/"+whicheye 

    if not os.path.exists(save_checkpoint):
        os.makedirs(save_checkpoint)

    assert os.path.isdir( data_dir +'/EV_Eye_dataset/raw_data/Data_davis_labelled_with_mask/' ), data_dir+'/EV_Eye_dataset/raw_data/Data_davis_labelled_with_mask not exist, please download according to the guide.'
    # write results to checkpoint
    dir_checkpoint = Path('./' + whicheye + '/')
    with open(os.path.join(
            data_dir + "/"+whicheye + "/",
            f"ui_result.txt"), 'w') as outfiletotal:
        userlist = [u for u in range(1, 49)]
        orders = ["1_0_2", "2_0_1", "2_0_2"]
        for user in userlist:
            print(user)
            userlist_remain = userlist.copy()
            userlist_remain.remove(user)
            print(userlist_remain)

            train_data = []
            train_label = []
            flag = 1

            for user_train in userlist_remain:
                print(user_train)
                for order in orders:
                    f = h5py.File(os.path.join(
                        data_dir + '/EV_Eye_dataset/raw_data/Data_davis_labelled_with_mask/' + whicheye + '/user' + str(
                            user_train) + '_session_' + order + '.h5'), 'r')
                    # for key in f.keys():
                    #     print(f[key].name)

                    print(((f['data'].value).T).shape)
                    print(((f['label'].value).T).shape)

                    train_data_temp = ((f['data'].value).T).reshape(-1, 1, 260, 346)
                    train_label_temp = ((f['label'].value).T).reshape(-1, 260, 346)
                    if flag == 1:

                        train_data = train_data_temp
                        train_label = train_label_temp
                        flag = flag + 1
                    else:
                        train_data = np.concatenate((train_data, train_data_temp), axis=0)
                        train_label = np.concatenate((train_label, train_label_temp), axis=0)
                    print(train_data.shape)
                    print(train_label.shape)

            trainDataset = Data.TensorDataset((torch.from_numpy(train_data).type(torch.FloatTensor) / 255),
                                              torch.div(torch.from_numpy(train_label).type(torch.LongTensor), 1))

            n_train = len(trainDataset)
            print(n_train)
            train_loader = torch.utils.data.DataLoader(
                trainDataset,
                batch_size=8,
                shuffle=True,
                num_workers=4,
                # pin_memory=True
            )

            ####################################### #########################################################################################################

            test_data = []
            test_label = []
            flag = 1
            for user_test in range(user, user + 1):
                for order in orders:
                    f = h5py.File(os.path.join(
                        data_dir + '/EV_Eye_dataset/raw_data/Data_davis_labelled_with_mask/'+whicheye + '/user' + str(
                            user_test) + '_session_' + order + '.h5'), 'r')  # 

                    print(((f['data'].value).T).shape)
                    print(((f['label'].value).T).shape)

                    test_data_temp = ((f['data'].value).T).reshape(-1, 1, 260, 346)
                    test_label_temp = ((f['label'].value).T).reshape(-1, 260, 346)
                    if flag == 1:

                        test_data = test_data_temp
                        test_label = test_label_temp
                        flag = flag + 1
                    else:
                        test_data = np.concatenate((test_data, test_data_temp), axis=0)
                        test_label = np.concatenate((test_label, test_label_temp), axis=0)
                    print(test_data.shape)
                    print(test_label.shape)

            testDataset = Data.TensorDataset((torch.from_numpy(test_data).type(torch.FloatTensor) / 255),
                                             torch.div(torch.from_numpy(test_label).type(torch.LongTensor), 1))
            n_val = len(testDataset)
            val_loader = torch.utils.data.DataLoader(
                testDataset,
                batch_size=8,
                shuffle=False,
                num_workers=4,
                # pin_memory=True
            )

            net = UNet(n_channels=1, n_classes=args.classes, bilinear=args.bilinear)
            net.to(device=device)

            # 4. Set up the optimizer, the loss, the learning rate scheduler and the loss scaling for AMP
            optimizer = optim.Adam(net.parameters())
            scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, 'max', patience=2)  # goal: maximize Dice score
            grad_scaler = torch.cuda.amp.GradScaler(enabled=amp)
            criterion = nn.CrossEntropyLoss()
            global_step = 0

            # 5. Begin training
            for epoch in range(1, epochs + 1):
                net.train()
                epoch_loss = 0
                with tqdm(total=n_train, desc=f'Epoch {epoch}/{epochs}', unit='img') as pbar:
                    for batch in train_loader:
                        images, true_masks = batch
                        torch.set_printoptions(profile="full")

                        assert images.shape[1] == net.n_channels, \
                            f'Network has been defined with {net.n_channels} input channels, ' \
                            f'but loaded images have {images.shape[1]} channels. Please check that ' \
                            'the images are loaded correctly.'

                        images = images.to(device=device, dtype=torch.float32)
                        true_masks = true_masks.to(device=device, dtype=torch.long)

                        with torch.cuda.amp.autocast(enabled=amp):
                            masks_pred = net(images)
                            # print(masks_pred.shape)
                            loss = criterion(masks_pred, true_masks) \
                                   + dice_loss(F.softmax(masks_pred, dim=1).float(),
                                               F.one_hot(true_masks, net.n_classes).permute(0, 3, 1, 2).float(),
                                               multiclass=True)

                        optimizer.zero_grad(set_to_none=True)
                        grad_scaler.scale(loss).backward()
                        grad_scaler.step(optimizer)
                        grad_scaler.update()

                        pbar.update(images.shape[0])
                        global_step += 1
                        epoch_loss += loss.item()
                        pbar.set_postfix(**{'loss (batch)': loss.item()})
                        # Evaluation round
                        division_step = (n_train // (10 * batch_size))
                        if division_step > 0:
                            if global_step % division_step == 0:
                                histograms = {}
                                for tag, value in net.named_parameters():
                                    tag = tag.replace('/', '.')

                                val_score, miou = evaluate(net, val_loader, device)
                                scheduler.step(val_score)

                                logging.info('Validation Dice score: {}'.format(val_score))

            # save chackpoint
            if save_checkpoint:
                outfiletotal.write(
                    "user_" + str(user) + ":dice_score:" + str(val_score.cpu().numpy()) + ",miou_score:" + str(
                        miou) + "\n")
                sys.stdout.flush()
                outfiletotal.flush()
                Path(dir_checkpoint).mkdir(parents=True, exist_ok=True)
                torch.save(net.state_dict(), os.path.join(str(dir_checkpoint), "user" + str(user) + ".pth"))
                logging.info(f'Checkpoint {epoch} saved!')


def get_args():
    parser = argparse.ArgumentParser(description='Train the UNet on images and target masks')
    parser.add_argument('--epochs', '-e', metavar='E', type=int, default=5, help='Number of epochs')
    parser.add_argument('--batch-size', '-b', dest='batch_size', metavar='B', type=int, default=8, help='Batch size')
    parser.add_argument('--learning-rate', '-l', metavar='LR', type=float, default=1e-5,
                        help='Learning rate', dest='lr')
    parser.add_argument('--load', '-f', type=str, default=False, help='Load model from a .pth file')
    parser.add_argument('--scale', '-s', type=float, default=1, help='Downscaling factor of the images')
    parser.add_argument('--validation', '-v', dest='val', type=float, default=10.0,
                        help='Percent of the data that is used as validation (0-100)')
    parser.add_argument('--amp', action='store_true', default=False, help='Use mixed precision')
    parser.add_argument('--bilinear', action='store_true', default=False, help='Use bilinear upsampling')
    parser.add_argument('--classes', '-c', type=int, default=2, help='Number of classes')
    parser.add_argument('--whicheye', '-d', type=str, default="right")
    parser.add_argument('--data_dir', type=str,
                        default=os.getcwd())
    return parser.parse_args()


if __name__ == '__main__':
    args = get_args()

    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    logging.info(f'Using device {device}')

    try:
        train_net(
            epochs=args.epochs,
            batch_size=args.batch_size,
            learning_rate=args.lr,
            device=device,
            img_scale=args.scale,
            val_percent=args.val / 100,
            amp=args.amp,
            whicheye=args.whicheye,
            data_dir=args.data_dir,
        )
    except KeyboardInterrupt:
        torch.save(net.state_dict(), 'INTERRUPTED.pth')
        logging.info('Saved interrupt')
        raise
