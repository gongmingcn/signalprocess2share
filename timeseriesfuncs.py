# -*- coding: utf-8 -*-
"""
Created on Fri Jun 17 16:14:21 2022

A module to hold generic functions for time series signal processing

"""
import math
import numpy as np

# a queue like objec/class with an efficient way to calculate the moving average
class native_running_queue:
    """
    class for mean calculation with a fix length of array
    Parameters
        ------------
        nLen: length of the running queue
    Application Example:
        ------------
        this_running_queue = native_running_queue(5)
        this_running_queue.push(2.4)
        this_running_queue.mean      
    """
    def __init__(self, nLen = 10):
        """
        Parameters
        ----------
        nLen : int, optional
            Length of the running queue. The default is 10.

        Returns
        -------
        None.

        """
        self.__n = nLen
        assert self.__n > 0 and isinstance(self.__n, int), "should be one postive interger value"
        self.__sum = 0
        self.__queue = np.zeros(self.__n)

    def push(self, x):
        """
        Push a new number to the queue
        Parameters
        ----------
        x : value
            Newly arrived number for the queue.

        Returns
        -------
        None.

        """
        self.__sum += x
        self.__sum -= self.__queue[0]
        self.__queue[:-1] = self.__queue[1:]
        self.__queue[-1] = x

    @property
    def mean(self):
        """
        return std of the virtual queue
        """
        return (self.__sum/self.__n)   

    @property
    def n(self):
        """
        return the length of virtual queue
        """
        return self.__n
    
# a function to calculate the running mean, may subject to accumulated error for huge number of Array
def running_mean(theArray, nWin, fill = False):
    """
    Running mean calculation / a quick convolution
    Parameters
    ----------
        theArray: 1D np.array, raw sequence data
        nWin: windows length to be averaged
        fill: boolean, True --> padding the results to the same size of the input Array
    Returns
    ----------
        an array holds the moving averaged result
    """
    
    cumsum = np.cumsum(np.insert(theArray, 0, 0))
    rtn_array = (cumsum[nWin:] - cumsum[:-nWin]) / nWin
    
    if fill: # pad the results to the same length of the input array
        fill_len = int((nWin-1)/2)
        rtn_array = np.pad(rtn_array,(fill_len,(len(theArray)-len(rtn_array)-fill_len)),'edge')
    
    return rtn_array

# calculate the weight of one queue --> a list is return in order of [x, weight]
def cal1DWeight(theQueue, sum_it = False):
    '''
    Calculate the weight of one queue --> a list is return in order of [x, weight]
    Parameters
    ----------
    theQueue : queue or list.
    sum_it : boolean, optional
        DESCRIPTION. The default is False.
        True --> simple sum
        False --> average weight of the non-zero elements
    Returns
    -------
    weight : list
        a list is return in order of [x, weight].

    '''

    if not isinstance(theQueue,np.ndarray):
        theQueue = np.array(theQueue)

    w=np.sum(theQueue)

    if w>0:
        if sum_it:
            weight = [np.average(list(range(len(theQueue))),weights=theQueue), w]
        else:
            weight = [np.average(list(range(len(theQueue))),weights=theQueue), \
                      w/np.count_nonzero(theQueue)]
    else:
        weight = [0]*2

    return weight
  
