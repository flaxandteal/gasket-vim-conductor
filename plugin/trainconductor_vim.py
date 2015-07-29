# Vim global plugin for Train integration
# Last Change: 2015 Jul 29
# Maintainer: Phil Weir <phil.weir@flaxandteal.co.uk>
# License: MIT License

import vim, os, socket
import lxml.etree as ET
import re

class TrainTrain:
    active = False
    carriages = None
    def __init__(self, train_track_file, active=True):
        self.carriages = {}
	self.active = active
        try:
            track = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
	    track.connect(train_track_file)
	except:
	    self.track = None
        finally:
            self.track = track

    def toggle_active(self):
        self.active = not self.active
	self.redisplay()

    def add_carriage(self, name=None):
    	car_id = "car-%d" % len(self.carriages)
	if name is None:
		name = car_id
	self.carriages[car_id] = (name, ET.Element('g'))
	return car_id

    def update_carriage(self, car_id, svg):
        if car_id not in self.carriages:
	    raise RuntimeException("Train Carriage not found")
	g = self.carriages[car_id][1]
	g.clear()
	g.append(svg)
	self.redisplay()

    def remove_carriage(self, car_id):
        if car_id not in self.carriages:
	    raise RuntimeException("Train Carriage not found")
	del self.carriages[car_id]
	self.redisplay()

    def redisplay(self):
	track = self.track
        if track is None:
		return

        if not self.active:
		self.clear()
		return

        doc = ET.Element('svg', width='10', height='10', xmlns='http://www.w3.org/2000/svg')
	for car_id in self.carriages:
		car = self.carriages[car_id]
		car[1].set('title', car[0])
		doc.append(car[1])

        track.sendall(ET.tostring(doc, pretty_print=True))
        track.sendall("\n__GASKET_CABOOSE__\n")

    def shutdown(self):
	track = self.track
        if track is None:
		return

        self.clear()
	track.close()

    def clear(self):
	track = self.track
        if track is None:
		return

        track.sendall("\n__GASKET_CABOOSE__\n")
        track.sendall("\n__GASKET_CABOOSE__\n")

if not hasattr(vim, "train"):
    train_track_file = os.getenv("GASKET_SOCKET")
    if train_track_file is not None and train_track_file != "":
        vim.train = TrainTrain(train_track_file, active=False)
    else:
	vim.train = None
