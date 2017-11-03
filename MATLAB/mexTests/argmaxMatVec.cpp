#include "mex.h"
#include <string.h>
#include <math.h>
#include <algorithm>

// Faster exp function
// inline double expFast(double x)
// {
//     x = 1 + x/1024.;
//     x*=x; x*=x; x*=x; x*=x; x*=x;
//     x*=x; x*=x; x*=x; x*=x; x*=x;
//     return x;
// }

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Input variables
    #define A_in               prhs[0]
    #define v_in               prhs[1]
    
    double *A;
    double *v;
    
    A = mxGetPr(A_in);
    int N = mxGetDimensions(A_in)[0];     // Number of samples
    int d = mxGetDimensions(v_in)[0]; // Get number of dim. Exclude label columns
    
    double maxVal = -1000000., maxValTemp = -1000000.;
    double argmax = 0.;
    
    v = mxGetPr(v_in);
//     int i, j;
    for (int j = 0; j < N; ++j)
    {
        maxValTemp = 0;
        for (int i = 0; i < d; ++i)
        {
            maxValTemp += A[j+i*N]*v[i];
        }
        if (maxValTemp > maxVal)
        {
            maxVal = maxValTemp;
            argmax = j;
        }
    }
//     ++argmax;
    plhs[0] = mxCreateDoubleScalar(++argmax);
    return;
}