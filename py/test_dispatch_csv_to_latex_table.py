#!/bin/env python3
import pandas

X=4 # change this to whatever dimension
Y=4 # change this to whatever dimension
file_path="~/bsg_bladerunner/bsg_replicant/regression/cuda/test_dispatch.csv"
data = pandas.read_csv(file_path)

print("\\begin{tabular}{c|c}")
print("\t(x,y)\t&seconds\t\\\\")
print("\t\\hline")
for x in range(X):
    for y in range(Y):
        t = data.query('x==%d'%x).query('y==%d'%y).mean()
        print("\t({},{})\t& {:1.6f}\t\\\\".format(x,y,t[2]))
print("\\end{tabular}")


HZ = 125.0e6 # manycore clock frequency in F1 emulation

min_d = data.query('x==0').query('y==0').mean().dispatch_seconds
max_d = data.query('x==3').query('y==3').mean().dispatch_seconds

print("{:1.6f} seconds from first to last core".format((max_d-min_d)))
print("{:1.6f} cycles  from first to last core".format((max_d-min_d) * HZ))

print("{:1.6f} seconds total".format(max_d))
print("{:1.6f} cycles  total".format(max_d * HZ))
