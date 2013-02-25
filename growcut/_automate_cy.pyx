#cython: cdivision=True
#cython: boundscheck=False
#cython: nonecheck=False
#cython: wraparound=False

import sys
import numpy as np
cimport numpy as cnp

CONNECT_4 = [(-1, 0), (1, 0), (0, 1), (0, -1)]
CONNECT_8 = [(-1, -1), (-1, 0), (-1, 1), (0, -1),
             (0, 1), (1, -1), (1, 0), (1, 1)]

if sys.version_info < (3,):
    range = xrange


def _g_cy(float x, float maxC):
    return 1 - x / maxC


def _pad(arr):
    arr = np.vstack((arr[0, :], arr, arr[arr.shape[0] - 1, :]))
    return np.hstack((arr[:, 0][:, np.newaxis],
                      arr,
                      arr[:, arr.shape[1] - 1][:, np.newaxis]))


def automate_cy(cnp.ndarray[double, ndim=2] lum,
                cnp.ndarray[double, ndim=2] strength,
                cnp.ndarray[int, ndim=2] label,
                connectivity=4):
    """ Grow-cut without iterGrids """
    if connectivity == 4:
        connectivity = CONNECT_4
    else:
        connectivity = CONNECT_8

    # Output initialization
    cdef cnp.ndarray[double, ndim=2] nextStrength = (
                np.atleast_2d(strength.copy()).astype(float))
    cdef cnp.ndarray[int, ndim=2] nextLabel = (
                np.atleast_2d(label.copy()).astype(int))

    # Internal variables
    cdef:
        tuple point, rel_point
        list neighbourLum, neighbourStrength, neighbourLabel
        float cp, thetap, cq, thetaq, lum_max
        int lq
        Py_ssize_t rows = lum.shape[0]
        Py_ssize_t cols = lum.shape[1]
        Py_ssize_t rel_row, rel_col

    # Set max luminance & connectivity
    lum_max = lum.max()


    # Pad inputs with one pixel of replication, so wraparound isn't a concern
    lum = _pad(lum)
    strength = _pad(strength)
    label = _pad(label)

    # Loop over every point
    for row in range(rows):
        for col in range(cols):
            cp = lum[row + 1, col + 1]
            thetap = strength[row + 1, col + 1]

            # Loop over local neighborhood
            for rel_point in connectivity:
                rel_row = row + rel_point[0] + 1
                rel_col = col + rel_point[1] + 1
                cq = lum[rel_row, rel_col]
                thetaq = strength[rel_row, rel_col]
                lq = label[rel_row, rel_col]
                test = _g_cy(cp - cq, lum_max) * thetaq

                if test > thetap or test < -thetap:
                    nextLabel[row, col] = lq
                    nextStrength[row, col] = test

    return nextStrength, nextLabel
