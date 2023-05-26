import argparse
import logging
import os
import glob
import os
import os.path as osp
import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
from torchvision import transforms
from tqdm import tqdm
from utils.data_loading import BasicDataset
from unet import UNet
from utils.utils import plot_img_and_mask


def predict_img(net,
                full_img,
                device,
                scale_factor=1,
                out_threshold=0.5):
    net.eval()
    img = torch.from_numpy(np.asarray(full_img)[np.newaxis, ...])
    # print(img.shape)
    img = torch.div(img.type(torch.FloatTensor), 255)
    img = img.unsqueeze(0)
    img = img.to(device=device, dtype=torch.float32)

    with torch.no_grad():
        output = net(img)

        if net.n_classes > 1:
            probs = F.softmax(output, dim=1)[0]
        else:
            probs = torch.sigmoid(output)[0]

        tf = transforms.Compose([
            transforms.ToPILImage(),
            transforms.Resize((full_img.size[1], full_img.size[0])),
            transforms.ToTensor()
        ])

        full_mask = tf(probs.cpu()).squeeze()
        # print(full_mask.shape)
    if net.n_classes == 1:
        return (full_mask > out_threshold).numpy()
    else:
        return F.one_hot(full_mask.argmax(dim=0), net.n_classes).permute(2, 0, 1).numpy()


def get_args():
    parser = argparse.ArgumentParser(description='Predict masks from input images')
    parser.add_argument('--model', '-m', default='MODEL.pth', metavar='FILE',
                        help='Specify the file in which the model is stored')
    parser.add_argument('--input', '-i', help="pls enter a string", type=str)
    parser.add_argument('--output', '-o', metavar='OUTPUT', nargs='+', help='Filenames of output images')
    parser.add_argument('--viz', '-v', action='store_true',
                        help='Visualize the images as they are processed')
    parser.add_argument('--no-save', '-n', action='store_true', help='Do not save the output masks')
    parser.add_argument('--mask-threshold', '-t', type=float, default=0.5,
                        help='Minimum probability value to consider a mask pixel white')
    parser.add_argument('--scale', '-s', type=float, default=1,
                        help='Scale factor for the input images')
    parser.add_argument('--bilinear', action='store_true', default=False, help='Use bilinear upsampling')

    parser.add_argument('--data_dir', type=str, default=os.getcwd())
    parser.add_argument('--direction', type=str, default="right")
    return parser.parse_args()


def get_output_filenames(args):
    def _generate_name(fn):
        return f'{os.path.splitext(fn)[0]}_OUT.png'

    return args.output or list(map(_generate_name, args.input))


def mask_to_image(mask: np.ndarray):
    if mask.ndim == 2:
        return Image.fromarray((mask * 255).astype(np.uint8))
    elif mask.ndim == 3:
        return Image.fromarray((np.argmax(mask, axis=0) * 255 / mask.shape[0]).astype(np.uint8))


if __name__ == '__main__':
    args = get_args()
    userlist = [u for u in range(1, 49)]
    orders = ['1_0_1','1_0_2','2_0_1','2_0_2']
    for user in userlist:
        print(user)
        for order in orders:
            origin_data_dir = args.data_dir + '/dataset/raw_data/Data_dvs/user' + str(
                user) + args.direction + '/session_'+order+'/events/'

            assert os.path.exists(origin_data_dir), "please check your data directory"

            origin_paths = []

            paths = glob.glob(os.path.join(origin_data_dir, 'frames/', '*.png'))
            origin_paths.extend(paths)

            target_data_dir = args.data_dir + '/dataset/raw_data/Data_dvs_predict/user' + str(
                user) +  args.direction + '/session_'+order+'/events/'

            assert os.path.exists(origin_data_dir), "please check your data directory"

            target_path = (os.path.join(target_data_dir, 'predict/'))
            print(target_path)
            if not os.path.exists(target_path):
                os.makedirs(target_path)

            net = UNet(n_channels=1, n_classes=2, bilinear=args.bilinear)

            device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
            logging.info(f'Loading model {args.model}')
            logging.info(f'Using device {device}')
            device = "cuda:1"
            net.to(device=device)

            model_dir = args.data_dir + '/' + args.direction + '_checkpoints/user' + str(
                user) + '.pth'

            net.load_state_dict(torch.load(model_dir, map_location=device))

            logging.info('Model loaded!')

            for i, filename in enumerate(tqdm(origin_paths)):

                logging.info(f'\nPredicting image {filename} ...')
                img = Image.open(filename)

                mask = predict_img(net=net,
                                   full_img=img,  #
                                   scale_factor=args.scale,
                                   out_threshold=args.mask_threshold,
                                   device=device)
           
                out_filename = (os.path.join(target_path, osp.splitext(os.path.split(filename)[-1])[0] + '_mask.gif'))
                # print(out_filename)
                result = mask_to_image(mask)

                result.save(out_filename)
                logging.info(f'Mask saved to {out_filename}')
