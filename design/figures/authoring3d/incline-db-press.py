"""Incline DB press: back on a bench inclined about 30 degrees, feet on the floor; dumbbells press from beside the
chest to over the shoulders. The body was first placed by hand (no script existed before 7 Oct); its points are kept
as they were, the bench is built around it: the back pad 9 below the neck-pelvis line, meeting the rear of the seat."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import slab, line, write

START = {
    "pelvis": [98, 140, 0],
    "neck": [54.7, 115.0, 0.0],
    "head": [38.9, 108.6, 0.0],
    "shoulderL": [54.7, 115.0, 15.0],
    "shoulderR": [54.7, 115.0, -15.0],
    "hipL": [98, 140, 9],
    "hipR": [98, 140, -9],
    "elbowL": [61.4, 137.7, 27.9],
    "handL": [67.4, 113.8, 24.0],
    "elbowR": [65.2, 135.5, -29.1],
    "handR": [71.4, 111.8, -24.0],
    "kneeL": [135.6, 139.2, 14.6],
    "ankleL": [139.0, 175.0, 15.0],
    "toeL": [151.4, 178.8, 15.0],
    "kneeR": [135.5, 139.0, -14.9],
    "ankleR": [134.0, 175.0, -15.0],
    "toeR": [146.4, 178.8, -15.0]}
END = {
    "pelvis": [98, 140, 0],
    "neck": [54.7, 115.0, 0.0],
    "head": [38.9, 108.6, 0.0],
    "shoulderL": [54.7, 115.0, 15.0],
    "shoulderR": [54.7, 115.0, -15.0],
    "hipL": [98, 140, 9],
    "hipR": [98, 140, -9],
    "elbowL": [58.7, 88.4, 13.3],
    "handL": [61.9, 63.7, 11.0],
    "elbowR": [60.6, 88.7, -13.4],
    "handR": [65.3, 64.2, -11.2],
    "kneeL": [135.6, 139.2, 14.6],
    "ankleL": [139.0, 175.0, 15.0],
    "toeL": [151.4, 178.8, 15.0],
    "kneeR": [135.5, 139.0, -14.9],
    "ankleR": [134.0, 175.0, -15.0],
    "toeR": [146.4, 178.8, -15.0]}

PAD = 9                                   # pad surface below the body's centre line
pel, nk = START["pelvis"], START["neck"]
t = [nk[0] - pel[0], nk[1] - pel[1]]
tl = math.hypot(*t)
t = [t[0] / tl, t[1] / tl]                # pelvis -> neck
n = [t[1], -t[0]]                         # perpendicular, pointing down-left (under the back)
if n[1] < 0:
    n = [-n[0], -n[1]]
base = [pel[0] + n[0] * PAD, pel[1] + n[1] * PAD]
SEAT_Y = 151
# lower end of the pad: where the pad line comes down to just above the seat
k = (SEAT_Y - 2 - base[1]) / t[1]         # negative: down the slope past the pelvis
pad_low = [base[0] + t[0] * k, base[1] + t[1] * k]
pad_top = [base[0] + t[0] * 68, base[1] + t[1] * 68]
props = [slab([pad_low, pad_top], -12, 12, 7),                     # back pad
         slab([[88, SEAT_Y], [124, SEAT_Y]], -12, 12, 7),           # seat
         line([[104, 153, 0], [104, 181, 0]], 5),                   # seat post
         slab([[84, 181], [124, 181]], -14, 14, 4),                 # base
         line([[88.6, 144, 0], [104, 165, 0]], 4)]                  # brace under the back pad
load = {"type": "dumbbells", "at": "hands", "axis": [1, 0, 0]}
write("incline-db-press", START, END, props, load, tempo=2.6)
