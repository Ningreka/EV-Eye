import torch
import torch.nn.functional as F
from tqdm import tqdm
import numpy as np
from utils.dice_score import multiclass_dice_coeff, dice_coeff


def evaluate(net, dataloader, device):
    net.eval()
    num_val_batches = len(dataloader)
    dice_score = 0
    iou_mean_score = 0
    # iterate over the validation set
    for batch in tqdm(dataloader, total=num_val_batches, desc='Validation round', unit='batch', leave=False):
        # image, mask_true = batch['image'], batch['mask']
        image, mask_true = batch
        # move images and labels to correct device and type
        image = image.to(device=device, dtype=torch.float32)
        mask_true = mask_true.to(device=device, dtype=torch.long)
        mask_target = mask_true.cpu()
        # print(mask_true.shape)

        mask_true = F.one_hot(mask_true, net.n_classes).permute(0, 3, 1, 2).float()
        with torch.no_grad():
            # predict the mask
            mask_pred = net(image)
            # print(mask_pred.shape)
            mask_probs = mask_pred.cpu()

            mask_probs = np.argmax(mask_probs, axis=1)
            # print(mask_probs[0])
            # print(mask_target.shape)
            iou_mean_score += iou_mean(mask_probs, mask_target, n_classes=1)
            # convert to one-hot format
            if net.n_classes == 1:
                mask_pred = (F.sigmoid(mask_pred) > 0.5).float()
                # compute the Dice score
                dice_score += dice_coeff(mask_pred, mask_true, reduce_batch_first=False)
            else:
                mask_pred = F.one_hot(mask_pred.argmax(dim=1), net.n_classes).permute(0, 3, 1, 2).float()
                # compute the Dice score, ignoring background
                dice_score += multiclass_dice_coeff(mask_pred[:, 1:, ...], mask_true[:, 1:, ...],
                                                    reduce_batch_first=False)

    print('iou_mean_score:', iou_mean_score / num_val_batches)
    net.train()

    # Fixes a potential division by zero error

    if num_val_batches == 0:
        return dice_score, iou_mean_score
    return dice_score / num_val_batches, iou_mean_score / num_val_batches


def iou_mean(pred, target, n_classes=1):
    # n_classes ：the number of classes in your dataset,not including background
    # for mask and ground-truth label, not probability map
    ious = []
    iousSum = 0

    # Ignore IoU for background class ("0")
    for cls in range(1, n_classes + 1):  # This goes from 1:n_classes-1 -> class "0" is ignored
        pred_inds = pred == cls
        target_inds = target == cls
        intersection = (pred_inds[target_inds]).long().sum().data.cpu().item()  # Cast to long to prevent overflows
        union = pred_inds.long().sum().data.cpu().item() + target_inds.long().sum().data.cpu().item() - intersection
        if union == 0:
            ious.append(float('nan'))  # If there is no ground truth, do not include in evaluation
        else:
            ious.append(float(intersection) / float(max(union, 1)))
            iousSum += float(intersection) / float(max(union, 1))
    return iousSum / n_classes
