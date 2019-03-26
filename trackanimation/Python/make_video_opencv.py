# Make video using timestamp images using OpenCV.
# The image files are all stored in one folder as <timestamp>.png

import numpy as np
import cv2
import glob

images = []
files = sorted(glob.glob("../staticmap2/*.png"))

for file in files:
    img = cv2.imread(file)
    height, width, layers = img.shape
    size = (width, height)
    images.append(img)

fourcc = cv2.VideoWriter_fourcc(*'XVID')

out = cv2.VideoWriter("../vidoutput/tsvid.avi", fourcc, 30.0, size)

for i in range(len(images)):
    out.write(images[i])

out.release()

