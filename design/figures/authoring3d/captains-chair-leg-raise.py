"""Captain's chair leg raise: as the knee raise (same chair, same hold on the arm rests), but the legs stay
straight and rise from hanging to hip height while the pelvis curls off the pad, then lower slowly."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import write
import importlib.util
_spec = importlib.util.spec_from_file_location("ccknee", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                      "captains-chair-knee-raise.py"))
cc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cc)

start = cc.pose(90, 87, 89, 50)
end = cc.pose(104, -6, -6, -40)
write("captains-chair-leg-raise", start, end, cc.chair(start["elbowL"], start["handL"]), None,
      tempo=3.0, floor=cc.FLOOR, yaw=20)
