from moviepy.editor import *

clip = (VideoFileClip("../vidoutput/tomap.mp4")
#    .subclip((0,1),(0,2))
    .resize(0.5)
    .set_duration(5))

clip.write_gif("../preview.gif", fps = 5)
