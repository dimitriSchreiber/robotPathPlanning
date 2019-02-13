# -*- coding: utf-8 -*-
"""
Created on Fri Feb  8 15:57:11 2019

@author: xumw1
"""

import numpy as np
from sklearn.utils.extmath import cartesian

class configGenerator_VREP(object):
    def generate_sample(config = 2):
        # prepare training set
        joint_range_lower_limit = np.array([-7.500e-2, -4.500e-2, -9.000e+1, -5.200e+1, -5.020e+1, -5.200e+1, 0])
        joint_range = np.array([1.500e-1, 9.000e-2, 1.800e+2, 1.040e+2, 1.020e+2, 1.040e+2, 5.500e-2])
        joint_range_upper_limit = joint_range_lower_limit + joint_range
        
        index_Pjoint = [0, 1]   # does not include insertion
        index_Sjoint = [2, 3, 4, 5]
        
        sample = (np.linspace(0,1,config)[:,None]*(joint_range_upper_limit
                               -joint_range_lower_limit)+joint_range_lower_limit)
        
        #x1, x2 = np.meshgrid(sample_j1, sample_j2)
        #t = np.array(np.meshgrid(sample[0,:],sample[1,:])).T.reshape(-1,7)
        
        total_sample = cartesian((sample[:, 0], sample[:, 1], sample[:, 2], sample[:, 3], 
                       sample[:, 4], sample[:, 5]))
        return total_sample

if __name__ == "__main__":
    total_sample = configGenerator_VREP.generate_sample(2)