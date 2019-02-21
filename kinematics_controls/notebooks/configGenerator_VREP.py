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
#        joint_range_lower_limit = np.array([-2e-1, -4.500e-2, -9.000e+1, -5.200e+1, -5.020e+1, -5.200e+1, 0])
#        joint_range = np.array([4e-1, 0.95e0, 1.800e+2, 1.040e+2, 1.020e+2, 1.040e+2, 5.500e-2])

        #units are radians for revolute joints: http://www.coppeliarobotics.com/helpFiles/en/jointDescription.htm
        joint_range_lower_limit = np.array([-1e-1, -4.500e-2, -9.000e+1, -5.200e+1, -5.020e+1, -5.200e+1, 0])
        joint_range_lower_limit[2:-1] = joint_range_lower_limit[2:-1] * np.pi/180
        joint_range = np.array([2e-1, 0.95e0, 1.800e+2, 1.040e+2, 1.020e+2, 1.040e+2, 5.500e-2])
        joint_range[2:-1] = joint_range[2:-1] * np.pi/180
        joint_range_upper_limit = joint_range_lower_limit + joint_range
        
        print('joint lower limit\n', joint_range_lower_limit)
        print('joint upper limit\n', joint_range_upper_limit)
        
        sample = (np.linspace(0,1,config)[:,None]*(joint_range_upper_limit
                               -joint_range_lower_limit)+joint_range_lower_limit)
        
        #x1, x2 = np.meshgrid(sample_j1, sample_j2)
        #t = np.array(np.meshgrid(sample[0,:],sample[1,:])).T.reshape(-1,7)
#        sample0 = ((np.linspace(0,1,config[0])[:,None]*(joint_range_upper_limit
#                           -joint_range_lower_limit)+joint_range_lower_limit))
#        sample1 = ((np.linspace(0,1,config[1])[:,None]*(joint_range_upper_limit
#                           -joint_range_lower_limit)+joint_range_lower_limit))
#        sample2 = ((np.linspace(0,1,config[2])[:,None]*(joint_range_upper_limit
#                           -joint_range_lower_limit)+joint_range_lower_limit))
#        sample3 = ((np.linspace(0,1,config[3])[:,None]*(joint_range_upper_limit
#                           -joint_range_lower_limit)+joint_range_lower_limit))
#        sample4 = ((np.linspace(0,1,config[4])[:,None]*(joint_range_upper_limit
#                           -joint_range_lower_limit)+joint_range_lower_limit))
#        sample5 = ((np.linspace(0,1,config[5])[:,None]*(joint_range_upper_limit
#                           -joint_range_lower_limit)+joint_range_lower_limit))
#        
#        #x1, x2 = np.meshgrid(sample_j1, sample_j2)
#        #t = np.array(np.meshgrid(sample[0,:],sample[1,:])).T.reshape(-1,7)
#        sample = np.vstack((sample0,sample1,sample2,sample3,sample4,sample5))
        
        total_sample = cartesian((sample[:, 0], sample[:, 1], sample[:, 2], sample[:, 3], 
                       sample[:, 4], sample[:, 5]))
        return total_sample

if __name__ == "__main__":
    total_sample = configGenerator_VREP.generate_sample(2)
    print(total_sample)