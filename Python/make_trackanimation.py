import trackanimation
from trackanimation.animation import AnimationTrack

input_directory = "../data/tomap.csv"
ibiza_trk = trackanimation.read_track(input_directory)

fig = AnimationTrack(df_points=ibiza_trk, dpi=300, bg_map=True, map_transparency=1)

fig.make_video(output_file='../vidoutput/tomap', framerate=30, linewidth=3.0)
